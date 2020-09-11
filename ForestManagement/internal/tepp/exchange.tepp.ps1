Register-PSFTeppScriptblock -Name 'ForestManagement.ExchangeVersion' -ScriptBlock {
	& (Get-Module ForestManagement) { (Get-ExchangeVersion).Binding }
} -Global