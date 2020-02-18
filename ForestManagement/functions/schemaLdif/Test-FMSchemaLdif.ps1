function Test-FMSchemaLdif
{
	<#
	.SYNOPSIS
		Tests whether the configured ldif-file-based schema extension has been applied.
	
	.DESCRIPTION
		Tests whether the configured ldif-file-based schema extension has been applied.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-FMSchemaLdif

		Checks the current forest against all configured schema extension files
	#>
	
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SchemaLdif -Cmdlet $PSCmdlet
		try {
			$rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop
			$forest = Get-ADForest @parameters -ErrorAction Stop
		}
		catch {
			Stop-PSFFunction -String 'Test-FMSchemaLdif.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$parameters["Server"] = $forest.SchemaMaster
	}
	process
	{
		$ldifMapping = ConvertTo-SchemaLdifPhase -LdifData (Get-FMSchemaLdif)
		$ldifSorted = Get-FMSchemaLdif | Sort-Object Weight
		$changes = @{ }
		$missingEntities = @()

		foreach ($ldifFile in $ldifSorted) {
			$changes[$ldifFile.Name] = @()
		}

		foreach ($distinguishedName in $ldifMapping.Keys) {
			$hasDefinedState = $ldifMapping[$distinguishedName].Values.State.Count -gt 0
			$attributeName = '{0},{1}' -f $distinguishedName, $rootDSE.schemaNamingContext

			#region Retrieve AD Object ($adObject)
			try { $adObject = Get-ADObject @parameters -Identity $attributeName -ErrorAction Stop -Properties * }
			catch {
				if ($hasDefinedState) {
					foreach ($file in $ldifMapping[$distinguishedName].Keys) {
						$changes[$file] += [PSCustomObject]@{
								DN = $distinguishedName
								Property = '<FailsToExist>'
								File = $file
								Setting = $ldifMapping[$distinguishedName][$file]
								ADObject = $null
								ValueS = $null
								ValueA = $null
							}
					}
				}
				else {
					if ($distinguishedName -notin ($ldifSorted.MissingObjectExemption | Write-Output)) {
						Write-PSFMessage -Level Warning -String 'Test-FMSchemaLdif.Missing.SchemaItem' -StringValues $attributeName -Tag 'panic'
						$missingEntities += $attributeName
					}
				}
				continue
			}
			#endregion Retrieve AD Object ($adObject)

			#region Compare configured with real state ($offStateLdifName)
			$offStateLdif = foreach ($ldifFile in $ldifSorted) {
				# Skip files that do not yet contain the taret object
				if (-not $ldifMapping[$distinguishedName][$ldifFile.Name]) { continue }

				$definedState = $ldifMapping[$distinguishedName][$ldifFile.Name]
				if ($definedState.State.Count -gt 0) {
					foreach ($propertyName in $definedState.State.Keys) {
						if (Compare-SchemaProperty -Setting $definedState.State -ADObject $adObject -PropertyName $propertyName -RootDSE $rootDSE) {
							[PSCustomObject]@{
								DN = $distinguishedName
								Property = $propertyName
								File = $ldifFile.Name
								Setting = $definedState
								ADObject = $adObject
								ValueS = $definedState.State.$propertyName
								ValueA = $adObject.$propertyName
							}
						}
					}
				}
				else {
					foreach ($propertyName in $definedState.Add.Keys) {
						if (Compare-SchemaProperty -Setting $definedState.Add -ADObject $adObject -PropertyName $propertyName -RootDSE $rootDSE -Add) {
							[PSCustomObject]@{
								DN = $distinguishedName
								Property = $propertyName
								File = $ldifFile.Name
								Setting = $definedState
								ADObject = $adObject
								ValueS = $definedState.Add.$propertyName
								ValueA = $adObject.$propertyName
							}
						}
					}
					foreach ($propertyName in $definedState.Replace.Keys) {
						if (Compare-SchemaProperty -Setting $definedState.Replace -ADObject $adObject -PropertyName $propertyName -RootDSE $rootDSE) {
							[PSCustomObject]@{
								DN = $distinguishedName
								Property = $propertyName
								File = $ldifFile.Name
								Setting = $definedState
								ADObject = $adObject
								ValueS = $definedState.Replace.$propertyName
								ValueA = $adObject.$propertyName
							}
						}
					}
				}
			}
			#endregion Compare configured with real state ($offStateLdifName)

			$applicableLdif = $ldifSorted | Where-Object Name -in $ldifMapping[$distinguishedName].Keys
			$lastAppliedItem = $applicableLdif |
				Where-Object Name -notin $offStateLdif.File |
					Sort-Object Weight -Descending |
						Select-Object -First 1
			
			foreach ($ldifFile in $applicableLdif) {
				if ($ldifFile.Weight -lt $lastAppliedItem.Weight) { continue }
				if ($lastAppliedItem.Name -eq $ldifFile.Name) { continue }
				foreach ($entry in $offStateLdif) {
					if ($entry.File -ne $ldifFile.Name) { continue }
					$changes[$ldifFile.Name] += $entry
				}
			}
		}
		foreach ($schemaName in $changes.Keys) {
			if (-not $changes[$schemaName]) { continue }

			[PSCustomObject]@{
				PSTypeName = 'ForestManagement.SchemaLdif.TestResult'
				Type = 'InEqual'
				ObjectType = 'SchemaLdif'
				Identity = $schemaName
				Changed = $changes[$schemaName]
				Server = $forest.SchemaMaster
				DeltaCount = $changes[$schemaName].Count
				ADObject = $null
				Configuration = ($ldifSorted | Where-Object Name -eq $schemaName)
			}
		}
	}
}