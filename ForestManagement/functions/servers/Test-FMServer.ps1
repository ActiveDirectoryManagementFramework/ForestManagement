function Test-FMServer
{
	<#
		.SYNOPSIS
			Checks whether the Domain Controller in a forest are in the correct site.
		
		.DESCRIPTION
			Checks whether the Domain Controller in a forest are in the correct site.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Test-FMServer

			Tests, whethether all domain controllers in the current forest are up-to-date.
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
		$rootDSE = Get-ADRootDSE @parameters
		$searchBase = "CN=Sites,$($rootDSE.configurationNamingContext)"
		$domainControllers = Get-ADObject @parameters -LDAPFilter '(objectClass=server)' -SearchBase $searchBase -Properties * | Select-Object *, IPAddress, @{
			Name = 'SiteName'
			Expression = { $_.DistinguishedName -replace ".+,CN=(.+?),CN=Sites,CN=Configuration,DC=.+",'$1' }
		}
		foreach ($domainController in $domainControllers) {
			if ($domainController.DNSHostName) {
				$domainController.IPAddress = [IPAddress](Resolve-DnsName -Name $domainController.DNSHostName -ErrorAction Ignore -Debug:$false | Where-Object Type -eq A | Select-Object -First 1).IPAddress
			}
		}
		$allSubnets = Get-ADReplicationSubnet @parameters -Filter * -Properties Description | Select-PSFObject 'Name',  @{
			Name = "SiteName"
			Expression = { ($_.Site | Get-ADObject @parameters).Name }
		}, 'Name.Split("/")[0] AS IPBase TO IPAddress', 'Name.Split("/")[1].Split("´n")[0] AS MaskSize To Int', Mask, site | Where-Object Name -notlike "*CNF*" | Sort-Object MaskSize -Descending
		foreach ($subnet in $allSubnets) {
			$subnet.Mask = ConvertTo-SubnetMask -MaskSize $subnet.MaskSize
		}
	}
	process
	{
		:main foreach ($domainController in $domainControllers) {
			#region No IP Address
			if (-not $domainController.IPAddress) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Server.TestResult'
					Type = 'AddressNotFound'
					ObjectType = 'Server'
					Identity = $domainController.Name
					Changed = $null
					Server = $Server
					CurrentSite = $domainController.SiteName
					SupposedSite = $null
					FoundSubnet = $null
					ADObject = $domainController
				}
				continue
			}
			#endregion No IP Address

			#region Resolving Subnet
			$foundSubnet = $null
			foreach ($subnet in $allSubnets) {
				if (Test-Subnet -NetworkAddress $subnet.IPBase -MaskAddress $subnet.Mask -HostAddress $domainController.IPAddress) {
					$foundSubnet = $subnet
					break
				}
			}

			if (-not $foundSubnet) {
				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Server.TestResult'
					Type = 'NoMatchingSubnet'
					ObjectType = 'Server'
					Identity = $domainController.Name
					Changed = $null
					Server = $Server
					CurrentSite = $domainController.SiteName
					SupposedSite = $null
					FoundSubnet = $null
					ADObject = $domainController
				}
				continue
			}
			#endregion Resolving Subnet

			if ($domainController.SiteName -ne $foundSubnet.SiteName) {
				$currentSiteSubnets = $allSubnets | Where-Object SiteName -eq $domainController.SiteName
				foreach ($subnet in $currentSiteSubnets) {
					# Domain Controller is legally in his current site
					if (Test-Subnet -NetworkAddress $subnet.IPBase -MaskAddress $subnet.Mask -HostAddress $domainController.IPAddress) {
						Write-PSFMessage -Level InternalComment -String 'Test-FMServer.SiteConflict' -StringValues $domainController.Name, $foundSubnet.SiteName, $domainController.SiteName, $foundSubnet.Name -Tag 'note' -Target $domainController.Name
						continue main
					}
				}

				[PSCustomObject]@{
					PSTypeName = 'ForestManagement.Server.TestResult'
					Type = 'BadSite'
					ObjectType = 'Server'
					Identity = $domainController.Name
					Changed = $foundSubnet.SiteName
					Server = $Server
					CurrentSite = $domainController.SiteName
					SupposedSite = $foundSubnet.SiteName
					FoundSubnet = $foundSubnet
					ADObject = $domainController
				}
			}
		}
	}
}
