<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name ForestManagement.alcohol
#>

Register-PSFTeppArgumentCompleter -Command Get-FMSite -Parameter Name -Name 'ForestManagement.Sites'
Register-PSFTeppArgumentCompleter -Command Register-FMSite -Parameter Name -Name 'ForestManagement.Sites'
Register-PSFTeppArgumentCompleter -Command Unregister-FMSite -Parameter Name -Name 'ForestManagement.Sites'

Register-PSFTeppArgumentCompleter -Command Get-FMSubnet -Parameter SiteName -Name 'ForestManagement.Sites'
Register-PSFTeppArgumentCompleter -Command Register-FMSubnet -Parameter SiteName -Name 'ForestManagement.Sites'

Register-PSFTeppArgumentCompleter -Command Get-FMSiteLink -Parameter SiteName -Name 'ForestManagement.Sites'
Register-PSFTeppArgumentCompleter -Command Register-FMSiteLink -Parameter Site1 -Name 'ForestManagement.Sites'
Register-PSFTeppArgumentCompleter -Command Register-FMSiteLink -Parameter Site2 -Name 'ForestManagement.Site2New'
Register-PSFTeppArgumentCompleter -Command Unregister-FMSiteLink -Parameter Site1 -Name "ForestManagement.Linked.Site1"
Register-PSFTeppArgumentCompleter -Command Unregister-FMSiteLink -Parameter Site2 -Name "ForestManagement.Linked.Site2"

Register-PSFTeppArgumentCompleter -Command Invoke-FMSchema -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Invoke-FMSchemaLdif -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Invoke-FMServer -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Invoke-FMSite -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Invoke-FMSiteLink -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Invoke-FMSubnet -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMSchema -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMSchemaLdif -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMServer -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMSite -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMSiteLink -Parameter Server -Name 'ForestManagement.ForestName'
Register-PSFTeppArgumentCompleter -Command Test-FMSubnet -Parameter Server -Name 'ForestManagement.ForestName'