<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'ForestManagement' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'ForestManagement' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'ForestManagement' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

# Sitelinks
Set-PSFConfig -Module 'ForestManagement' -Name 'SiteLink.MultilateralLinks' -Value $false -Initialize -Validation 'bool' -Description 'Whether sitelinks should be allowed to contain more than two sites. Enabling this will suppress all error messages when finding those.'

# Schema
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.AutoCreate.TempAdmin' -Value $false -Initialize -Validation 'bool' -Description 'Schema Updates require special privileges not usually granted. Enabling this setting will have the task automatically create a temporary schema admin account with the permissions to execute the planned updates.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.Credential' -Value $null -Initialize -Validation credential -Description 'Credentials to use for performing schema updates'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.Name' -Value '' -Initialize -Validation string -Description 'The name of the account to use'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoDescription' -Value '' -Initialize -Validation string -Description 'The description for the account used. If specified, this is what the description will be updated to after successfully using the account.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoCreate' -Value $false -Initialize -Validation bool -Description 'Whether the account should be created automatically if it isn''t present'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoEnable' -Value $false -Initialize -Validation bool -Description 'Whether the account to use for performing the schema update should be enabled for use if disabled.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoDisable' -Value $false -Initialize -Validation bool -Description 'Whether the account to use for performing the schema update should be disabled after use.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoGrant' -Value $false -Initialize -Validation bool -Description 'Whether the account to use for performing the schema update should be added to the schema admins group before use.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Account.AutoRevoke' -Value $false -Initialize -Validation bool -Description 'Whether the account to use for performing the schema update should be removed from the schema admins group after use.'
Set-PSFConfig -Module 'ForestManagement' -Name 'Schema.Password.AutoReset' -Value $false -Initialize -Validation bool -Description 'Whether the password of the used account should be reset before & after use.'
