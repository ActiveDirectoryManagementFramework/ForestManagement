function Test-Subnet
{
	<#
	.SYNOPSIS
		Tests whether a host fits into the specified subnet.
	
	.DESCRIPTION
		Tests whether a host fits into the specified subnet.
	
	.PARAMETER NetworkAddress
		The address of the subnet.
	
	.PARAMETER MaskAddress
		The subnet mask of the subnet.
	
	.PARAMETER MaskSize
		The size of the mask of the subnet.
	
	.PARAMETER HostAddress
		The address of the host to test
	
	.EXAMPLE
		PS C:\> Test-Subnet -NetworkAddress '192.168.2.0' -MaskSize 24 -HostAddress '192.168.20.255'

		Checks whether the address '192.168.20.255' is part of the subnet '192.168.2.0/24'
	#>
	
	[CmdletBinding()]
	Param (
		[IPAddress]
		$NetworkAddress,

		[IPAddress]
		$MaskAddress,

		[int]
		$MaskSize,

		[IPAddress]
		$HostAddress
	)
	
	process
	{
		if ($MaskSize) {
			$MaskAddress = ConvertTo-SubnetMask -MaskSize $MaskSize
		}
		$NetworkAddress.Address -eq ($MaskAddress.Address -band $HostAddress.Address)
	}
}
