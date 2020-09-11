function Test-FMSchemaDefaultPermission
{
<#
	.SYNOPSIS
		Validates, whether the target forest has the defined default permissions applied in its schema.
	
	.DESCRIPTION
		Validates, whether the target forest has the defined default permissions applied in its schema.
		Returns a list of all actions that would be taken by the associated Invoke-* command.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.

	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-FMSchemaDefaultPermission -Server contoso.com
	
		Validates, whether the contoso.com forest has the defined default permissions applied in its schema.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SchemaDefaultPermissions -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters
		try { $rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'Test-FMSchemaDefaultPermission.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$forest = Get-ADForest @parameters
		$parameters["Server"] = $forest.SchemaMaster
		Invoke-PSFProtectedCommand -ActionString 'Test-FMSchemaDefaultPermission.WinRM.Connect' -Target $forest.SchemaMaster -ScriptBlock {
			$psParameters = $parameters.Clone()
			$psParameters.Remove('Server')
			$psParameters.ComputerName = $forest.SchemaMaster
			$session = New-PSSession @psParameters -ErrorAction Stop
		} -EnableException $EnableException -PSCmdlet $PSCmdlet -WhatIf:$false -Confirm:$false
		
		#region Default Permissions Scriptblock
		$defaultPermissionScriptblock = {
			param (
				$ClassName,
				
				$SchemaNC
			)
			$object = Get-ADObject -LDAPFilter "(name=$ClassName)" -SearchBase $SchemaNC -Server localhost -Properties defaultSecurityDescriptor
			if (-not $object) { throw "Object class '$ClassName' not found!" }
			$acl = New-Object System.DirectoryServices.ActiveDirectorySecurity
			$acl.SetSecurityDescriptorSddlForm($object.defaultSecurityDescriptor)
			$acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
		}
		#endregion Default Permissions Scriptblock
		
		#region Utility Functions
		function Convert-ConfiguredAccessRule
		{
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$AccessRule,
				
				[System.Collections.Hashtable]
				$Parameters
			)
			process
			{
				$basicHash = $AccessRule | ConvertTo-PSFHashtable
				$basicHash.IdentityResolved = $true
				$basicHash.Error = $null
				$basicHash.ObjectTypeGuid = Convert-DMSchemaGuid @Parameters -Name $basicHash.ObjectType -OutType GuidString
				$basicHash.ObjectTypeName = Convert-DMSchemaGuid @Parameters -Name $basicHash.ObjectType -OutType Name
				$basicHash.InheritedObjectTypeGuid = Convert-DMSchemaGuid @Parameters -Name $basicHash.InheritedObjectType -OutType GuidString
				$basicHash.InheritedObjectTypeName = Convert-DMSchemaGuid @Parameters -Name $basicHash.InheritedObjectType -OutType Name
				
				# Namensauflösung
				$basicHash.ResolvedIdentity = $AccessRule.Identity | Resolve-String -Mode Lax -ArgumentList $Parameters
				
				# Principal Auflösung
				try { $basicHash.Principal = [string]($basicHash.ResolvedIdentity | Resolve-Principal -OutputType SID @Parameters -ErrorAction Stop) }
				catch
				{
					Write-PSFMessage -Level Warning -String 'Test-FMSchemaDefaultPermission.Principal.ResolutionError' -StringValues $AccessRule.Identity, $basicHash.ResolvedIdentity -Target $AccessRule
					$basicHash.IdentityResolved = $false
					$basicHash.Error = $_
				}
				
				[pscustomobject]$basicHash
			}
		}
		
		function Compare-AccessRule
		{
			[CmdletBinding()]
			param (
				$Configuration,
				
				$Applied,
				
				[PSFComputer]
				$Server,
				
				[Hashtable]
				$Parameters
			)
			
			#region Utility Functions
			function New-Change
			{
				[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
				[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
				[CmdletBinding()]
				param (
					[Parameter(Mandatory = $true)]
					[ValidateSet('Add', 'Remove')]
					[string]
					$Type,
					
					$Configuration,
					
					$ADObject,
					
					[string]
					$ClassName,
					
					[hashtable]
					$Parameters
				)
				
				$object = [pscustomobject]@{
					PSTypeName = 'ForestManagement.SchemaDefaultPermission.Change'
					Type	   = $Type
					Identity   = $Configuration.ResolvedIdentity
					Privilege  = $Configuration.ActiveDirectoryRights
					Access	   = $Configuration.AccessControlType -as [string]
					Configuration = $Configuration
					ADObject   = $ADObject
					ClassName  = $ClassName
				}
				if ($ADObject)
				{
					$object.Identity = $ADObject.IdentityReference
					if (($ADObject.IdentityReference -as [System.Security.Principal.SecurityIdentifier]).AccountDomainSid)
					{
						try { $object.Identity = $ADObject.IdentityReference | Resolve-Principal @Parameters -ErrorAction Stop -OutputType NTAccount }
						catch { } # No Action Needed
					}
					$object.Privilege = $ADObject.ActiveDirectoryRights
					$object.Access = $ADObject.AccessControlType -as [string]
				}
				
				Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Force -Value {
					'{0}: {1}>{2}({3})' -f $this.Type, $this.Identity, $this.Privilege, $this.Access.SubString(0, 1)
				} -PassThru
			}
			#endregion Utility Functions
			
			#region Process ProcessingMode
			$processingMode = 'Additive'
			if ($Configuration.Mode -contains 'Defined') { $processingMode = 'Defined' }
			if ($Configuration.Mode -contains 'Constrained') { $processingMode = 'Constrained' }
			
			if ($processingMode -eq 'Constrained' -and ($Configuration | Where-Object IdentityResolved -EQ $false))
			{
				Write-PSFMessage -Level Warning -String 'Test-FMSchemaDefaultPermission.Class.IdentityUncertain' -StringValues $Configuration[0].ClassName -Target $Configuration[0].ClassName -Data @{
					Configured = $Configuration
					Applied    = $Applied
				}
				New-TestResult -ObjectType SchemaDefaultPermission -Type IdentityError -Identity $Configuration[0].ClassName -Server $Server -Configuration $Configuration -ADObject $Applied
				return
			}
			#endregion Process ProcessingMode
			
			$changes = @()
			$matchedRules = @()
			#region Check configured rules against applied rules
			:outer foreach ($ruleDefinition in $Configuration)
			{
				if (-not $ruleDefinition.IdentityResolved) { continue }
				foreach ($appliedRule in $Applied)
				{
					if ($ruleDefinition.ActiveDirectoryRights -ne $appliedRule.ActiveDirectoryRights) { continue }
					if ($ruleDefinition.InheritanceType -ne $appliedRule.InheritanceType) { continue }
					if ($ruleDefinition.ObjectTypeGuid -ne $appliedRule.ObjectType) { continue }
					if ($ruleDefinition.InheritedObjectTypeGuid -ne $appliedRule.InheritedObjectType) { continue }
					if ($ruleDefinition.AccessControlType -ne $appliedRule.AccessControlType) { continue }
					if ($ruleDefinition.Principal -ne $appliedRule.IdentityReference) { continue }
					
					# Existing rule is a match
					$matchedRules += $appliedRule
					continue outer
				}
				
				$changes += New-Change -Type Add -Configuration $ruleDefinition -ClassName $Configuration[0].ClassName -Parameters $Parameters
			}
			#endregion Check configured rules against applied rules
			
			#region Check applied rules against configured rules
			foreach ($appliedRule in $Applied)
			{
				if ($processingMode -eq 'Additive') { break }
				if ($appliedRule -in $matchedRules) { continue }
				if ($processingMode -eq 'Defined' -and $Configuration.Principal -notcontains $Applied.Identity) { continue }
				
				$changes += New-Change -Type Remove -ADObject $appliedRule -ClassName $Configuration[0].ClassName -Parameters $Parameters
			}
			#endregion Check applied rules against configured rules
			
			if ($changes)
			{
				New-TestResult -ObjectType SchemaDefaultPermission -Type Update -Identity $Configuration[0].ClassName -Server $Server -Configuration $Configuration -ADObject $Applied -Changed $changes
			}
		}
		#endregion Utility Functions
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($className in $script:schemaDefaultPermissions.Keys)
		{
			$definedAccessRules = $script:schemaDefaultPermissions[$className].Values | Convert-ConfiguredAccessRule -Parameters $parameters
			
			try { $actualAccessRules = Invoke-Command -Session $session -ScriptBlock $defaultPermissionScriptblock -ArgumentList $className, $rootDSE.schemaNamingContext }
			catch
			{
				Write-PSFMessage -Level Warning -String 'Test-FMSchemaDefaultPermission.Class.NotFound' -StringValues $className -Target $className
				New-TestResult -ObjectType SchemaDefaultPermission -Type NotFound -Identity $className -Server $Server -Configuration $definedAccessRules
				continue
			}
			
			Compare-AccessRule -Configuration $definedAccessRules -Applied $actualAccessRules -Server $Server -Parameters $parameters
		}
	}
	end
	{
		if ($session) { Remove-PSSession -Session $session -ErrorAction Ignore -WhatIf:$false -Confirm:$false }
	}
}
