function Test-FMSiteLink {
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
	
	begin {
		#region Functions
		function New-Update {
			[CmdletBinding()]
			param (
				$Identity,

				$Property,

				$OldValue,

				$NewValue
			)

			$datum = [PSCustomObject]@{
				PSTypeName = 'ForestManagement.SiteLink.Update'
				Identity = $Identity
				Property = $Property
				OldValue = $OldValue
				NewValue = $NewValue
			}
			Add-Member -InputObject $datum -MemberType ScriptMethod -Name ToString -Value {
				'{0}: {1} -> {2}' -f $this.Property, $this.OldValue, $this.NewValue
			} -Force
			$datum
		}
		#endregion Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SiteLinks -Cmdlet $PSCmdlet
		$allSiteLinks = Get-ADReplicationSiteLink @parameters -Filter * -Properties Cost, Description, Options, Name, replInterval, siteList | Select-Object *
		$linksToExclude = @()

		$resultDefaults = @{
			ObjectType = 'SiteLink'
			Server     = $Server
		}

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
					New-TestResult @resultDefaults -Type MultipleSites -Identity $siteLink.Name -ADObject $siteLink -Properties @{
						Name              = $siteLink.Name
						DistinguishedName = $siteLink.DistinguishedName
					}
				}
				else {
					Write-PSFMessage -Level Warning -String 'Test-FMSiteLink.Critical.TooManySites' -StringValues $siteLink.DistinguishedName, $siteLink.siteList.Count -Tag sitelink, critical, panic -Target $siteLink.DistinguishedName
					New-TestResult @resultDefaults -Type TooManySites -Identity $siteLink.Name -ADObject $siteLink -Properties @{
						Name              = $siteLink.Name
						DistinguishedName = $siteLink.DistinguishedName
					}
				}
				$linksToExclude += $siteLink
			}
			#endregion More than 2 sites in Sitelink
			Add-Member -InputObject $siteLink -MemberType NoteProperty -Name IdealName -Value ('{0}-{1}' -f $siteLink.Site1, $siteLink.Site2)
		}
		$allSiteLinks = $allSiteLinks | Where-Object { $_ -notin $linksToExclude }
	}
	process {
		#region Test all sitelinks found in the forest
		foreach ($siteLink in $allSiteLinks) {
			if (-not (Get-FMSiteLink | Compare-SiteLink $siteLink)) {
				New-TestResult @resultDefaults -Type Delete -Identity $siteLink.Name -ADObject $siteLink -Properties @{
					Name                = $siteLink.Name
					Site1               = $siteLink.Site1
					Site2               = $siteLink.Site2
					IdealName           = $siteLink.IdealName
					Cost                = $siteLink.Cost
					Description         = $siteLink.Description
					Options             = $siteLink.Options
					ReplicationInterval = $siteLink.replInterval
				}
				continue
			}

			$configuredSitelink = Get-FMSiteLink | Compare-SiteLink $siteLink | Select-Object -First 1
			$deltaProperties = @()

			#region Compare Properties
			if ($configuredSiteLink.Name -ne $siteLink.Name) {
				$deltaProperties += New-Update -Identity $siteLink.Name -OldValue $siteLink.Name -NewValue $configuredSitelink.Name -Property 'Name'
			}
			if ($configuredSiteLink.Cost -ne $siteLink.Cost) {
				$deltaProperties += New-Update -Identity $siteLink.Name -OldValue $siteLink.Cost -NewValue $configuredSitelink.Cost -Property 'Cost'
			}
			if ($configuredSiteLink.Description -ne ([string]($siteLink.Description))) {
				$deltaProperties += New-Update -Identity $siteLink.Name -OldValue ([string]($siteLink.Description)) -NewValue $configuredSitelink.Description -Property 'Description'
			}
			if ($configuredSiteLink.Option -ne ([int]($siteLink.Options))) {
				$deltaProperties += New-Update -Identity $siteLink.Name -OldValue ([int]($siteLink.Options)) -NewValue $configuredSitelink.Option -Property 'Options'
			}
			if ($configuredSiteLink.Interval -ne $siteLink.replInterval) {
				$deltaProperties += New-Update -Identity $siteLink.Name -OldValue $siteLink.replInterval -NewValue $configuredSitelink.Interval -Property 'ReplicationInterval'
			}
			#endregion Compare Properties

			if ($deltaProperties) {
				New-TestResult @resultDefaults -Type Update -Identity $siteLink.Name -ADObject $siteLink -Configuration $configuredSitelink -Properties @{
					Name                = $configuredSitelink.Name
					Site1               = $configuredSitelink.Site1
					Site2               = $configuredSitelink.Site2
					IdealName           = $configuredSitelink.Name
					Cost                = $configuredSitelink.Cost
					Description         = $configuredSitelink.Description
					Options             = $configuredSitelink.Option
					ReplicationInterval = $configuredSitelink.Interval
				} -Changed $deltaProperties
			}
		}
		#endregion Test all sitelinks found in the forest

		foreach ($configuredSitelink in (Get-FMSiteLink)) {
			if ($allSiteLinks | Compare-SiteLink $configuredSitelink) { continue }

			New-TestResult @resultDefaults -Type Create -Identity $configuredSitelink.Name -Configuration $configuredSitelink -Properties @{
				Name                = $configuredSitelink.Name
				Site1               = $configuredSitelink.Site1
				Site2               = $configuredSitelink.Site2
				IdealName           = $configuredSitelink.Name
				Cost                = $configuredSitelink.Cost
				Description         = $configuredSitelink.Description
				Options             = $configuredSitelink.Option
				ReplicationInterval = $configuredSitelink.Interval
			}
		}
	}
}