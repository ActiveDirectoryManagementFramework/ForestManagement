function Unregister-FMForestLevel
{
<#
	.SYNOPSIS
		Removes the domain level configuration if present.
	
	.DESCRIPTION
		Removes the domain level configuration if present.
	
	.EXAMPLE
		PS C:\> Unregister-FMForestLevel
	
		Removes the domain level configuration if present.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:forestlevel = $null
	}
}
