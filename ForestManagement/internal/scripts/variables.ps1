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