﻿# Directory Certificate Stores
$script:dsCertificates = @{ }
$script:dsCertificatesAuthorative = @{ }

# Exchange Schema Version
$script:exchangeschema = $null

# Forest Level
$script:forestlevel = $null

# NT Auth Store Configuration
$script:ntAuthStoreCertificates = @{ }
$script:ntAuthStoreAuthorative = $false

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