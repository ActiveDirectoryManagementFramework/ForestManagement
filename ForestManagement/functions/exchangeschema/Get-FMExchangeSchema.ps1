function Get-FMExchangeSchema
{
<#
	.SYNOPSIS
		Returns the defined Exchange Forest configuration to apply.
	
	.DESCRIPTION
		Returns the defined Exchange Forest configuration to apply.
	
	.EXAMPLE
		PS C:\> Get-FMExchangeSchema
	
		Returns the defined Exchange Forest configuration to apply.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:exchangeschema
	}
}
