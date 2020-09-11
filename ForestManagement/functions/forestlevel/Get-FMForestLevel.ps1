function Get-FMForestLevel
{
<#
	.SYNOPSIS
		Returns the defined desired state if configured.
	
	.DESCRIPTION
		Returns the defined desired state if configured.
	
	.EXAMPLE
		PS C:\> Get-FMForestLevel
	
		Returns the defined desired state if configured.
#>
	[CmdletBinding()]
	Param (
	
	)
	process
	{
		$script:forestLevel
	}
}
