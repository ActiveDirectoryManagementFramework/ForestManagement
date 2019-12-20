function Get-FMSchemaLdif
{
	<#
	.SYNOPSIS
		Returns the registered schema ldif files.
	
	.DESCRIPTION
		Returns the registered schema ldif files.
	
	.PARAMETER Name
		The name to filter byy.
	
	.EXAMPLE
		PS C:\> Get-FMSchemaLdif

		List all registered ldif files.
	#>
	
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		($script:schemaLdif.Values | Where-Object Name -Like $Name)
	}
}
