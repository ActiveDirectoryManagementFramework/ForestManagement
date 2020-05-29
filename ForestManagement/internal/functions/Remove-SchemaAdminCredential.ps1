function Remove-SchemaAdminCredential
{
	<#
		.SYNOPSIS
			Implements the post processing of schema admin credentials.
		
		.DESCRIPTION
			Implements the post processing of schema admin credentials.
			This command is responsible for applying the schema admin credential configuration policies.
			For example, it will remove temporary admin accounts or perform the auto-reset auf admin credentials.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.PARAMETER SchemaAccountCredential
			The credential object of the schema admin that was returned by Get-SchemaAdminCredential.

		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
		
		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
		
		.EXAMPLE
			PS C:\> Remove-SchemaAdminCredential @removeParameters

			Cleans up the credentials according to policy.
	#>
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[PSCredential]
		$SchemaAccountCredential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		$domain = Get-ADDomain @parameters
	}
	process
	{
		if ($SchemaAccountCredential) {
			$userName = $SchemaAccountCredential.GetNetworkCredential().UserName
			try {
				Write-PSFMessage -String 'Remove-SchemaAdminCredential.SchemaAccount.Resolve' -StringValues $userName
				$accountObject = Get-ADUser @parameters -Identity $userName -ErrorAction Stop
			}
			catch { Stop-PSFFunction -String 'Remove-SchemaAdminCredential.SchemaAccount.Resolve.Failed' -StringValues $userName -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
		}
		if ((Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoRevoke') -and ($accountObject)) {
			Invoke-PSFProtectedCommand -ActionString 'Remove-SchemaAdminCredential.Account.Group.Revoke' -Target $username -ScriptBlock {
				"$($domain.DomainSID)-518" | Remove-ADGroupMember @parameters -Members $accountObject -ErrorAction Stop -Confirm:$false
			} -EnableException $true -PSCmdlet $PSCmdlet
		}
		if ((Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoDisable') -and ($accountObject)) {
			$null = Invoke-PSFProtectedCommand -ActionString 'Remove-SchemaAdminCredential.SchemaAccount.Disable' -Target $username -ScriptBlock {
				Disable-ADAccount @parameters -Identity $accountObject -ErrorAction Stop -Confirm:$false
			} -EnableException $true -PSCmdlet $PSCmdlet
		}
		if ((Get-PSFConfigValue -FullName 'ForestManagement.Schema.Password.AutoReset') -and ($accountObject)) {
			$null = Invoke-PSFProtectedCommand -ActionString 'Remove-SchemaAdminCredential.SchemaAccount.PasswordReset' -Target $username -ScriptBlock {
				$password = New-Password -Length 128 -AsSecureString
				Set-ADAccountPassword @parameters -Identity $accountObject -ErrorAction Stop -NewPassword $password -Reset -Confirm:$false
			} -EnableException $true -PSCmdlet $PSCmdlet
		}
		if ((Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoDescription') -and ($accountObject)) {
			$null = Invoke-PSFProtectedCommand -ActionString 'Remove-SchemaAdminCredential.Account.AutoDescription' -Target $username -ScriptBlock {
				Set-ADUser @parameters -Identity $accountObject -Description (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoDescription') -ErrorAction Stop
			} -EnableException $true -PSCmdlet $PSCmdlet
		}
		if ($script:temporarySchemaUpdateUser) {
			try {
				Write-PSFMessage -String 'Remove-SchemaAdminCredential.TemporaryAccount.Remove' -StringValues $script:temporarySchemaUpdateUser.Name
				Remove-ADUser @parameters -Identity $script:temporarySchemaUpdateUser -ErrorAction Stop -Confirm:$false
				$script:temporarySchemaUpdateUser = $null
			}
			catch { Stop-PSFFunction -String 'Remove-SchemaAdminCredential.TemporaryAccount.Remove.Failed' -StringValues $script:temporarySchemaUpdateUser.Name -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
		}
	}
}