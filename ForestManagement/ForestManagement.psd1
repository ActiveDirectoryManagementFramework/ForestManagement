@{
	# Script module or binary module file associated with this manifest
	RootModule = 'ForestManagement.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.5.79'
	
	# ID used to uniquely identify this module
	GUID = '7de4379d-17c8-48d3-bd6d-93279aef64bb'
	
	# Author of this module
	Author = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName = 'Microsoft'
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2019 Friedrich Weinmann'
	
	# Description of the functionality provided by this module
	Description = 'Infrastructure module to build and maintain forest configuration'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules   = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.12.346' }
		
		# Additional Dependencies, cannot declare due to bug in dependency handling in PS5.1
		# @{ ModuleName = 'ResolveString'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'Principal'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'ADMF.Core'; ModuleVersion = '1.1.6' }
		# @{ ModuleName = 'DomainManagement'; ModuleVersion = '1.4.84' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\ForestManagement.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\ForestManagement.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\ForestManagement.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Clear-FMConfiguration'
		'Get-FMCallback'
		'Get-FMCertificate'
		'Get-FMExchangeSchema'
		'Get-FMForestLevel'
		'Get-FMNTAuthStore'
		'Get-FMSchema'
		'Get-FMSchemaDefaultPermission'
		'Get-FMSchemaLdif'
		'Get-FMSite'
		'Get-FMSiteLink'
		'Get-FMSubnet'
		'Invoke-FMCertificate'
		'Invoke-FMExchangeSchema'
		'Invoke-FMForestLevel'
		'Invoke-FMNTAuthStore'
		'Invoke-FMSchema'
		'Invoke-FMSchemaDefaultPermission'
		'Invoke-FMSchemaLdif'
		'Invoke-FMServer'
		'Invoke-FMSite'
		'Invoke-FMSiteLink'
		'Invoke-FMSubnet'
		'Register-FMCallback'
		'Register-FMCertificate'
		'Register-FMExchangeSchema'
		'Register-FMForestLevel'
		'Register-FMNTAuthStore'
		'Register-FMSchema'
		'Register-FMSchemaDefaultPermission'
		'Register-FMSchemaLdif'
        'Register-FMServer'
		'Register-FMSite'
		'Register-FMSiteLink'
		'Register-FMSubnet'
		'Test-FMCertificate'
		'Test-FMExchangeSchema'
		'Test-FMForestLevel'
		'Test-FMNTAuthStore'
		'Test-FMSchema'
		'Test-FMSchemaDefaultPermission'
		'Test-FMSchemaLdif'
		'Test-FMServer'
		'Test-FMSite'
		'Test-FMSiteLink'
		'Test-FMSubnet'
		'Unregister-FMCallback'
		'Unregister-FMCertificate'
		'Unregister-FMExchangeSchema'
		'Unregister-FMForestLevel'
		'Unregister-FMNTAuthStore'
		'Unregister-FMSchema'
		'Unregister-FMSchemaDefaultPermission'
		'Unregister-FMSchemaLdif'
		'Unregister-FMSite'
		'Unregister-FMSiteLink'
		'Unregister-FMSubnet'
	)
	
	# Cmdlets to export from this module
	# CmdletsToExport = ''
	
	# Variables to export from this module
	# VariablesToExport = ''
	
	# Aliases to export from this module
	# AliasesToExport = ''
	
	# List of all modules packaged with this module
	# ModuleList = @()
	
	# List of all files packaged with this module
	# FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('activedirectory','forest','admf')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/ActiveDirectoryManagementFramework/ForestManagement/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://admf.one'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/ActiveDirectoryManagementFramework/ForestManagement/blob/master/ForestManagement/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}