Register-PSFTeppScriptblock -Name 'ForestManagement.ForestName' -ScriptBlock {
    (Get-ADTrust -Filter *).Target
}