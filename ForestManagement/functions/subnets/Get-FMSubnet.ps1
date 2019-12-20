function Get-FMSubnet
{
<#
	.SYNOPSIS
		Returns the list of configured subnets.

	.DESCRIPTION
		Returns the list of configured subnets.
		Subnets can be configured using Register-FMSubnet.
		Those configurations represent the "Should be" state as defined for the entire organization.

	.PARAMETER Name
		Name of the subnet to filter by.
		Defaults to "*"

	.EXAMPLE
		PS C:\> Get-FMSubnet

		Returns all configured subnets.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = "*"
	)

	process
	{
		($script:subnets.Values | Where-Object Name -like $Name)
	}
}