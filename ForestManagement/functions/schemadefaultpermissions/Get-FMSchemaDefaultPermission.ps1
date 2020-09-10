function Get-FMSchemaDefaultPermission
{
<#
	.SYNOPSIS
		Returns the list of registered default schema permissions.
	
	.DESCRIPTION
		Returns the list of registered default schema permissions.
	
	.PARAMETER ClassName
		The name of the affected objectclass to filter by.
		Defaults to '*'.
	
	.EXAMPLE
		PS C:\> Get-FMSchemaDefaultPermission
	
		Returns the list of all registered default schema permissions.
#>
	[CmdletBinding()]
	param (
		[string]
		$ClassName = '*'
	)
	
	process
	{
		foreach ($key in $script:schemaDefaultPermissions.Keys)
		{
			if ($key -notlike $ClassName) { continue }
			
			$script:schemaDefaultPermissions[$key].Values
		}
	}
}
