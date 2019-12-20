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
		foreach ($schemaFile in (Get-FMSchemaLdif)) {
			$countDelta = 0
			$changes = @()

			:setting foreach ($setting in $schemaFile.Settings) {
				if (-not $setting.DistinguishedName) { continue }
				$attributeName = '{0},{1}' -f $setting.DistinguishedName, $rootDSE.schemaNamingContext

				#region Calculate deltas
				try { $adObject = Get-ADObject @parameters -Identity $attributeName -ErrorAction Stop -Properties * }
				catch {
					$countDelta++
					$changes += [PSCustomObject]@{
						LdifName = $schemaFile.Name
						LdifPath = $schemaFile.Path
						Type = 'Missing'
						Object  = $attributeName
						Properties = @()
					}
					continue
				}

				switch ($setting.changetype)
				{
					#region New Item Definitions
					'add'
					{
						$change = [PSCustomObject]@{
							LdifName = $schemaFile.Name
							LdifPath = $schemaFile.Path
							Type = 'InEqual'
							Object  = $attributeName
							Properties = @()
						}
						:prop foreach ($property in $setting.PSObject.Properties.Name) {
							switch ($property) {
								'DistinguishedName' { continue prop }
								'changetype' { continue prop }
								'schemaIDGUID' {
									if (($setting.$property.GuidData -join '|') -ne ($adObject.$property -join '|')) {
										$countDelta++
										$change.Properties += $property
									}
								}
								'attributeSecurityGUID' {
									if (($setting.$property.GuidData -join '|') -ne ($adObject.$property -join '|')) {
										$countDelta++
										$change.Properties += $property
									}
								}
								'objectCategory' {
									if (($setting.$property -replace '<SchemaContainerDN>',$rootDSE.schemaNamingContext) -ne ($adObject.$property -join '|')) {
										$countDelta++
										$change.Properties += $property
									}
								}
								default {
									foreach ($item in $setting.$property) {
										if ($item -notin $adObject.$property) {
											$countDelta++
											$change.Properties += $property
											continue prop
										}
									}
								}
							}
						}
						if ($change.Properties.Count -gt 0) {
							$changes += $change
						}
					}
					#endregion New Item Definitions

					#region Deltas
					'modify'
					{
						if ($setting.Add) {
							$propName = $setting.Add
							if ($setting.$propName | Where-Object { $_ -notin $adObject.$propName }) {
								$countDelta++
								$changes += [PSCustomObject]@{
									LdifName = $schemaFile.Name
									LdifPath = $schemaFile.Path
									Type = 'Missing'
									Object  = $attributeName
									Properties = @($propName)
								}
								continue setting
							}
						}
						elseif ($setting.Replace) {
							$propName = $setting.Replace
							if ($setting.$propName -ne $adObject.$propName) {
								$countDelta++
								$changes += [PSCustomObject]@{
									LdifName = $schemaFile.Name
									LdifPath = $schemaFile.Path
									Type = 'InEqual'
									Object  = $attributeName
									Properties = @($propName)
								}
								continue setting
							}
						}
						else {
							$change = [PSCustomObject]@{
								LdifName = $schemaFile.Name
								LdifPath = $schemaFile.Path
								Type = 'InEqual'
								Object  = $attributeName
								Properties = @()
							}
							:prop foreach ($property in $setting.PSObject.Properties.Name) {
								switch ($property) {
									'DistinguishedName' { continue prop }
									'changetype' { continue prop }
									'schemaIDGUID' {
										if (($setting.$property.GuidData -join '|') -ne ($adObject.$property -join '|')) {
											$countDelta++
											$change.Properties += $property
										}
									}
									'attributeSecurityGUID' {
										if (($setting.$property.GuidData -join '|') -ne ($adObject.$property -join '|')) {
											$countDelta++
											$change.Properties += $property
										}
									}
									'objectCategory' {
										if (($setting.$property -replace '<SchemaContainerDN>',$rootDSE.schemaNamingContext) -ne ($adObject.$property -join '|')) {
											$countDelta++
											$change.Properties += $property
										}
									}
									default {
										foreach ($item in $setting.$property) {
											if ($item -notin $adObject.$property) {
												$countDelta++
												$change.Properties += $property
												continue prop
											}
										}
									}
								}
							}
							if ($change.Properties.Count -gt 0) {
								$changes += $change
							}
						}
					}
					#endregion Deltas
				}
				#endregion Calculate deltas


			}

			if ($countDelta -gt 0) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.SchemaLdif.TestResult'
					Type = 'InEqual'
					ObjectType = 'SchemaLdif'
					Identity = $schemaFile.Name
					Changed = ($changes.Object | Select-Object -Unique)
					Server = $forest.SchemaMaster
					DeltaCount = $countDelta
					Changes = $changes
					ADObject = $null
					Configuration = $schemaFile
				}
			}
		}
	}
}
