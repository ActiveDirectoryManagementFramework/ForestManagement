function Get-SchemaAdminCredential
{
	<#
	.SYNOPSIS
		Returns the credentials for the account to use for schema administration.
	
	.DESCRIPTION
		Returns the credentials for the account to use for schema administration.
		The behavior of this command is heavily controlled by the configuration system:
		ForestManagement.Schema.*
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-SchemaAdminCredential @parameters

		Returns the configured schema credentials
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		$script:temporarySchemaUpdateUser = $null
	}
	process
	{
		#region Case: Explicit Credentials
		if (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.Credential') {
			Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.Credential'
			return
		}
		#endregion Case: Explicit Credentials

		#region Case: Temporary Schema Admin Account
		if (Get-PSFConfigValue -FullName 'ForestManagement.Schema.AutoCreate.TempAdmin') {
			do
			{
				$newName = "$(Get-Random -Minimum 100000 -Maximum 999999)_$($env:USERNAME)"
			}
			while (Get-ADUser @parameters -LDAPFilter "(name=$newName)")
			$password = New-Password -Length 128 -AsSecureString

			Invoke-PSFProtectedCommand -ActionString 'Get-SchemaAdminCredential.Account.Creation' -Target $newName -ScriptBlock {
				$newUser = New-ADUser @parameters -Name $newName -Description 'Temporary Admin account used to update the schema' -AccountPassword $password -PassThru -Enabled $true -ErrorAction Stop
			} -EnableException $true -PSCmdlet $PSCmdlet
			if (-not $newUser) { return }

			$script:temporarySchemaUpdateUser = $newUser
			$domain = Get-ADDomain @parameters
			try { Get-ADGroup @parameters -Identity "$($domain.DomainSID)-518" | Add-ADGroupMember @parameters -Members $newUser -ErrorAction Stop }
			catch {
				Remove-ADUser -Identity $userObject @parameters
				$script:temporarySchemaUpdateUser = $null
				Stop-PSFFunction -String 'Get-SchemaAdminCredential.Account.Assignment.Failure' -StringValues $newName -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_
			}
			New-Object System.Management.Automation.PSCredential("$($domain.NetBIOSName)\$($newName)", $password)
			return
		}
		#endregion Case: Temporary Schema Admin Account

		#region Case: Explicit Schema Admin Account
		if (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.Name') {
			$accountName = Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.Name'
			if ($accountName -like "*\*") { $accountName = $account.Split("\")[1] }
			$domain = Get-ADDomain @parameters
			
			$accountObject = Get-ADUser @parameters -LDAPFilter "(name=$accountName)"
			$schemaAdmins = Get-ADGroup @parameters -Identity "$($domain.DomainSID)-518" -Properties Members

			#region Scenario: Account does not exist
			if (-not $accountObject)
			{
				if (-not (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoCreate')) {
					Stop-PSFFunction -String 'Get-SchemaAdminCredential.Account.ExistsNot' -StringValues $accountName -EnableException $true -Cmdlet $PSCmdlet -Category ObjectNotFound
				}

				$password = New-Password -Length 128 -AsSecureString
				Invoke-PSFProtectedCommand -ActionString 'Get-SchemaAdminCredential.Account.Creation' -Target $accountName -ScriptBlock {
					$userObject = New-ADUser @parameters -Name $accountName -AccountPassword $password -Enabled $true -Description "Admin account for updating the schema. Created by $($env:USERDOMAIN)\$($env:USERNAME)" -PassThru -ErrorAction Stop
				} -EnableException $true -PSCmdlet $PSCmdlet
				if (-not $userObject) { return }
				
				try { Get-ADGroup @parameters -Identity "$($domain.DomainSID)-518" | Add-ADGroupMember @parameters -Members $userObject -ErrorAction Stop }
				catch {
					Remove-ADUser -Identity $userObject @parameters
					Stop-PSFFunction -String 'Get-SchemaAdminCredential.Account.GroupAssignment.Failure' -StringValues $accountName -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_
				}
				New-Object System.Management.Automation.PSCredential("$($domain.NetBIOSName)\$($accountName)", $password)
				return
			}
			#endregion Scenario: Account does not exist
			
			#region Fail Fast
			if ($schemaAdmins.Members -notcontains $accountObject.DistinguishedName) {
				if (-not (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoGrant')) {
					Stop-PSFFunction -String 'Get-SchemaAdminCredential.Account.Unprivileged' -StringValues $accountName -EnableException $true -Category ResourceUnavailable -Cmdlet $PSCmdlet
				}
			}
			if (-not $accountObject.Enabled) {
				if (-not (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Account.AutoEnable')) {
					Stop-PSFFunction -String 'Get-SchemaAdminCredential.Account.Disabled' -StringValues $accountName -EnableException $true -Category ResourceUnavailable -Cmdlet $PSCmdlet
				}
			}
			#endregion Fail Fast

			#region Prepare account for schema administration
			if ($schemaAdmins.Members -notcontains $accountObject.DistinguishedName) {
				Invoke-PSFProtectedCommand -ActionString 'Get-SchemaAdminCredential.Account.Group.Assignment' -Target $accountName -ScriptBlock {
					$null = $schemaAdmins | Add-ADGroupMember @parameters -Members $accountObject -ErrorAction Stop
				} -EnableException $true -PSCmdlet $PSCmdlet
			}

			if (-not $accountObject.Enabled) {
				Invoke-PSFProtectedCommand -ActionString 'Get-SchemaAdminCredential.Account.Enable' -Target $accountName -ScriptBlock {
					$null = Enable-ADAccount @parameters -Identity $accountObject -ErrorAction Stop
				} -EnableException $true -PSCmdlet $PSCmdlet
			}
			#endregion Prepare account for schema administration

			#region Handle Password
			if (Get-PSFConfigValue -FullName 'ForestManagement.Schema.Password.AutoReset') {
				$password = New-Password -Length 128 -AsSecureString
				try {
					Write-PSFMessage -String 'Get-SchemaAdminCredential.Password.Reset' -StringValues $accountName
					$null = Set-ADAccountPassword @parameters -Identity $accountObject -NewPassword $password -ErrorAction Stop -Reset
				}
				catch { Stop-PSFFunction -String 'Get-SchemaAdminCredential.Password.Reset.Failed' -StringValues $accountName -EnableException $true -ErrorRecord $_ -Cmdlet $PSCmdlet }

				New-Object System.Management.Automation.PSCredential("$($domain.NetBIOSName)\$($accountName)", $password)
				return
			}
			else {
				try { $password = Read-Host -Prompt "Specify password for schema admin $accountName" -AsSecureString -ErrorAction Stop }
				catch { Stop-PSFFunction -String 'Get-SchemaAdminCredential.Password.InteractiveRead.Failed' -StringValues $accountName -EnableException $true -ErrorRecord $_ -Cmdlet $PSCmdlet }

				New-Object System.Management.Automation.PSCredential("$($domain.NetBIOSName)\$($accountName)", $password)
				return
			}
			#endregion Handle Password
		}
		#endregion Case: Explicit Schema Admin Account

		# Case: Current User Credential
		$Credential
	}
}
