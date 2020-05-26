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
	}
	process {
		# Pick up termination flag from Stop-PSFFunction and interrupt if begin failed to connect
		if (Test-PSFFunctionInterrupt) { return }

		foreach ($schemaSetting in (Get-FMSchema)) {
			$schemaObject = $null
			$schemaObject = Get-ADObject @parameters -LDAPFilter "(attributeID=$($schemaSetting.OID))" -SearchBase $rootDSE.schemaNamingContext -ErrorAction Ignore -Properties *

			if (-not $schemaObject) {
				# If we already want to disable the attribute, no need to create it
				if ($schemaSetting.Defunct) { continue }

				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'ConfigurationOnly'
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

			$isEqual = $true
			$deltaProperties = @()
			
			if ($schemaSetting.OMSyntax -ne $schemaObject.oMSyntax) { $isEqual = $false; $deltaProperties += 'OMSyntax' }
			if ($schemaSetting.AttributeSyntax -ne $schemaObject.attributeSyntax) { $isEqual = $false; $deltaProperties += 'AttributeSyntax' }
			if ($schemaSetting.SingleValued -ne $schemaObject.isSingleValued) { $isEqual = $false; $deltaProperties += 'SingleValued' }
			if ($schemaSetting.AdminDescription -cne $schemaObject.adminDescription) { $isEqual = $false; $deltaProperties += 'AdminDescription' }
			if ($schemaSetting.AdminDisplayName -cne $schemaObject.adminDisplayName) { $isEqual = $false; $deltaProperties += 'AdminDisplayName' }
			if ($schemaSetting.LdapDisplayName -cne $schemaObject.ldapDisplayName) { $isEqual = $false; $deltaProperties += 'LdapDisplayName' }
			if ($schemaSetting.SearchFlags -ne $schemaObject.searchflags) { $isEqual = $false; $deltaProperties += 'SearchFlags' }
			if ($schemaSetting.PartialAttributeSet -ne $schemaObject.isMemberOfPartialAttributeSet) { $isEqual = $false; $deltaProperties += 'PartialAttributeSet' }
			if ($schemaSetting.AdvancedView -ne $schemaObject.showInAdvancedViewOnly) { $isEqual = $false; $deltaProperties += 'AdvancedView' }

			if (-not $schemaSetting.IsDefunct) {
				$mayContain = Get-ADObject @parameters -LDAPFilter "(mayContain=$($schemaSetting.LdapDisplayName))" -SearchBase $rootDSE.schemaNamingContext
				if (-not $mayContain -and $schemaSetting.ObjectClass) {
					$isEqual = $false
					$deltaProperties += 'ObjectClass'
				}
				elseif ($mayContain.Name -and -not $schemaSetting.ObjectClass) {
					$isEqual = $false
					$deltaProperties += 'ObjectClass'
				}
				elseif (-not $mayContain.Name -and -not $schemaSetting.ObjectClass) {
					# Nothing wrong here
				}
				elseif ($mayContain.Name | Compare-Object $schemaSetting.ObjectClass) {
					$isEqual = $false
					$deltaProperties += 'ObjectClass'
				}
			}

			if (-not $isEqual) {
				[PSCustomObject]@{
					PSTypeName    = 'ForestManagement.Schema.TestResult'
					Type          = 'InEqual'
					ObjectType    = 'Schema'
					Identity      = $schemaSetting.AdminDisplayName
					Changed       = $deltaProperties
					Server        = $forest.SchemaMaster
					ADObject      = $schemaObject
					Configuration = $schemaSetting
				}
			}
		}
	}
}