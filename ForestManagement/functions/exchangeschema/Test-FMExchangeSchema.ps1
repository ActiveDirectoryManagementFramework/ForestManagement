function Test-FMExchangeSchema {
	<#
	.SYNOPSIS
		Tests, whether the desired Exchange version has already been applied to the Forest.
	
	.DESCRIPTION
		Tests, whether the desired Exchange version has already been applied to the Forest.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-FMExchangeSchema -Server contoso.com
	
		Tests whether the desired Exchange version has already been applied to the contoso.com forest.
#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type ExchangeSchema -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters
		
		#region Utility Functions
		function Get-ExchangeRangeUpper {
			[CmdletBinding()]
			param (
				[hashtable]
				$Parameters
			)
			
			$rootDSE = Get-ADRootDSE @parameters
			(Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=ms-Exch-Schema-Version-Pt)" -Properties rangeUpper).rangeUpper
		}
		
		function Get-ExchangeObjectVersion {
			[CmdletBinding()]
			param (
				[hashtable]
				$Parameters
			)
			
			$rootDSE = Get-ADRootDSE @parameters
			(Get-ADObject @parameters -SearchBase $rootDSE.configurationNamingContext -LDAPFilter '(objectClass=msExchOrganizationContainer)' -Properties ObjectVersion).ObjectVersion
		}
		
		function Get-ExchangeOrganizationName {
			[CmdletBinding()]
			param (
				[hashtable]
				$Parameters
			)
			
			$rootDSE = Get-ADRootDSE @parameters
			(Get-ADObject @parameters -SearchBase $rootDSE.configurationNamingContext -LDAPFilter '(objectClass=msExchOrganizationContainer)').Name
		}
		#endregion Utility Functions
	}
	process {
		$forest = Get-ADForest @parameters
		$schemaVersion = Get-ExchangeRangeUpper -Parameters $parameters
		$objectVersion = Get-ExchangeObjectVersion -Parameters $parameters
		$displayName = (Get-AdcExchangeVersion | Where-Object RangeUpper -EQ $schemaVersion | Where-Object ObjectVersionConfig -EQ $objectVersion | Sort-Object Name | Select-Object -Last 1).Name
		$splitPermissionsEnabled = Test-ADObject @parameters -Identity ("OU=Microsoft Exchange Protected Groups,%DomainDN%" | Resolve-String)

		$adData = [pscustomobject]@{
			SchemaVersion    = $schemaVersion
			ObjectVersion    = $objectVersion
			DisplayName      = $displayName
			OrganizationName = Get-ExchangeOrganizationName -Parameters $parameters
			SplitPermissions = $splitPermissionsEnabled
		}
		Add-Member -InputObject $adData -MemberType ScriptMethod -Name ToString -Value {
			if ($this.DisplayName) { $this.DisplayName }
			else { '{0} : {1}' -f $this.SchemaVersion, $this.ObjectVersion }
		} -Force
		$configuredData = Get-FMExchangeSchema

		$common = @{
			ObjectType    = 'ExchangeSchema'
			Identity      = $forest
			Server        = $Server
			Configuration = $configuredData
			ADObject      = $adData
		}
		
		if ($configuredData.SchemaOnly) {
			if (-not $schemaVersion) {
				New-TestResult @common -Type CreateSchema
			}
			elseif ($configuredData.RangeUpper -gt $schemaVersion) {
				New-TestResult @common -Type UpdateSchema
			}
			return
		}
		
		if (-not $schemaVersion -or -not $objectVersion) {
			New-TestResult @common -Type Create
			return
		}
		if (($configuredData.RangeUpper -gt $schemaVersion) -or ($configuredData.ObjectVersion -gt $objectVersion)) {
			New-TestResult @common -Type Update
		}
		if ($splitPermissionsEnabled -and -not $configuredData.SplitPermission) {
			New-TestResult @common -Type DisableSplitP
		}
		if (-not $splitPermissionsEnabled -and $configuredData.SplitPermission) {
			New-TestResult @common -Type EnableSplitP
		}
	}
}
