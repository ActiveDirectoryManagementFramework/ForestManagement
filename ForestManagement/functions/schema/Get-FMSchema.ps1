function Get-FMSchema
{
	<#
	.SYNOPSIS
		Returns the list of registered Schema Extensions.
	
	.DESCRIPTION
		Returns the list of registered Schema Extensions.
	
	.PARAMETER Name
		Name to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-FMSchema

		Returns a list of all schema extensions
	#>
	
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:schema.Values | Where-Object AdminDisplayName -Like $Name)
	}
}
