function Register-FMSchemaDefaultPermission
{
<#
	.SYNOPSIS
		Registers a new desired schema default permission access rule.
	
	.DESCRIPTION
		Registers a new desired schema default permission access rule.
		These access rules are then used / applied when when creating a new object of the class affected.
	
		These settings apply only to new objects created of the affected class, not already existing ones.
		Using this you could for example add a group to have full control over all newly created group policy objects.
	
	.PARAMETER ClassName
		The name of the object class in schema this applies to.
	
	.PARAMETER Identity
		The principal to which the access rule applies.
		Supports limited string resolution.
	
	.PARAMETER ActiveDirectoryRights
		The rights granted.
	
	.PARAMETER AccessControlType
		Allow or Deny?
		Defaults to: Allow
	
	.PARAMETER InheritanceType
		How is this privilege inherited by child objects?
	
	.PARAMETER ObjectType
		What object types does this permission apply to?
	
	.PARAMETER InheritedObjectType
		What object types does this permission apply to?
		Used for extended properties.
	
	.PARAMETER Mode
		How access rules are actually applied:
		- Additive: Only add new access rules, but do not touch existing ones
		- Defined: Add new access rules, remove access rules not defined in configuration that apply to a principal that has access rules defined.
		- Constrained: Add new access rules, remove all access rules not defined in configuration
	
		All Modes of all settings for a given class are used when determining the effective Mode applied to that class.
		The most restrictive Mode applies.
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\sdp.json | ConvertFrom-Json | Write-Output | Register-FMSchemaDefaultPermission
	
		Loads all entries from the specified json file and registers them.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ClassName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ActiveDirectoryRights,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[System.Security.AccessControl.AccessControlType]
		$AccessControlType = 'Allow',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[System.DirectoryServices.ActiveDirectorySecurityInheritance]
		$InheritanceType = 'None',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$ObjectType = '<All>',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$InheritedObjectType = '<All>',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Constrained', 'Defined', 'Additive')]
		[string]
		$Mode,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		if (-not $script:schemaDefaultPermissions[$ClassName]) { $script:schemaDefaultPermissions[$ClassName] = @{ } }
		$script:schemaDefaultPermissions[$ClassName]["$($Identity)þ$($ActiveDirectoryRights)þ$($ObjectType)þ$($InheritedObjectType)þ$($InheritanceType)þ$($AccessControlType)"] = [PSCustomObject]@{
			PSTypeName		      = 'ForestManagement.SchemaDefaultPermission.Configuration'
			ClassName			  = $ClassName
			Identity			  = $Identity
			ActiveDirectoryRights = $ActiveDirectoryRights
			AccessControlType	  = $AccessControlType
			InheritanceType	      = $InheritanceType
			ObjectType		      = $ObjectType
			InheritedObjectType   = $InheritedObjectType
			Mode				  = $Mode
			ContextName		      = $ContextName
		}
	}
}