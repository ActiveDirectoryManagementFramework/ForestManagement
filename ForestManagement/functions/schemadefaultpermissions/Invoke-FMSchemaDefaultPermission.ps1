function Invoke-FMSchemaDefaultPermission
{
<#
	.SYNOPSIS
		Brings the target forest into compliance with the defined default permissions in its schema.
	
	.DESCRIPTION
		Brings the target forest into compliance with the defined default permissions in its schema.
	
		Use the module's configuration settings to govern schema admin credentials.
		The configuration can be read with Get-PSFConfig and updated with Set-PSFConfig.
	
	.PARAMETER InputObject
		Test results from Test-FMSchemaDefaultPermission to apply.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.

	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Invoke-FMSchemaDefaultPermission -Server contoso.com
	
		Brings the contoso.com forest into compliance with the defined default permissions in its schema.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		#region Utility Functions
		function Add-AccessRule
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
			[CmdletBinding()]
			param (
				$Change,
				
				$Session,
				
				[Hashtable]
				$Tracking
			)
			
			Invoke-Command -Session $Session -ArgumentList $Change -ScriptBlock {
				param ($Change)
				
				$rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
					[System.Security.Principal.SecurityIdentifier]$Change.Configuration.Principal,
					$Change.Configuration.ActiveDirectoryRights,
					$Change.Configuration.AccessControlType,
					$Change.Configuration.ObjectTypeGuid,
					$Change.Configuration.InheritanceType,
					$Change.Configuration.InheritedObjectTypeGuid
				)
				$null = $acl.AddAccessRule($rule)
			} -ErrorAction Stop
			$Tracking[$Change] = $Change
		}
		
		function Remove-AccessRule
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$Change,
				
				$Session,
				
				[Hashtable]
				$Tracking
			)
			
			Invoke-Command -Session $Session -ArgumentList $Change -ScriptBlock {
				param ($Change)
				$rules = $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
				foreach ($rule in $rules)
				{
					if ($rule.ActiveDirectoryRights -ne $Change.ADObject.ActiveDirectoryRights) { continue }
					if ($rule.InheritanceType -ne $Change.ADObject.InheritanceType) { continue }
					if ($rule.ObjectType -ne $Change.ADObject.ObjectType) { continue }
					if ($rule.InheritedObjectType -ne $Change.ADObject.InheritedObjectType) { continue }
					if ($rule.AccessControlType -ne $Change.ADObject.AccessControlType) { continue }
					if ("$($rule.IdentityReference)" -ne "$($Change.ADObject.IdentityReference)") { continue }
					$null = $acl.RemoveAccessRule($rule)
				}
			} -ErrorAction Stop
			$Tracking[$Change] = $Change
		}
		
		function Write-SchemaDefaultPermission
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
			[CmdletBinding()]
			param (
				$Session,
				
				[hashtable]
				$SchemaParameters
			)
			
			$newSddl, $schemaObjectDN = Invoke-Command -Session $Session -ScriptBlock { $acl.Sddl, $schemaObject.DistinguishedName }
			
			Set-ADObject @SchemaParameters -Identity $schemaObjectDN -Replace @{ defaultSecurityDescriptor = $newSddl } -ErrorAction Stop
		}
		#endregion Utility Functions
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SchemaDefaultPermissions -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters

		try { $rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'Invoke-FMSchemaDefaultPermission.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$forest = Get-ADForest @parameters
		$parameters["Server"] = $forest.SchemaMaster
		#region WinRM
		Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.WinRM.Connect' -Target $forest.SchemaMaster -ScriptBlock {
			$psParameters = $parameters.Clone()
			$psParameters.Remove('Server')
			$psParameters.ComputerName = $forest.SchemaMaster
			$session = New-PSSession @psParameters -ErrorAction Stop
		} -EnableException $EnableException -PSCmdlet $PSCmdlet -WhatIf:$false -Confirm:$false
		#endregion WinRM
		
		#region Resolve Credentials
		$cred = $null
		$schemaParameters = $parameters.Clone()
		Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.Schema.Credentials' -Target $forest.SchemaMaster -ScriptBlock {
			[PSCredential]$cred = Get-SchemaAdminCredential @parameters | Write-Output | Select-Object -First 1
			if ($cred) { $schemaParameters['Credential'] = $cred }
		} -EnableException $EnableException -PSCmdlet $PSCmdlet
		if (Test-PSFFunctionInterrupt) { return }
		$null = Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.Credentials.Test' -Target $forest.SchemaMaster -ScriptBlock {
			$null = Get-ADDomain @schemaParameters -ErrorAction Stop
		} -EnableException $EnableException -PSCmdlet $PSCmdlet -RetryCount 5 -RetryWait 1
		if (Test-PSFFunctionInterrupt) { return }
		#endregion Resolve Credentials
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $InputObject)
		{
			$InputObject = Test-FMSchemaDefaultPermission @parameters -EnableException:$EnableException
		}
		
		foreach ($testItem in $InputObject)
		{
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'ForestManagement.SchemaDefaultPermission.TestResult')
			{
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-FMSchemaDefaultPermission', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			switch ($testItem.Type)
			{
				'Update'
				{
					#region Load Acl from SDDL
					Invoke-Command -Session $session -ArgumentList $rootDSE.schemaNamingContext, $testItem.Identity -ScriptBlock {
						param ($SchemaNC, $ClassName)
						$schemaObject = Get-ADObject -Server localhost -SearchBase $SchemaNC -LDAPFilter "(name=$ClassName)" -Properties defaultSecurityDescriptor
						$acl = New-Object System.DirectoryServices.ActiveDirectorySecurity
						$acl.SetSecurityDescriptorSddlForm($schemaObject.defaultSecurityDescriptor)
					}
					#endregion Load Acl from SDDL
					
					#region Apply individual changes to in-memory ACL
					$tracking = @{ }
					# Apply remove changes
					foreach ($change in $testItem.Changed)
					{
						if ($change.Type -ne 'Remove') { continue }
						
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.AccessRule.Remove' -ActionStringValues $change.Identity, $change.Privilege, $change.Access -Target $testItem -ScriptBlock {
							Remove-AccessRule -Change $change -Session $session -Tracking $tracking -ErrorAction Stop
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -Tag invoke
						
					}
					
					# Apply add changes
					foreach ($change in $testItem.Changed)
					{
						if ($change.Type -ne 'Add') { continue }
						
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.AccessRule.Add' -ActionStringValues $change.Identity, $change.Privilege, $change.Access -Target $testItem -ScriptBlock {
							Add-AccessRule -Change $change -Session $session -Tracking $tracking -ErrorAction Stop
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -Tag invoke
					}
					#endregion Apply individual changes to in-memory ACL
					
					# Write SDDL back to schema object
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.Permissions.Update' -ActionStringValues $tracking.Count, $testItem.Changed.Count, $testItem.Identity -Target $testItem -ScriptBlock {
						Write-SchemaDefaultPermission -Session $session -SchemaParameters $schemaParameters -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -Tag invoke
				}
				'NotFound'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-FMSchemaDefaultPermission.NotFound' -StringValues $testItem.Identity -Target $testItem
				}
				'IdentityError'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-FMSchemaDefaultPermission.IdentityError' -StringValues $testItem.Identity -Target $testItem
				}
			}
		}
	}
	end
	{
		if ($session) { Remove-PSSession -Session $session -ErrorAction Ignore -WhatIf:$false -Confirm:$false }
		
		if (Test-PSFFunctionInterrupt) { return }
		
		Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaDefaultPermission.Schema.Credentials.Release' -Target $forest.SchemaMaster -ScriptBlock {
			$null = Remove-SchemaAdminCredential @parameters -ErrorAction Stop
		} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
	}
}