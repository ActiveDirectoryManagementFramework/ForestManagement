function Unregister-FMSchemaDefaultPermission
{
<#
	.SYNOPSIS
		Removes schema default permissions from the list of registered configurationsets.
	
	.DESCRIPTION
		Removes schema default permissions from the list of registered configurationsets.
	
	.PARAMETER ClassName
		The name of the object class in schema this applies to.
	
	.PARAMETER Identity
		The principal to which the access rule applies.
	
	.PARAMETER ActiveDirectoryRights
		The rights granted.
	
	.PARAMETER AccessControlType
		Allow or Deny?
	
	.PARAMETER InheritanceType
		How is this privilege inherited by child objects?
	
	.PARAMETER ObjectType
		What object types does this permission apply to?
	
	.PARAMETER InheritedObjectType
		What object types does this permission apply to?
		Used for extended properties.
	
	.EXAMPLE
		PS C:\> Get-FMSchemaDefaultPermission | Unregister-FMSchemaDefaultPermission
	
		Clear all configured default schema permissions.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ClassName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ActiveDirectoryRights,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[System.Security.AccessControl.AccessControlType]
		$AccessControlType,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[System.DirectoryServices.ActiveDirectorySecurityInheritance]
		$InheritanceType,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ObjectType,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$InheritedObjectType
	)
	
	process
	{
		if (-not $script:schemaDefaultPermissions[$ClassName]) { return }
		$script:schemaDefaultPermissions[$ClassName].Remove("$($Identity)þ$($ActiveDirectoryRights)þ$($ObjectType)þ$($InheritedObjectType)þ$($InheritanceType)þ$($AccessControlType)")
		if ($script:schemaDefaultPermissions[$ClassName].Count -lt 1) { $script:schemaDefaultPermissions.Remove($ClassName) }
	}
}
