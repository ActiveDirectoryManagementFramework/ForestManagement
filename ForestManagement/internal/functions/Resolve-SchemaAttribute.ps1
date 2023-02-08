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
	
	.PARAMETER Changes
		Changes to be applied to an existing attribute.

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
		
		$ADObject,

		$Changes
	)

	begin {
		function Convert-AttributeName {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[AllowNull()]
				[string[]]
				$Name
			)

			process {
				foreach ($entry in $Name) {
					if ($null -eq $entry) { continue }

					switch ($entry) {
						SingleValued { 'isSingleValued' }
						OID { 'attributeID' }
						PartialAttributeSet { 'isMemberOfPartialAttributeSet' }
						AdvancedView { 'showInAdvancedViewOnly' }
						default { $_ }
					}
				}
			}
		}
	}
	
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

		#region Case: Update Settings
		$updates = @{ }
		foreach ($change in $Changes) {
			$updates[($change.Property | Convert-AttributeName)] = $change.New
		}
		
		$systemOnly = @(
			'isSingleValued'
			'oMSyntax'
			'attributeId'
			'attributeSyntax'
		)

		foreach ($attributeName in ($updates.Keys | Write-Output)) {
			
			if ($systemOnly -contains $attributeName) {
				Write-PSFMessage -Level Warning -String 'Resolve-SchemaAttribute.Update.SystemOnlyError' -StringValues $attributeName, $attributes.$attributeName, $ADObject
				$attributes.Remove($attributeName)
			}
		}
		#endregion Case: Update Settings
		
		$attributes
	}
}