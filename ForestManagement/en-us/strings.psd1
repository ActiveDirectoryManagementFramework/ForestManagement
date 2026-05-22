# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Assert-ADConnection.Failed'                                  = 'Failed to connect to {0}' # $Server
	
	'Assert-Configuration.NotConfigured'                          = 'No configuration found for {0}' # $Type
	
	'General.Invalid.Input'                                       = 'Invalid input: {1}! This command only accepts output objects from {0}' # 'Test-FMSchemaDefaultPermission', $testItem
	
	'Get-SchemaAdminCredential.Account.Assignment.Failure'        = 'Failed to add temporary schema admin account {0} to group schema admins!' # $newName
	'Get-SchemaAdminCredential.Account.Creation'                  = 'Creating admin account for schema administration' # 
	'Get-SchemaAdminCredential.Account.Disabled'                  = 'Account for schema administration: {0} is disabled! Enable it or set the "ForestManagement.Schema.Account.AutoEnable" setting' # $accountName
	'Get-SchemaAdminCredential.Account.Enable'                    = 'Enabling account for schema administration' # 
	'Get-SchemaAdminCredential.Account.ExistsNot'                 = 'Unable to find schema operations account {0}. Either create it or enable the "ForestManagement.Schema.Account.AutoCreate" configuration setting' # $accountName
	'Get-SchemaAdminCredential.Account.Group.Assignment'          = 'Assigning to schema admin group' # 
	'Get-SchemaAdminCredential.Account.GroupAssignment.Failure'   = 'Failed to assign {0} to the schema admins group.' # $accountName
	'Get-SchemaAdminCredential.Account.Unprivileged'              = 'The account: {0} was selected for schema administration. However it does not have the required permissions to do so and the automatic assignments of needed privileges has not been enabled.' # $accountName
	'Get-SchemaAdminCredential.Password.InteractiveRead.Failed'   = 'Failed to interactively read the password for the account for schema administration: {0}' # $accountName
	'Get-SchemaAdminCredential.Password.Reset'                    = 'Resetting the password for schema administration account {0}' # $accountName
	'Get-SchemaAdminCredential.Password.Reset.Failed'             = 'Failed to reset the password for schema administration account {0}' # $accountName
	
	'Invoke-Callback.Invoking'                                    = 'Executing callback: {0}' # $callback.Name
	'Invoke-Callback.Invoking.Failed'                             = 'Error executing callback: {0}' # $callback.Name
	'Invoke-Callback.Invoking.Success'                            = 'Successfully executed callback: {0}' # $callback.Name
	
	'Invoke-FMAccessRule.Access.Failed'                           = 'Failed to access ACL on {0}' # $testItem.Identity
	'Invoke-FMAccessRule.AccessRule.Create'                       = 'Adding access rule for {0}, granting {1} ({2})' # $changeEntry.Configuration.IdentityReference, $changeEntry.Configuration.ActiveDirectoryRights, $changeEntry.Configuration.AccessControlType
	'Invoke-FMAccessRule.AccessRule.Creation.Failed'              = 'Failed to create accessrule at {0} for {1}' # $testItem.Identity, $changeEntry.Configuration.IdentityReference
	'Invoke-FMAccessRule.AccessRule.Remove'                       = 'Removing access rule for {0}, granting {1} ({2}) from {3}' # $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType, $changeEntry.DistinguishedName
	'Invoke-FMAccessRule.AccessRule.Remove.Error.Consistency'     = 'Failed to remove access rule from {0}! This may be due to a consistency error. Investigate the object, it may be resolvable via the dsa GUI in the security tab' # $testItem.Identity
	'Invoke-FMAccessRule.AccessRule.Remove.Failed'                = 'Failed to removing access rule for {0}, granting {1} ({2}) from {3} for unknown reasons (sorry). If this persists, consider enabling the alternative deletion mode through the "Domainmanagement.AccessRules.Remove.Option2" configuration setting.' # $changeEntry.ADObject.IdentityReference, $changeEntry.ADObject.ActiveDirectoryRights, $changeEntry.ADObject.AccessControlType, $changeEntry.DistinguishedName
	'Invoke-FMAccessRule.AccessRule.Restore'                      = 'Restoring access rule from schema default for {0}, granting {1} ({2})' # $changeEntry.Configuration.IdentityReference, $changeEntry.Configuration.ActiveDirectoryRights, $changeEntry.Configuration.AccessControlType
	'Invoke-FMAccessRule.ADObject.Missing'                        = 'Cannot process access rules, due to missing AD object: {0}. Please ensure the domain object is created before trying to apply rules to it!' # $testItem.Identity
	'Invoke-FMAccessRule.Processing.Execute'                      = 'Applying {0} out of {1} intended access rule changes' # ($testItem.Changed.Count - $failedCount), $testItem.Changed.Count
	'Invoke-FMAccessRule.Processing.Rules'                        = 'Processing {1} access rule changes on {0}' # $testItem.Identity, $testItem.Changed.Count

	'Invoke-FMCertificate.Add'                                    = 'Adding {1} certificate: {0}' # $testResult.Configuration.Certificate.Subject, $testResult.Configuration.Type
	'Invoke-FMCertificate.Invalid.Input'                          = 'Invalid input - not a valid testresult object returned by Test-FMCertificate: {0}' # $testResult
	'Invoke-FMCertificate.Remove'                                 = 'Removing certificate {0} from {1}' # $testResult.ADObject.Subject, $testResult.ADObject.ADObject
	'Invoke-FMCertificate.WinRM.Failed'                           = 'Failed to connect to {0} via WinRM' # $computerName
	
	'Invoke-FMExchangeSchema.Installing'                          = 'Installing Exchange Forest settings for {0}' # $testItem.Configuration
	'Invoke-FMExchangeSchema.IsoPath.Missing'                     = 'Cannot find the specified exchange ISO file on the target computer: {0}' # $testItem.Configuration.LocalImagePath
	'Invoke-FMExchangeSchema.Updating'                            = 'Updating Exchange Forest settings from {0} to {1}' # $testItem.ADObject, $testItem.Configuration
	'Invoke-FMExchangeSchema.WinRM.Failed'                        = 'Failed to connect to "{0}" via WinRM/PowerShell Remoting.' # $computerName
	'Invoke-FMExchangeSchema.DisablingSplitPermissions'           = 'Disabling split permissions for {0}' # $testItem.Configuration
	'Invoke-FMExchangeSchema.EnablingSplitPermissions'            = 'Enabling split permissions for {0}' # $testItem.Configuration
	'Invoke-FMExchangeSchema.SchemaMaster.WrongSite'              = 'Error applying Exchange Schema update: Target server {0} must be in the same site as the Schema Master {1}' # $parameters.Server, $forest.SchemaMaster
	
	'Invoke-FMForestLevel.Raise.Level'                            = 'Raising forest level to {0}' # $testItem.Configuration.Level
	
	'Invoke-FMNTAuthStore.Add'                                    = 'Adding certificate to the NTAuthStore: {0}' # $testResult.Configuration.Subject
	'Invoke-FMNTAuthStore.Invalid.Input'                          = 'Invalid input - not a valid testresult object returned by Test-FMNTAuthStore: {0}' # $testResult
	'Invoke-FMNTAuthStore.Remove'                                 = 'Removing certificate from the NTAuthStore: {0}' # $testResult.ADObject.Subject
	'Invoke-FMNTAuthStore.WinRM.Failed'                           = 'Failed to connect to {0} via WinRM' # $computerName
	
	'Invoke-FMSchema.Assigning.Attribute.ToObjectClass'           = 'Assigning attribute {1} to object class {0}' # $class, $testItem.Identity
	'Invoke-FMSchema.Connect.Failed'                              = 'Failed to connect to {0}' # $Server
	'Invoke-FMSchema.Creating.Attribute'                          = 'Creating a new schema attribute' # 
	'Invoke-FMSchema.Credentials.Test'                            = 'Testing ADWS connectivity to the Schema Master' # 
	'Invoke-FMSchema.Decommission.Attribute'                      = 'Deprecating attribute {0} with ID {1}' # $testItem.ADObject.LdapDisplayName, $testItem.ADObject.AttributeID
	'Invoke-FMSchema.Decommission.MayContain'                     = 'Removing attribute {0} from class''s {1} MayContain attribute' # $testItem.ADObject.LdapDisplayName, $adObject.LdapDisplayName
	'Invoke-FMSchema.Decommission.MustContain'                    = 'Removing attribute {0} from class''s {1} MustContain attribute' # $testItem.ADObject.LdapDisplayName, $adObject.LdapDisplayName
	'Invoke-FMSchema.Reading.ObjectClass.Failed'                  = 'Error searching for object class {0}' # $class
	'Invoke-FMSchema.Reading.ObjectClass.NotFound'                = 'Failed to find object class {0}' # $class
	'Invoke-FMSchema.Removing.Attribute.FromObjectClass'          = 'Removing attribute {1} from object class: {0}' # $class, $testItem.Identity
	'Invoke-FMSchema.Rename.Attribute'                            = 'Renaming attribute {0} to {1}' # $testItem.ADObject.cn, $testItem.Configuration.Name
	'Invoke-FMSchema.Schema.Credentials'                          = 'Resolving credentials for schema administration' # 
	'Invoke-FMSchema.Schema.Credentials.Release'                  = 'Releasing/Postprocessing credentials used for schema administration' # 
	'Invoke-FMSchema.Updating.Attribute'                          = 'Updating the attribute, modifying {0}' # ($resolvedAttributes.Keys -join ', ')
	
	'Invoke-FMSchemaDefaultPermission.AccessRule.Add'             = 'Adding permissions to {0} : Granting {1} ({2})' # $change.Identity, $change.Privilege, $change.Access
	'Invoke-FMSchemaDefaultPermission.AccessRule.Remove'          = 'Removing permissions to {0} : Revoking {1} ({2})' # $change.Identity, $change.Privilege, $change.Access
	'Invoke-FMSchemaDefaultPermission.Connect.Failed'             = 'Failed to connect to {0} via ADWS' # $Server
	'Invoke-FMSchemaDefaultPermission.Credentials.Test'           = 'Testing Schema-Update credentials' # 
	'Invoke-FMSchemaDefaultPermission.IdentityError'              = 'Skipping processing {0} - error resolving identity' # $testItem.Identity
	'Invoke-FMSchemaDefaultPermission.NotFound'                   = 'Skipping processing {0} - object class does not exist' # $testItem.Identity
	'Invoke-FMSchemaDefaultPermission.Permissions.Update'         = 'Updating {2}, processing {0} out of {1} changes' # $tracking.Count, $testItem.Changed.Count, $testItem.Identity
	'Invoke-FMSchemaDefaultPermission.Schema.Credentials'         = 'Resolving schema admin credentials' # 
	'Invoke-FMSchemaDefaultPermission.Schema.Credentials.Release' = 'Releasing schema admin credentials' # 
	'Invoke-FMSchemaDefaultPermission.WinRM.Connect'              = 'Connecting via WinRM' # 
	
	'Invoke-FMSchemaLdif.Connect.Failed'                          = 'Failed to connect to {0}' # $Server
	'Invoke-FMSchemaLdif.Invoke.File'                             = 'Loading LDIF file schema extension: {0}' # $testItem.Identity
	'Invoke-FMSchemaLdif.Schema.Credentials'                      = 'Resolving credentials for schema administration' # 
	'Invoke-FMSchemaLdif.Schema.Credentials.Release'              = 'Releasing/Postprocessing credentials used for schema administration' # 
	
	'Invoke-FMServer.Server.FailedToResolve'                      = 'Failed to resolve IP Address for domain controller {0}. Ensure the network and DNS are properly configured.' # $testItem.Identity
	'Invoke-FMServer.Server.Moving'                               = 'Moving domain controller to site {0}' # $testItem.SupposedSite
	'Invoke-FMServer.Server.NoSubnet'                             = 'Unable to find a suitable subnet for domain controller {0} with IP {1}.' # $testItem.Identity, $testItem.ADObject.IPAddress
	'Invoke-FMServer.Server.NotFound'                             = 'Failed to find DNSHostName of {0}. Ensure the domain controller exists and is properly configured!' # $testItem.Identity
	
	'Invoke-FMSite.Creating.Site'                                 = 'Creating a new site' # 
	'Invoke-FMSite.Removing.Site'                                 = 'Removing Site' # 
	'Invoke-FMSite.Removing.Site.ChildServers'                    = 'Failed to remove site: Still has child servers assigned to it: {0}' # ($servers.Name -join ", ")
	'Invoke-FMSite.Renaming.Site'                                 = 'Renaming site to {0}' # $testItem.NewName
	'Invoke-FMSite.Updating.Site'                                 = 'Updating {0} on an existing site' # ($testItem.Changed -join ", ")
	
	'Invoke-FMSiteLink.Creating.SiteLink'                         = 'Creating a new Sitelink' # 
	'Invoke-FMSiteLink.Removing.SiteLink'                         = 'Removing Sitelink' # 
	'Invoke-FMSiteLink.Renaming.SiteLink'                         = 'Renaming sitelink to {0}' # $testItem.IdealName
	'Invoke-FMSiteLink.Updating.SiteLink'                         = 'Updating {0} on an existing sitelink' # ($testItem.Changed -join ", ")
	
	'Invoke-FMSubnet.Creating.Subnet'                             = 'Creating a new Subnet' # 
	'Invoke-FMSubnet.Deleting.Subnet'                             = 'Removing Subnet' # 
	'Invoke-FMSubnet.Updating.Subnet'                             = 'Updating {0} on an existing Subnet' # ($testItem.Changed -join ", ")
	
	'Invoke-LdifFile.Invoking.File'                               = 'Loading the LDIF file: {0}' # $Path
	
	'Remove-SchemaAdminCredential.Account.AutoDescription'        = 'Updating description for schema admin user account' # 
	'Remove-SchemaAdminCredential.Account.Group.Revoke'           = 'Revoking schema admin group membership for administrative account' # 
	'Remove-SchemaAdminCredential.SchemaAccount.Disable'          = 'Disabling account object for schema admin user {0}' # 
	'Remove-SchemaAdminCredential.SchemaAccount.PasswordReset'    = 'Resetting the password for schema admin user {0}' # 
	'Remove-SchemaAdminCredential.SchemaAccount.Resolve'          = 'Resolving account object for schema admin user {0}' # $userName
	'Remove-SchemaAdminCredential.SchemaAccount.Resolve.Failed'   = 'Failed to resolve account object for schema admin user {0}' # $userName
	'Remove-SchemaAdminCredential.TemporaryAccount.Remove'        = 'Removing temporary schema admin account {0}' # $script:temporarySchemaUpdateUser.Name
	'Remove-SchemaAdminCredential.TemporaryAccount.Remove.Failed' = 'Failed to remove temporary schema admin account {0}' # $script:temporarySchemaUpdateUser.Name
	
	'Resolve-ContentSearchBase.Exclude.NotFound'                  = 'Failed to find excluded ou/container: {0}' # $item.Name
	'Resolve-ContentSearchBase.Include.NotFound'                  = 'Failed to find included ou/container: {0}' # $item.Name
	'Resolve-ContentSearchBase.Searchbase.Found'                  = 'Resolved searchbase in {2}: {0} | {1}' # $searchBase.SearchScope, $searchBase.SearchBase, $script:domainContext.Fqdn
	
	'Resolve-SchemaAttribute.Update.SystemOnlyError'              = 'Cannot update {0} to {1} on {2}. The attribute property is system protected and can only ever be defined when creating a new attribute! This cannot be undone and only replacing the attribute with a new attribute will allow you to resolve the issue.' # $attributeName, $attributes.$attributeName, $ADObject
	
	'Set-FMContentMode.Error.UnknownExcludedComponent'            = 'Error excluding a Component from the Forest Content Mode. Unexpected Component: {0}. Ensure the Component specified not only exists, but also supports being excluded from Forest Content Mode.' # $pair.Key

	'Test-FMAccessRule.DefaultPermission.Failed'                  = 'Failed to retrieve default permissions from Schema when connecting to {0}' # $Server
	'Test-FMAccessRule.NoAccess'                                  = 'Failed to access {0}' # $resolvedPath
	'Test-FMAccessRule.Parallel.Error'                            = 'Failed to process {0}' # $fail.ADObject
	
	'Test-FMSchema.Connect.Failed'                                = 'Failed to connect to {0}' # $Server
	
	'Test-FMSchemaDefaultPermission.Class.IdentityUncertain'      = 'Unable to resolve all identities for the default permissions to apply to {0}. This objectclass will be skipped instead.' # $Configuration[0].ClassName
	'Test-FMSchemaDefaultPermission.Class.NotFound'               = 'Unable to find object class {0}. Make sure the configuration does not contain a typo and that all schema updates have been applied.' # $className
	'Test-FMSchemaDefaultPermission.Connect.Failed'               = 'Unable to connect to {0} via ADWS.' # $Server
	'Test-FMSchemaDefaultPermission.Principal.ResolutionError'    = 'Unable to resolve {0}! Value after string resolution: {1}' # $AccessRule.Identity, $basicHash.ResolvedIdentity
	'Test-FMSchemaDefaultPermission.WinRM.Connect'                = 'Unable to connect via WinRM' # 
	
	'Test-FMSchemaLdif.Connect.Failed'                            = 'Failed to connect to {0}' # $Server
	'Test-FMSchemaLdif.Missing.SchemaItem'                        = 'Defining changes for {0} when object has not been defined and does not exist!' # $attributeName
	
	'Test-FMServer.SiteConflict'                                  = 'Found a site conflict on DC {0} : Is in site {2} and could also be in {1} ({3})' # $domainController.Name, $foundSubnet.SiteName, $domainController.SiteName, $foundSubnet.Name
	
	'Test-FMSiteLink.Critical.TooManySites'                       = 'Critical issue when scanning sitelinks: The following link contains more than two sites ({1}): "{0}". This is not a technical error, but violates configuration policies. Manually update this sitelink-settings in AD to resolve the issue.' # $siteLink.DistinguishedName, $siteLink.siteList.Count
	'Test-FMSiteLink.Information.MultipleSites'                   = 'Sitelink with {1} sites found. This is not a problem, but not supported by this tool, sitelink will be ignored: {1}' # $siteLink.DistinguishedName, $siteLink.siteList.Count
	
	'Validate.Path.SingleFile.Failed'                             = 'Input does not point at a single, existing file: {0} | Make sure the path notation is correct, relative paths are supported.' # <user input>, <validation item>
	'Validate.Subnet.Failed'                                      = 'Input is not a legal subnet: {0} | Please offer an IPv4/Subnetsize notation subnet. E.g.: "1.2.3.4/24"' # <user input>, <validation item>
}