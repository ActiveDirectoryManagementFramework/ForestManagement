function Resolve-SchemaAttribute
{
	<#
	.SYNOPSIS
		Combines configuration and adobject into an attributes hashtable.
	
	.DESCRIPTION
		Combines configuration and adobject into an attributes hashtable.
		This is a helper function that allows to simplify the code used to create and update schema attributes.
	
	.PARAMETER Configuration
		The configuration object containing the desired schema attribute name.
	
	.PARAMETER ADObject
		The ADObject - if present - containing the current schema attribute configuration.
		Specifying this will cause it to return a delta hashtable useful for updating attributes.
	
	.EXAMPLE
		PS C:\> Resolve-SchemaAttribute -Configuration $testItem.Configuration

		Returns the attributes hashtable for a new schema attribute.
		
	.EXAMPLE
		PS C:\> Resolve-SchemaAttribute -Configuration $testItem.Configuration -ADObject $testItem.ADObject

		Returns the attributes hashtable for attributes to update.
	#>
	[CmdletBinding()]
	Param (
		$Configuration,

		$ADObject
	)
	
	process
	{
		#region Build out basic attribute hashtable
		$attributes = @{
			adminDisplayName = $Configuration.AdminDisplayName
			lDAPDisplayName  = $Configuration.LdapDisplayName
			attributeId	     = $Configuration.OID
			oMSyntax		 = $Configuration.OMSyntax
			attributeSyntax  = $Configuration.AttributeSyntax
			isSingleValued   = ($Configuration.SingleValued -as [bool])
			adminDescription = $Configuration.AdminDescription
			searchflags	     = $Configuration.SearchFlags
			isMemberOfPartialAttributeSet = $Configuration.PartialAttributeSet
			showInAdvancedViewOnly = $Configuration.AdvancedView
		}
		#endregion Build out basic attribute hashtable

		#region If ADObject is present: Remove attributes that are already present
		$attributeNames = 'isSingleValued', 'searchflags', 'isMemberOfPartialAttributeSet', 'oMSyntax', 'attributeId', 'adminDescription', 'adminDisplayName', 'showInAdvancedViewOnly', 'lDAPDisplayName', 'attributeSyntax'

		if ($ADObject) {
			foreach ($attributeName in $attributeNames) {
				if ($ADobject.$attributeName -eq $attributes[$attributeName]) {
					$attributes.Remove($attributeName)
				}
			}
		}
		#endregion If ADObject is present: Remove attributes that are already present
		
		$attributes
	}
}
