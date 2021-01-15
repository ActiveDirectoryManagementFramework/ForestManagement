function Test-SchemaAdminCredential {
	<#
	.SYNOPSIS
		Validates, whether the schema admin credential workflow should be executed.
	
	.DESCRIPTION
		Validates, whether the schema admin credential workflow should be executed.
		This is done using two checks:
		- Is the ForestManagement.Schema.Account.IgnoreOnCredentialProvider config setting set?
		- Is the command calling the caller of this command anything other than Invoke-AdmfForest with the CredentialProvider parameter set
		If the configuration is set and a crededntial provider was specified, it will return false.
	
	.EXAMPLE
		PS C:\> Test-SchemaAdminCredential

		Validates, whether the schema admin credential workflow should be executed.
	#>
	[CmdletBinding()]
	param ()

	if (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.IgnoreOnCredentialProvider') {
		return $true
	}

	$invocation = (Get-PSCallstack)[2]
	-not ($invocation.Command -eq 'Invoke-AdmfForest' -and $invocation.InvocationInfo.BoundParameters.Keys -contains 'CredentialProvider')
}