function Register-FMSchema {
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

	.PARAMETER Name
		The name of the attribute.
		Defaults to the AdminDisplayName if not specified.
	
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

	.PARAMETER IsDefunct
		Flag this attribute as defunct.
		It will be marked as such in AD, be delisted from the Global Catalog and removed from all its supposed memberships.

	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\schema.json | ConvertFrom-Json | Write-Output | Register-FMSchema

		Registers all extension attributes in the json file as schema settings to apply when running Invoke-FMSchema.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
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

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
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
		$AdvancedView,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[bool]
		$IsDefunct,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		$nameResult = $Name
		if (-not $Name) { $nameResult = $AdminDisplayName }

		$script:schema[$OID] = [PSCustomObject]@{
			PSTypeName          = 'ForestManagement.Schema.Configuration'
			ObjectClass         = $ObjectClass
			OID                 = $OID
			AdminDisplayName    = $AdminDisplayName
			LdapDisplayName     = $LdapDisplayName
			Name                = $nameResult
			OMSyntax            = $OMSyntax
			AttributeSyntax     = $AttributeSyntax
			SingleValued        = $SingleValued
			AdminDescription    = $AdminDescription
			SearchFlags         = $SearchFlags
			PartialAttributeSet = $PartialAttributeSet
			AdvancedView        = $AdvancedView
			IsDefunct           = $IsDefunct
			ContextName         = $ContextName
		}
	}
}
