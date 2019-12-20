function Register-FMSchema
{
<#
	.SYNOPSIS
		Registers a schema extension attribute.
	
	.DESCRIPTION
		Registers a schema extension attribute.
		These registered attributes will be applied / updated as needed when running Invoke-FMSchema.
		Use Test-FMSchema to verify, whether a forest is properly configured.
	
	.PARAMETER ObjectClass
		The class to assign the new attribute to.
	
	.PARAMETER OID
		The unique OID of the attribute.
	
	.PARAMETER AdminDisplayName
		The displayname of the attribute as admins see it.
	
	.PARAMETER LdapDisplayName
		The name of the attribute as LDAP sees it.
	
	.PARAMETER OMSyntax
		The OM Syntax of the attribute
	
	.PARAMETER AttributeSyntax
		The syntax rules of the attribute.
	
	.PARAMETER SingleValued
		Whether the attribute is singlevalued.
	
	.PARAMETER AdminDescription
		The human friendly description of the attribute.
	
	.PARAMETER SearchFlags
		The search flags for the attribute.
	
	.PARAMETER PartialAttributeSet
		Whether the attribute is part of a partial attribute set.
	
	.PARAMETER AdvancedView
		Whether this attribute is only shown in advanced view.
		Use this to hide it from the default display, used to simplify display by hiding information not needed for regulaar daily tasks.
	
	.EXAMPLE
		PS C:\> Get-Content .\schema.json | ConvertFrom-Json | Write-Output | Register-FMSchema

		Registers all extension attributes in the json file as schema settings to apply when running Invoke-FMSchema.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ObjectClass,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$OID,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$AdminDisplayName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$LdapDisplayName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$OMSyntax,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$AttributeSyntax,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[switch]
		$SingleValued,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$AdminDescription,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[int]
		$SearchFlags,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[bool]
		$PartialAttributeSet,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[bool]
		$AdvancedView
	)
	
	process
	{
		$script:schema[$AdminDisplayName] = [PSCustomObject]@{
			PSTypeName = 'ForestManagement.Schema.Configuration'
			ObjectClass = $ObjectClass
			OID = $OID
			AdminDisplayName = $AdminDisplayName
			LdapDisplayName = $LdapDisplayName
			OMSyntax = $OMSyntax
			AttributeSyntax = $AttributeSyntax
			SingleValued = $SingleValued
			AdminDescription = $AdminDescription
			SearchFlags = $SearchFlags
			PartialAttributeSet = $PartialAttributeSet
			AdvancedView = $AdvancedView
		}
	}
}
