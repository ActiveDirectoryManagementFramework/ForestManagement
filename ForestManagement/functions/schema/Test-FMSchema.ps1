function Test-FMSchema {
	<#
		.SYNOPSIS
			Compare the current schema with the configured / desired configuration state.
		
		.DESCRIPTION
			Compare the current schema with the configured / desired configuration state.
			Only compares the custom configured settings, ignores any changes outside.
			(So it's not a delta comparison to the AD baseline)
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.

		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.
		
		.EXAMPLE
			PS C:\> Test-FMSchema

			Tests the current domain's schema configuration.
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
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Schema -Cmdlet $PSCmdlet
		try { $rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Test-FMSchema.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$forest = Get-ADForest @parameters
		$parameters["Server"] = $forest.SchemaMaster

		#region Display Code
		$objectClassToString = {
			$updates = do {
				$this.New | Where-Object { $_ -notin @($this.Old) } | Format-String '+{0}'
				$this.Old | Where-Object { $_ -notin @($this.New) } | Format-String '-{0}'
			}
			until ($true)
			'ObjectClass: {0}' -f ($updates -join ', ')
		}
		#endregion Display Code
	}
	process {
		# Pick up termination flag from Stop-PSFFunction and interrupt if begin failed to connect
		if (Test-PSFFunctionInterrupt) { return }

		foreach ($schemaSetting in (Get-FMSchema)) {
			$schemaObject = $null
			$schemaObject = Get-ADObject @parameters -LDAPFilter "(attributeID=$($schemaSetting.OID))" -SearchBase $rootDSE.schemaNamingContext -ErrorAction Ignore -Properties *

			if (-not $schemaObject) {
				# If we already want to disable the attribute, no need to create it
				if ($schemaSetting.IsDefunct) { continue }
				if ($schemaSetting.Optional) { continue }

				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'Create'
					ObjectType    = 'Schema'
					Identity      = $schemaSetting.AdminDisplayName
					Changed       = $null
					Server        = $forest.SchemaMaster
					ADObject      = $null
					Configuration = $schemaSetting
				}
				continue
			}

			if ($schemaSetting.IsDefunct -and -not $schemaObject.isDefunct) {
				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'Decommission'
					ObjectType    = 'Schema'
					Identity      = $schemaSetting.AdminDisplayName
					Changed       = @('IsDefunct')
					Server        = $forest.SchemaMaster
					ADObject      = $schemaObject
					Configuration = $schemaSetting
				}
			}

			if ($schemaSetting.Name -cne $schemaObject.cn) {
				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'Rename'
					ObjectType    = 'Schema'
					Identity      = $schemaSetting.AdminDisplayName
					Changed       = @('Name')
					Server        = $forest.SchemaMaster
					ADObject      = $schemaObject
					Configuration = $schemaSetting
				}
			}

			$changes = [System.Collections.ArrayList]@()

			$param = @{
				Configuration = $schemaSetting
				ADObject      = $schemaObject
				CaseSensitive = $true
				IfExists      = $true
				Changes       = $changes
				Type          = 'Schema'
			}
			Compare-AdcProperty @param -Property oMSyntax
			Compare-AdcProperty @param -Property attributeSyntax
			Compare-AdcProperty @param -Property SingleValued -ADProperty isSingleValued
			Compare-AdcProperty @param -Property adminDescription
			Compare-AdcProperty @param -Property adminDisplayName
			Compare-AdcProperty @param -Property ldapDisplayName
			Compare-AdcProperty @param -Property searchflags
			Compare-AdcProperty @param -Property PartialAttributeSet -ADProperty isMemberOfPartialAttributeSet
			Compare-AdcProperty @param -Property AdvancedView -ADProperty showInAdvancedViewOnly
			if (-not $schemaSetting.IsDefunct -and $schemaObject.isDefunct) {
				Compare-AdcProperty @param -Property isDefunct
			}

			if (-not $schemaSetting.IsDefunct -and $schemaSetting.PSObject.Properties.Name -contains 'Objectclass') {
				$mayContain = Get-ADObject @parameters -LDAPFilter "(mayContain=$($schemaSetting.LdapDisplayName))" -SearchBase $rootDSE.schemaNamingContext
				if (-not $mayContain -and $schemaSetting.ObjectClass) {
					$null = $changes.Add((New-AdcChange -Property ObjectClass -NewValue $schemaSetting.ObjectClass -Identity $schemaObject.DistinguishedName -Type Schema -ToString $objectClassToString))
				}
				elseif ($mayContain.Name -and -not $schemaSetting.ObjectClass) {
					$null = $changes.Add((New-AdcChange -Property ObjectClass -OldValue $mayContain.Name -Identity $schemaObject.DistinguishedName -Type Schema -ToString $objectClassToString))
				}
				elseif (-not $mayContain.Name -and -not $schemaSetting.ObjectClass) {
					# Nothing wrong here
				}
				elseif ($mayContain.Name | Compare-Object $schemaSetting.ObjectClass) {
					$null = $changes.Add((New-AdcChange -Property ObjectClass -OldValue $mayContain.Name -NewValue $schemaSetting.ObjectClass -Identity $schemaObject.DistinguishedName -Type Schema -ToString $objectClassToString))
				}
			}

			if ($changes.Count -gt 0) {
				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'Update'
					ObjectType    = 'Schema'
					Identity      = $schemaSetting.AdminDisplayName
					Changed       = $changes.ToArray()
					Server        = $forest.SchemaMaster
					ADObject      = $schemaObject
					Configuration = $schemaSetting
				}
			}
		}
	}
}