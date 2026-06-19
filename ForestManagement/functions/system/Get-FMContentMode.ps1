function Get-FMContentMode {
	<#
	.SYNOPSIS
		Returns the current forest content mode / content handling policy.
	
	.DESCRIPTION
		Returns the current forest content mode / content handling policy.
		For more details on the content mode and how it behaves, see the description on Set-FMContentMode
	
	.EXAMPLE
		PS C:\> Get-FMContentMode

		Returns the current domain content mode / content handling policy.
	#>
	[CmdletBinding()]
	param ()
	
	process {
		$script:contentMode
	}
}
