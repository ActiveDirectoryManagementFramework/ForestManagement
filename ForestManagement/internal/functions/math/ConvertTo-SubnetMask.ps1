function ConvertTo-SubnetMask
{
	<#
		.SYNOPSIS
			Converts the size of a mask into the mask as IPAddress
		
		.DESCRIPTION
			Converts the size of a mask into the mask as IPAddress
		
		.PARAMETER MaskSize
			The size of the subnet. Valid between 1 and 32
		
		.EXAMPLE
			PS C:\> ConvertTo-SubnetMask -MaskSize 30

			Converts the size (30) into the mask as IPAddress
	#>
	[OutputType([IPAddress])]
	[CmdletBinding()]
	param (
		[ValidateRange(1, 32)]
		[int]
		$MaskSize
	)
	
	process
	{
		$binaryString = ("1") * $MaskSize + ("0") * (32 - $MaskSize)
		$bytes = foreach ($number in (0 .. 3))
		{
			[convert]::ToByte($binaryString.SubString(($number * 8), 8), 2)
		}
		[IPAddress]::new($bytes)
	}
}
