Register-PSFTeppScriptblock -Name 'ForestManagement.ExchangeVersion' -ScriptBlock {
	(Get-AdcExchangeVersion).Binding
} -Global