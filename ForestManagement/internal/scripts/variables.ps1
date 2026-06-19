# Configured ACLs
$script:acls = @{ }
$script:aclByCategory = @{ }
$script:aclDefaultOwner = $null

# Configured Access Rules - Based on OU / Path
$script:accessRules = @{ }

# Configured Access Rules - Based on Object Category
$script:accessCategoryRules = @{ }

# Directory Certificate Stores
$script:dsCertificates = @{ }
$script:dsCertificatesAuthorative = @{ }

# Exchange Schema Version
$script:exchangeschema = $null

# Forest Level
$script:forestlevel = $null

# NT Auth Store Configuration
$script:ntAuthStoreCertificates = @{ }
$script:ntAuthStoreAuthorative = $false

# Server Auto Assignment - whether domain controllers will be automatically moved to valid sites without any configuration needed
$script:serverAutoAssignment = $true

# Site Configurations
$script:sites = @{ }

# Subnet Configurations
$script:subnets = @{ }

# Sitelink Configurations
$script:sitelinks = @{ }

# Schema Definition
$script:schema = @{ }

# Schema Default Permission
$script:schemaDefaultPermissions = @{ }

# Schema Definitions for external LDIF files
$script:schemaLdif = @{ }

#----------------------------------------------------------------------------#
#                                Context Data                                #
#----------------------------------------------------------------------------#

# Content Mode
$script:contentMode = [PSCustomObject]@{
	PSTypeName        = 'ForestManagement.Content.Mode'
	Mode              = 'Additive'
	Include           = @()
	Exclude           = @()

	# Note: Also update the help on Set-FMContentMode and on the website Content Mode documentation, when adding new entries here.
	ExcludeComponents = @{
		AccessRules = $false
	}
}
$script:contentSearchBases = [PSCustomObject]@{
	Include = @()
	Exclude = @()
	Bases   = @()
	Server  = ''
}