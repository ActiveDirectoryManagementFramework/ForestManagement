function Test-FMSite {
	<#
		.SYNOPSIS
			Tests a target foret's site configuration with the desired state.
		
		.DESCRIPTION
			Tests a target foret's site configuration with the desired state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Test-FMSite

			Checks whether the current forest is compliant with the desired site configuration.
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
				PSTypeName = 'ForestManagement.Site.Update'
				Identity   = $Identity
				Property   = $Property
				OldValue   = $OldValue
				NewValue   = $NewValue
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
		Assert-Configuration -Type Sites -Cmdlet $PSCmdlet
		$allSites = Get-ADReplicationSite @parameters -Filter * -Properties Location
		$renameMapping = @{}
		$script:sites.Values | Where-Object OldNames | ForEach-Object {
			foreach ($oldName in $_.OldNames) {
				$renameMapping[$oldName] = $_.Name
			}
		}
	}
	process {
		$foundSites = @{}

		$resultDefaults = @{
			Server     = $Server
			ObjectType = 'Site'
		}
		
		foreach ($site in $allSites) {
			if ($renameMapping.Keys -contains $site.Name) {
				New-TestResult @resultDefaults -Type Rename -Identity $site.Name -Properties @{
					Name        = $site.Name
					Description = $site.Description
					Location    = $site.Location
					NewName     = $renameMapping[$site.Name]
				} -ADObject $site -Changed (New-Update -Identity $site.Name -Property Name -OldValue $site.Name -NewValue $renameMapping[$site.Name])
				continue
			}
			elseif ($script:sites.Keys -contains $site.Name) {
				$foundSites[$site.Name] = $site
			}
			else {
				New-TestResult @resultDefaults -Type Delete -Identity $site.Name -Properties @{
					Name        = $site.Name
					Description = $site.Description
					Location    = $site.Location
				} -ADObject $site
			}
		}
		foreach ($site in $script:sites.Values) {
			if ($site.Name -in $allSites.Name) { continue }

			New-TestResult @resultDefaults -Type Create -Identity $site.Name -Properties @{
				Name        = $site.Name
				Description = $site.Description
				Location    = $site.Location
			} -Configuration $site
		}

		foreach ($site in $foundSites.Values) {
			$deltaProperties = @()
			if ([string]($site.Location) -ne $script:sites[$site.Name].Location) {
				$deltaProperties += New-Update -Identity $site.Name -OldValue $site.Location -NewValue $script:sites[$site.Name].Location -Property 'Location'
			}
			if ([string]($site.Description) -ne $script:sites[$site.Name].Description) {
				$deltaProperties += New-Update -Identity $site.Name -OldValue $site.Description -NewValue $script:sites[$site.Name].Description -Property 'Description'
			}

			if (-not $deltaProperties) { continue }

			New-TestResult @resultDefaults -Type Update -Identity $site.Name -Properties @{
				Name        = $site.Name
				Description = $script:sites[$site.Name].Description
				Location    = $script:sites[$site.Name].Location
			} -ADObject $site -Configuration $script:sites[$site.Name] -Changed $deltaProperties
		}
	}
}