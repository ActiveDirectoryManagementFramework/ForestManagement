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

		.PARAMETER ReportUnconfigured
			Whether to generate test results for unconfigured schema attributes.

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
		$ReportUnconfigured = (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Attributes.ReportUnconfigured'),

		[switch]
		$EnableException
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Schema -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters

		try { $rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Test-FMSchema.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$forest = Get-ADForest @parameters
		$parameters["Server"] = $forest.SchemaMaster

		#region Display Code
		$mayContainToString = {
			$updates = do {
				$this.New | Where-Object { $_ -notin @($this.Old) } | Format-String '+{0}'
				$this.Old | Where-Object { $_ -notin @($this.New) } | Format-String '-{0}'
			}
			until ($true)
			'mayContain: {0}' -f ($updates -join ', ')
		}
		$mustContainToString = {
			$updates = do {
				$this.New | Where-Object { $_ -notin @($this.Old) } | Format-String '+{0}'
				$this.Old | Where-Object { $_ -notin @($this.New) } | Format-String '-{0}'
			}
			until ($true)
			'mustContain: {0}' -f ($updates -join ', ')
		}
		#endregion Display Code
	}
	process {
		# Pick up termination flag from Stop-PSFFunction and interrupt if begin failed to connect
		if (Test-PSFFunctionInterrupt) { return }

		$allAttributes = Get-ADObject @parameters -LDAPFilter "(attributeID=*)" -SearchBase $rootDSE.schemaNamingContext -ErrorAction Ignore -Properties *
		$allClasses = Get-ADObject @parameters -LDAPFilter "(objectClass=classSchema)" -SearchBase $rootDSE.schemaNamingContext -ErrorAction Ignore -Properties *

		#region Process Configuration
		$results = foreach ($schemaSetting in (Get-FMSchema)) {
			$schemaObject = $null
			$schemaObject = $allAttributes.Where{ $_.attributeID -eq $schemaSetting.OID }[0]

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
				AsUpdate      = $true
				Changes       = $changes
				Type          = 'Schema'
			}
			Compare-AdcProperty @param -Property oMSyntax
			Compare-AdcProperty @param -Property attributeSyntax
			Compare-AdcProperty @param -Property SingleValued -ADProperty isSingleValued
			Compare-AdcProperty @param -Property adminDescription -AsString
			Compare-AdcProperty @param -Property adminDisplayName
			Compare-AdcProperty @param -Property ldapDisplayName
			Compare-AdcProperty @param -Property searchflags
			Compare-AdcProperty @param -Property PartialAttributeSet -ADProperty isMemberOfPartialAttributeSet
			Compare-AdcProperty @param -Property AdvancedView -ADProperty showInAdvancedViewOnly
			if (-not $schemaSetting.IsDefunct -and $schemaObject.isDefunct) {
				Compare-AdcProperty @param -Property isDefunct
			}

			if (-not $schemaSetting.IsDefunct -and $schemaSetting.PSObject.Properties.Name -contains 'MayBeContainedIn') {
				$mayContain = $allClasses.Where{ $_.MayContain -contains $schemaSetting.LdapDisplayName }
				if (-not $mayContain -and $schemaSetting.MayBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MayContain -NewValue $schemaSetting.MayBeContainedIn -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mayContainToString))
				}
				elseif ($mayContain.Name -and -not $schemaSetting.MayBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MayContain -OldValue $mayContain.Name -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mayContainToString))
				}
				elseif (-not $mayContain.Name -and -not $schemaSetting.MayBeContainedIn) {
					# Nothing wrong here
				}
				elseif ($mayContain.Name | Compare-Object $schemaSetting.MayBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MayContain -OldValue $mayContain.Name -NewValue $schemaSetting.MayBeContainedIn -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mayContainToString))
				}
			}

			if (-not $schemaSetting.IsDefunct -and $schemaSetting.PSObject.Properties.Name -contains 'MustBeContainedIn') {
				$mustContain = $allClasses.Where{ $_.mustContain -contains $schemaSetting.LdapDisplayName }
				if (-not $mustContain -and $schemaSetting.MustBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MustContain -NewValue $schemaSetting.MustBeContainedIn -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mustContainToString))
				}
				elseif ($mustContain.Name -and -not $schemaSetting.MustBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MustContain -OldValue $mustContain.Name -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mustContainToString))
				}
				elseif (-not $mustContain.Name -and -not $schemaSetting.MustBeContainedIn) {
					# Nothing wrong here
				}
				elseif ($mustContain.Name | Compare-Object $schemaSetting.MustBeContainedIn) {
					$null = $changes.Add((New-AdcChange -Property MustContain -OldValue $mustContain.Name -NewValue $schemaSetting.MustBeContainedIn -Identity $schemaObject.DistinguishedName -Type Schema -ToString $mustContainToString))
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

		# Ensure tests are returned in sorting order needed to invoke.
		# Invoke-FMSchema doesn't care - it invokes correctly - but Invoke-AdmfItem will have issues otherwise
		$results | Sort-Object Identity, {
			if ($_.Type -eq 'Decommission') { 0 }
			elseif ($_.Type -eq 'Rename') { 2 }
			elseif ($_.Type -eq 'ConfigurationOnly') { 3 }
			else { 1 }
		}
		#endregion Process Configuration

		#region Process AD Only
		if (-not $ReportUnconfigured) { return }
		$unconfigured = $allAttributes | Where-Object attributeID -NotIn (Get-FMSchema).OID
		foreach ($unexpectedAttribute in $unconfigured) {
			if ($unexpectedAttribute.IsDefunct) { continue }
			[PSCustomObject]@{
				PSTypeName    = 'ForestManagement.Schema.TestResult'
				Type          = 'Unmanaged'
				ObjectType    = 'Schema'
				Identity      = $unexpectedAttribute.AdminDisplayName
				Changed       = $null
				Server        = $forest.SchemaMaster
				ADObject      = $unexpectedAttribute
				Configuration = $null
			}
		}
		#endregion Process AD Only
	}
}