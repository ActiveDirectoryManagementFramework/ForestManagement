function Unregister-FMExchangeSchema
{
<#
	.SYNOPSIS
		Clears the defined exchange forest configuration from the loaded configuration set.
	
	.DESCRIPTION
		Clears the defined exchange forest configuration from the loaded configuration set.
	
	.EXAMPLE
		PS C:\> Unregister-FMExchangeSchema
	
		Clears the defined exchange forest configuration from the loaded configuration set.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		$script:exchangeschema = $null
	}
}
