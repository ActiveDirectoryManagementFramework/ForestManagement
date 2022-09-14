function Test-FMSiteLink
{
	<#
		.SYNOPSIS
			Compares a live sitelink setup with the configured desired state.
		
		.DESCRIPTION
			Compares a live sitelink setup with the configured desired state.
	
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-FMSiteLink

			Tests the current forest for compliance with the sitelink configuration
	#>
	
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SiteLinks -Cmdlet $PSCmdlet
		$allSiteLinks = Get-ADReplicationSiteLink @parameters -Filter * -Properties Cost,Description, Options, Name, replInterval, siteList | Select-Object *
		$linksToExclude = @()

		#TODO: Rationalize to New-TestResult
		foreach ($siteLink in $allSiteLinks) {
			$count = 1
			foreach ($site in $siteLink.siteList) {
				try { Add-Member -InputObject $siteLink -MemberType NoteProperty -Name "Site$($count)" -Value (Get-ADObject @parameters -Identity $site -Properties Name).Name }
				catch { Add-Member -InputObject $siteLink -MemberType NoteProperty -Name "Site$($count)" -Value $site }
				$count++
			}
			#region More than 2 sites in Sitelink
			if ($siteLink.siteList.Count -ge 3) {
				if (Get-PSFConfigValue -FullName 'ForestManagement.SiteLink.MultilateralLinks') {
					Write-PSFMessage -Level Verbose -String 'Test-FMSiteLink.Information.MultipleSites' -StringValues $siteLink.DistinguishedName, $siteLink.siteList.Count -Tag sitelink, multiple_sites -Target $siteLink.DistinguishedName
					[pscustomobject]@{
						PSTypeName = 'ForestManagement.SiteLink.Information.MultipleSites'
						Type = 'SiteLink.MultipleSites'
						ObjectType = 'SiteLink'
						Identity = $siteLink.Name
						Changed = $null
						Server = $Server
						DistinguishedName = $siteLink.DistinguishedName
						Name = $siteLink.Name
						ADObject = $siteLink
					}
					$linksToExclude += $siteLink
				}
				else {
					Write-PSFMessage -Level Warning -String 'Test-FMSiteLink.Critical.TooManySites' -StringValues $siteLink.DistinguishedName, $siteLink.siteList.Count -Tag sitelink, critical, panic -Target $siteLink.DistinguishedName
					[pscustomobject]@{
						PSTypeName = 'ForestManagement.SiteLink.Critical.TooManySites'
						Type = 'SiteLink.TooManySites'
						ObjectType = 'SiteLink'
						Identity = $siteLink.Name
						Changed = $null
						Server = $Server
						DistinguishedName = $siteLink.DistinguishedName
						Name = $siteLink.Name
						ADObject = $siteLink
					}
					$linksToExclude += $siteLink
				}
			}
			#endregion More than 2 sites in Sitelink
			Add-Member -InputObject $siteLink -MemberType NoteProperty -Name IdealName -Value ('{0}-{1}' -f $siteLink.Site1, $siteLink.Site2)
		}
		$allSiteLinks = $allSiteLinks | Where-Object { $_ -notin $linksToExclude }
	}
	process
	{
		#region Test all sitelinks found in the forest
		foreach ($siteLink in $allSiteLinks) {
			if (-not (Get-FMSiteLink | Compare-SiteLink $siteLink)) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.SiteLink.TestResult'
					Type = 'ForestOnly'
					ObjectType = 'SiteLink'
					Identity = $siteLink.Name
					Changed = $null
					Server = $Server
					Name = $siteLink.Name
					Site1 = $siteLink.Site1
					Site2 = $siteLink.Site2
					IdealName = $siteLink.IdealName
					Cost = $siteLink.Cost
					Description = $siteLink.Description
					Options = $siteLink.Options
					ReplicationInterval = $siteLink.replInterval
					Configuration = $null
					ADObject = $siteLink
				}
				continue
			}

			$configuredSitelink = Get-FMSiteLink | Compare-SiteLink $siteLink | Select-Object -First 1
			$isEqual = $true
			$deltaProperties = @()

			if ($configuredSiteLink.Name -ne $siteLink.Name) { $isEqual = $false; $deltaProperties += 'Name' }
			if ($configuredSiteLink.Cost -ne $siteLink.Cost) { $isEqual = $false; $deltaProperties += 'Cost' }
			if ($configuredSiteLink.Description -ne ([string]($siteLink.Description))) { $isEqual = $false; $deltaProperties += 'Description' }
			if ($configuredSiteLink.Option -ne ([int]($siteLink.Options))) { $isEqual = $false; $deltaProperties += 'Options' }
			if ($configuredSiteLink.Interval -ne $siteLink.replInterval) { $isEqual = $false; $deltaProperties += 'ReplicationInterval' }

			if (-not $isEqual)
			{
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.SiteLink.TestResult'
					Type = 'InEqual'
					ObjectType = 'SiteLink'
					Identity = $siteLink.Name
					Changed = $deltaProperties
					Server = $Server
					Name = $configuredSitelink.Name
					Site1 = $configuredSitelink.Site1
					Site2 = $configuredSitelink.Site2
					IdealName = $configuredSitelink.Name
					Cost = $configuredSitelink.Cost
					Description = $configuredSitelink.Description
					Options = $configuredSitelink.Option
					ReplicationInterval = $configuredSitelink.Interval
					Configuration = $configuredSitelink
					ADObject = $siteLink
				}
			}
		}
		#endregion Test all sitelinks found in the forest

		foreach ($configuredSitelink in (Get-FMSiteLink)) {
			if ($allSiteLinks | Compare-SiteLink $configuredSitelink) { continue }

			[PSCustomObject]@{
				PSTypeName = 'ForestManagement.SiteLink.TestResult'
				Type = 'ConfigurationOnly'
				ObjectType = 'SiteLink'
				Identity = $configuredSitelink.Name
				Changed = $null
				Server = $Server
				Name = $configuredSitelink.Name
				Site1 = $configuredSitelink.Site1
				Site2 = $configuredSitelink.Site2
				IdealName = $configuredSitelink.Name
				Cost = $configuredSitelink.Cost
				Description = $configuredSitelink.Description
				Options = $configuredSitelink.Option
				ReplicationInterval = $configuredSitelink.Interval
				Configuration = $configuredSitelink
				ADObject = $null
			}
		}
	}
}
