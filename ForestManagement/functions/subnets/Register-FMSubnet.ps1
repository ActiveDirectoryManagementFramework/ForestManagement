function Register-FMSubnet
{
	<#
		.SYNOPSIS
			Registers a new subnet assignment.
		
		.DESCRIPTION
			Registers a new subnet assignment.
			Subnets are assigned to sites.
		
		.PARAMETER SiteName
			Name of the site to which subnets are being assigned.
		
		.PARAMETER Name
			Subnet to assign.
			Must be a subnet in the following notation:
			<ipv4address>/<subnetsize>
			E.g.: 1.2.3.4/24

		.PARAMETER Description
			Description to add to the subnet

		.PARAMETER Location
			Location, where the subnet is at.
		
		.EXAMPLE
			PS C:\> Register-FMSubnet -SiteName MySite -Name '1.2.3.4/32'

			Assigns the subnet '1.2.3.4/32' to the site 'MySite'
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$SiteName,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidateScript('ForestManagement.Validate.Subnet', ErrorString = 'ForestManagement.Validate.Subnet.Failed')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string]
		$Location
	)
	
	process
	{
		$hashtable = @{
			PSTypeName = 'ForestManagement.Subnet.Configuration'
			SiteName = $SiteName
			Name = $Name
			Description = $Description
			Location = $Location
		}

		$script:subnets[$Name] = [PSCustomObject]$hashtable
	}
}
