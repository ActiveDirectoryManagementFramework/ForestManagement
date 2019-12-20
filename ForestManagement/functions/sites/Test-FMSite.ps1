function Test-FMSite
{
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
	
	begin
	{
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
	process
	{
		$foundSites  = @{}
		
		foreach ($site in $allSites) {
			if ($renameMapping.Keys -contains $site.Name) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Site.TestResult'
					Type = 'RenamePending'
					ObjectType = 'Site'
					Identity = $site.Name
					Changed = 'Name'
					Server = $Server
					Name = $site.Name
					Description = $site.Description
					Location = $site.Location
					NewName = $renameMapping[$site.Name]
					ADObject = $site
				}
			}
			elseif ($script:sites.Keys -contains $site.Name) {
				$foundSites[$site.Name] = $site
			}
			else {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Site.TestResult'
					Type = 'ForestOnly'
					ObjectType = 'Site'
					Identity = $site.Name
					Changed = $null
					Server = $Server
					Name = $site.Name
					Description = $site.Description
					Location = $site.Location
					ADObject = $site
				}
			}
		}
		foreach ($site in $script:sites.Values) {
			if ($site.Name -notin $allSites.Name) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Site.TestResult'
					Type = 'ConfigurationOnly'
					ObjectType = 'Site'
					Identity = $site.Name
					Changed = $null
					Server = $Server
					Name = $site.Name
					Description = $site.Description
					Location = $site.Location
					ADObject = $null
				}
			}
		}

		foreach ($site in $foundSites.Values) {
			$isEqual = $true
			$deltaProperties = @()
			if ([string]($site.Location) -ne $script:sites[$site.Name].Location) { $isEqual = $false; $deltaProperties += 'Location' }
			if ([string]($site.Description) -ne $script:sites[$site.Name].Description) { $isEqual = $false; $deltaProperties += 'Description' }

			if ($isEqual) { continue }

			[PSCustomObject]@{
				PSTypeName = 'ForestManagement.Site.TestResult'
				Type = 'InEqual'
				ObjectType = 'Site'
				Identity = $site.Name
				Changed = $deltaProperties
				Server = $Server
				Name = $site.Name
				Description = $script:sites[$site.Name].Description
				Location = $script:sites[$site.Name].Location
				ADObject = $site
			}
		}
	}
}
