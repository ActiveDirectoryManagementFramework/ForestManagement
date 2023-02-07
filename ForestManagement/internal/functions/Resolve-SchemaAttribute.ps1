function Resolve-SchemaAttribute {
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
	[OutputType([hashtable])]
	[CmdletBinding()]
	param (
		$Configuration,
		
		$ADObject
	)
	
	process {
		#region Build out basic attribute hashtable
		$attributes = @{
			adminDisplayName              = $Configuration.AdminDisplayName
			lDAPDisplayName               = $Configuration.LdapDisplayName
			attributeId                   = $Configuration.OID
			oMSyntax                      = $Configuration.OMSyntax
			attributeSyntax               = $Configuration.AttributeSyntax
			isSingleValued                = ($Configuration.SingleValued -as [bool])
			adminDescription              = $Configuration.AdminDescription
			searchflags                   = $Configuration.SearchFlags
			isMemberOfPartialAttributeSet = $Configuration.PartialAttributeSet
			showInAdvancedViewOnly        = $Configuration.AdvancedView
		}
		#endregion Build out basic attribute hashtable

		#region Case: New Attribute
		if (-not $ADObject) {
			$badProperties = foreach ($pair in $attributes.GetEnumerator()) {
				if ($null -eq $pair.Value) { $pair.Key }
			}
			if ($null -eq $Configuration.SingleValued) { $badProperties = @($badProperties) + @('SingleValued') }
			if ($badProperties) {
				throw "Cannot create new attribute $($Configuration.AdminDisplayName), missing attributes: $($badProperties -join ',')"
			}

			return $attributes
		}
		#endregion Case: New Attribute

		$properties = $Configuration.PSObject.Properties.Name | Set-String -OldValue '^SingleValued$' -NewValue 'isSingleValued'
		
		#region If ADObject is present: Remove attributes that are already present
		$attributeNames = @(
			'isSingleValued'
			'searchflags'
			'isMemberOfPartialAttributeSet'
			'oMSyntax'
			'attributeId'
			'adminDescription'
			'adminDisplayName'
			'showInAdvancedViewOnly'
			'lDAPDisplayName'
			'attributeSyntax'
		)
		$systemOnly = @(
			'isSingleValued'
			'oMSyntax'
			'attributeId'
			'attributeSyntax'
		)

		foreach ($attributeName in $attributeNames) {
			if ($attributeName -notin $properties) {
				$attributes.Remove($attributeName)
				continue
			}
			if ($ADObject.$attributeName -ceq $attributes[$attributeName]) {
				$attributes.Remove($attributeName)
			}
			if ($attributes.Keys -contains $attributeName -and $systemOnly -contains $attributeName) {
				Write-PSFMessage -Level Warning -String 'Resolve-SchemaAttribute.Update.SystemOnlyError' -StringValues $attributeName, $attributes.$attributeName, $ADObject
				$attributes.Remove($attributeName)
			}
		}
		#endregion If ADObject is present: Remove attributes that are already present
		
		$attributes
	}
}
