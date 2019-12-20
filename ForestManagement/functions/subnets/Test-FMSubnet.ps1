function Test-FMSubnet
{
	<#
		.SYNOPSIS
			Compares a forest's Subnet configuration against its desired state.
		
		.DESCRIPTION
			Compares a forest's Subnet configuration against its desired state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-FMSubnet

			Compares the current forest's Subnet configuration against its desired state.
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
		Assert-Configuration -Type Subnets -Cmdlet $PSCmdlet
		$allSubnets = Get-ADReplicationSubnet @parameters -Filter * -Properties Description | Select-Object *,  @{
			Name = "SiteName"
			Expression = { ($_.Site | Get-ADObject @parameters).Name }
		}
	}
	process
	{
		#region Test all Subnets found in the forest
		foreach ($subnetItem in $allSubnets) {
			if ($script:subnets.Keys -notcontains $subnetItem.Name) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Subnet.TestResult'
					Type = 'ForestOnly'
					ObjectType = 'Subnet'
					Identity = $subnetItem.Name
					Changed = $null
					Server = $Server
					SiteName = $subnetItem.SiteName
					Name = $subnetItem.Name
					Description = $subnetItem.Description
					Location = $subnetItem.Location
					ADObject = $subnetItem
				}
				continue
			}

			$configuredSubnet = $script:subnets[$subnetItem.Name]
			$isEqual = $true
			$deltaProperties = @()
			if ($subnetItem.SiteName -ne $configuredSubnet.SiteName) { $isEqual = $false; $deltaProperties += 'SiteName' }
			if ([string]($subnetItem.Description) -ne $configuredSubnet.Description) { $isEqual = $false; $deltaProperties += 'Description' }
			if ([string]($subnetItem.Location) -ne $configuredSubnet.Location) { $isEqual = $false; $deltaProperties += 'Location' }

			if (-not $isEqual)
			{
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Subnet.TestResult'
					Type = 'InEqual'
					ObjectType = 'Subnet'
					Identity = $subnetItem.Name
					Changed = $deltaProperties
					Server = $Server
					SiteName = $configuredSubnet.SiteName
					Name = $configuredSubnet.Name
					Description = $configuredSubnet.Description
					Location = $configuredSubnet.Location
					ADObject = $subnetItem
				}
			}
		}
		#endregion Test all Subnets found in the forest

		#region Catch subnets only in configuration but NOT in forest
		foreach ($configuredSubnet in $script:subnets.Values) {
			if ($allSubnets.Name -contains $configuredSubnet.Name) { continue }

			[PSCustomObject]@{
				PSTypeName = 'ForestManagement.Subnet.TestResult'
				Type = 'ConfigurationOnly'
				ObjectType = 'Subnet'
				Identity = $configuredSubnet.Name
				Changed = $null
				Server = $Server
				SiteName = $configuredSubnet.SiteName
				Name = $configuredSubnet.Name
				Description = $configuredSubnet.Description
				Location = $configuredSubnet.Location
				ADObject = $null
			}
		}
		#endregion Catch subnets only in configuration but NOT in forest
	}
}
