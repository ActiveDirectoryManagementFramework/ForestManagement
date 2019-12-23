﻿# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Assert-ADConnection.Failed' = 'Failed to connect to {0}' # $Server
	
	'Get-SchemaAdminCredential.Account.Assignment.Failure' = 'Failed to add temporary schema admin account {0} to group schema admins!' # $newName
	'Get-SchemaAdminCredential.Account.Creation' = 'Creating admin account for schema administration' # 
	'Get-SchemaAdminCredential.Account.Disabled' = 'Account for schema administration: {0} is disabled! Enable it or set the "ForestManagement.Schema.Account.AutoEnable" setting' # $accountName
	'Get-SchemaAdminCredential.Account.Enable' = 'Enabling account for schema administration' # 
	'Get-SchemaAdminCredential.Account.ExistsNot' = 'Unable to find schema operations account {0}. Either create it or enable the "ForestManagement.Schema.Account.AutoCreate" configuration setting' # $accountName
	'Get-SchemaAdminCredential.Account.Group.Assignment' = 'Assigning to schema admin group' # 
	'Get-SchemaAdminCredential.Account.GroupAssignment.Failure' = 'Failed to assign {0} to the schema admins group.' # $accountName
	'Get-SchemaAdminCredential.Account.Unprivileged' = 'The account: {0} was selected for schema administration. However it does not have the required permissions to do so and the automatic assignments of needed privileges has not been enabled.' # $accountName
	'Get-SchemaAdminCredential.Password.InteractiveRead.Failed' = 'Failed to interactively read the password for the account for schema administration: {0}' # $accountName
	'Get-SchemaAdminCredential.Password.Reset' = 'Resetting the password for schema administration account {0}' # $accountName
	'Get-SchemaAdminCredential.Password.Reset.Failed' = 'Failed to reset the password for schema administration account {0}' # $accountName

	'Invoke-FMSchema.Assigning.Attribute.ToObjectClass' = 'Assigning attribute to object class {0}' # $class
	'Invoke-FMSchema.Connect.Failed' = 'Failed to connect to {0}' # $Server
	'Invoke-FMSchema.Creating.Attribute' = 'Creating a new schema attribute' # 
	'Invoke-FMSchema.Reading.ObjectClass.Failed' = 'Error searching for object class {0}' # $class
	'Invoke-FMSchema.Reading.ObjectClass.NotFound' = 'Failed to find object class {0}' # $class
	'Invoke-FMSchema.Schema.Credentials' = 'Resolving credentials for schema administration' # 
	'Invoke-FMSchema.Schema.Credentials.Release' = 'Releasing/Postprocessing credentials used for schema administration' # 
	'Invoke-FMSchema.Updating.Attribute' = 'Updating the attribute, modifying {0}' # ($resolvedAttributes.Keys -join ', ')

	'Invoke-FMSchemaLdif.Connect.Failed' = 'Failed to connect to {0}' # $Server
	'Invoke-FMSchemaLdif.Invoke.File' = 'Loading LDIF file schema extension: {0}' # $testItem.Identity
	'Invoke-FMSchemaLdif.Schema.Credentials' = 'Resolving credentials for schema administration' # 
	'Invoke-FMSchemaLdif.Schema.Credentials.Release' = 'Releasing/Postprocessing credentials used for schema administration' # 

	'Invoke-FMServer.Server.FailedToResolve' = 'Failed to resolve IP Address for domain controller {0}. Ensure the network and DNS are properly configured.' # $testItem.Identity
	'Invoke-FMServer.Server.Moving' = 'Moving domain controller to site {0}' # $testItem.SupposedSite
	'Invoke-FMServer.Server.NoSubnet' = 'Unable to find a suitable subnet for domain controller {0} with IP {1}.' # $testItem.Identity, $testItem.ADObject.IPAddress
	'Invoke-FMServer.Server.NotFound' = 'Failed to find DNSHostName of {0}. Ensure the domain controller exists and is properly configured!' # $testItem.Identity

	'Invoke-FMSite.Creating.Site' = 'Creating a new site' # 
	'Invoke-FMSite.Removing.Site' = 'Removing Site' # 
	'Invoke-FMSite.Removing.Site.ChildServers' = 'Failed to remove site: Still has child servers assigned to it: {0}' # ($servers.Name -join ", ")
	'Invoke-FMSite.Renaming.Site' = 'Renaming site to {0}' # $testItem.NewName
	'Invoke-FMSite.Updating.Site' = 'Updating {0} on an existing site' # ($testItem.Changed -join ", ")

	'Invoke-FMSiteLink.Creating.SiteLink' = 'Creating a new Sitelink' # 
	'Invoke-FMSiteLink.Removing.SiteLink' = 'Removing Sitelink' # 
	'Invoke-FMSiteLink.Renaming.SiteLink' = 'Renaming sitelink to {0}' # $testItem.IdealName
	'Invoke-FMSiteLink.Updating.SiteLink' = 'Updating {0} on an existing sitelink' # ($testItem.Changed -join ", ")

	'Invoke-FMSubnet.Creating.Subnet' = 'Creating a new Subnet' # 
	'Invoke-FMSubnet.Deleting.Subnet' = 'Removing Subnet' # 
	'Invoke-FMSubnet.Updating.Subnet' = 'Updating {0} on an existing Subnet' # ($testItem.Changed -join ", ")

	'Invoke-LdifFile.Invoking.File' = 'Loading the LDIF file: {0}' # $Path

	'Remove-SchemaAdminCredential.Account.AutoDescription' = 'Updating description for schema admin user account' # 
	'Remove-SchemaAdminCredential.Account.Group.Revoke' = 'Revoking schema admin group membership for administrative account' # 
	'Remove-SchemaAdminCredential.SchemaAccount.Disable' = 'Disabling account object for schema admin user {0}' # 
	'Remove-SchemaAdminCredential.SchemaAccount.PasswordReset' = 'Resetting the password for schema admin user {0}' # 
	'Remove-SchemaAdminCredential.SchemaAccount.Resolve' = 'Resolving account object for schema admin user {0}' # $userName
	'Remove-SchemaAdminCredential.SchemaAccount.Resolve.Failed' = 'Failed to resolve account object for schema admin user {0}' # $userName
	'Remove-SchemaAdminCredential.TemporaryAccount.Remove' = 'Removing temporary schema admin account {0}' # $script:temporarySchemaUpdateUser.Name
	'Remove-SchemaAdminCredential.TemporaryAccount.Remove.Failed' = 'Failed to remove temporary schema admin account {0}' # $script:temporarySchemaUpdateUser.Name

	'Test-FMSchema.Connect.Failed' = 'Failed to connect to {0}' # $Server
	'Test-FMSchema.ReadOnly.Delta' = 'There is a discrepancy in the Read-Only property {0}: Found {1} when it should be {2}' # 'LdapDisplayName', $schemaObject.lDAPDisplayName, $schemaSetting.LdapDisplayName
	'Test-FMSchemaLdif.Connect.Failed' = 'Failed to connect to {0}' # $Server
	'Test-FMServer.SiteConflict' = 'Found a site conflict on DC {0} : Is in site {2} and could also be in {1} ({3})' # $domainController.Name, $foundSubnet.SiteName, $domainController.SiteName, $foundSubnet.Name

	'Test-FMSiteLink.Critical.TooManySites' = 'Critical issue when scanning sitelinks: The following link contains more than two sites ({1}): "{0}". This is not a technical error, but violates configuration policies. Manually update this sitelink-settings in AD to resolve the issue.' # $siteLink.DistinguishedName, $siteLink.siteList.Count
	'Test-FMSiteLink.Information.MultipleSites' = 'Sitelink with {1} sites found. This is not a problem, but not supported by this tool, sitelink will be ignored: {1}' # $siteLink.DistinguishedName, $siteLink.siteList.Count

	'Validate.Path.SingleFile.Failed' = 'Input does not point at a single, existing file: {0} | Make sure the path notation is correct, relative paths are supported.' # <user input>
	'Validate.Subnet.Failed' = 'Input is not a legal subnet: {0} | Please offer an IPv4/Subnetsize notation subnet. E.g.: "1.2.3.4/24"' # <user input>
}