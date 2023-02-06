function Invoke-FMSchema {
	<#
		.SYNOPSIS
			Updates the schema to conform to the desired state.
		
		.DESCRIPTION
			Updates the schema to conform to the desired state.
			Can add new attributes and update existing ones.

			Use Register-FMSchema to define the desired state.
			Use the module's configuration settings to govern schema admin credentials.
			The configuration can be read with Get-PSFConfig and updated with Set-PSFConfig.
		
		.PARAMETER InputObject
			Test results provided by the associated test command.
			Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
		
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
			PS C:\> Invoke-FMSchema

			Updates the schema of the current forest according to the configured settings
	#>
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Schema -Cmdlet $PSCmdlet
		try { $rootDSE = Get-ADRootDSE @parameters -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-FMSchema.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$forest = Get-ADForest @parameters
		$parameters["Server"] = $forest.SchemaMaster
		$removeParameters = $parameters.Clone()
		
		#region Resolve Credentials
		$cred = $null
		if (Test-SchemaAdminCredential) {
			Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Schema.Credentials' -Target $forest.SchemaMaster -ScriptBlock {
				[PSCredential]$cred = Get-SchemaAdminCredential @parameters | Write-Output | Select-Object -First 1
				if ($cred) { $parameters['Credential'] = $cred }
			} -EnableException $EnableException -PSCmdlet $PSCmdlet
			if (Test-PSFFunctionInterrupt) { return }
		}
		
		$null = Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Credentials.Test' -Target $forest.SchemaMaster -ScriptBlock {
			$null = Get-ADDomain @parameters -ErrorAction Stop
		} -EnableException $EnableException -PSCmdlet $PSCmdlet -RetryCount 5 -RetryWait 1
		if (Test-PSFFunctionInterrupt) { return }
		#endregion Resolve Credentials

		# Prepare parameters to use for when discarding the schema credentials
		if ($cred -and ($cred -ne $Credential)) { $removeParameters['SchemaAccountCredential'] = $cred }
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }

		if (-not $InputObject) {
			$InputObject = Test-FMSchema @parameters
		}

		$testResultsSorted = $InputObject | Sort-Object {
			if ($_.Type -eq 'Decommission') { 0 }
			elseif ($_.Type -eq 'Rename') { 2 }
			elseif ($_.Type -eq 'ConfigurationOnly') { 3 }
			else { 1 }
		}
		:main foreach ($testItem in $testResultsSorted) {
			switch ($testItem.Type) {
				#region Create new Schema Attribute
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Creating.Attribute' -Target $testItem.Identity -ScriptBlock {
						New-ADObject @parameters -Type attributeSchema -Name $testItem.Configuration.AdminDisplayName -Path $rootDSE.schemaNamingContext -OtherAttributes (Resolve-SchemaAttribute -Configuration $testItem.Configuration) -ErrorAction Stop
						Update-Schema @parameters
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					
					foreach ($class in  $testItem.Configuration.ObjectClass) {
						try { $classObject = Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=$($class))" -ErrorAction Stop }
						catch { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.Failed' -StringValues $class -EnableException $EnableException -Continue -ErrorRecord $_ }
						if (-not $classObject) { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.NotFound' -StringValues $class -EnableException $EnableException -Continue }

						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Assigning.Attribute.ToObjectClass' -ActionStringValues $class -Target $testItem.Identity -ScriptBlock {
							$classObject | Set-ADObject @parameters -Add @{ mayContain = $testItem.Configuration.LdapDisplayName } -ErrorAction Stop
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount 10
					}
				}
				#endregion Create new Schema Attribute

				#region Decommission the unwanted Schema Attribute
				'Decommission' {
					$values = @{
						IsDefunct = $true
						# PartialAttributeSet = $false
					}
					foreach ($adObject in (Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(mayContain=$($testItem.Configuration.OID))" -Properties ldapDisplayName)) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Decommission.MayContain' -ActionStringValues $testItem.ADObject.LdapDisplayName, $adObject.LdapDisplayName -Target $testItem -ScriptBlock {
							$adObject | Set-ADObject @parameters -Remove @{ mayContain = $testItem.ADObject.LdapDisplayName } -ErrorAction Stop
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}

					foreach ($adObject in (Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(mustContain=$($testItem.Configuration.OID))" -Properties ldapDisplayName)) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Decommission.MustContain' -ActionStringValues $testItem.ADObject.LdapDisplayName, $adObject.LdapDisplayName -Target $testItem -ScriptBlock {
							$adObject | Set-ADObject @parameters -Remove @{ mustContain = $testItem.ADObject.LdapDisplayName } -ErrorAction Stop
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}

					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Decommission.Attribute' -ActionStringValues $testItem.ADObject.LdapDisplayName, $testItem.ADObject.AttributeID -Target $testItem -ScriptBlock {
						$testItem.ADObject | Set-ADObject @parameters -Replace $values -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					$rootDSE = Get-ADRootDSE @parameters
				}
				#endregion Decommission the unwanted Schema Attribute

				#region Update Schema Attribute
				'Update' {
					$resolvedAttributes = Resolve-SchemaAttribute -Configuration $testItem.Configuration -ADObject $testItem.ADObject
					if ($resolvedAttributes.Keys.Count -ge 1) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Updating.Attribute' -ActionStringValues ($resolvedAttributes.Keys -join ', ') -Target $testItem.Identity -ScriptBlock {
							$testItem.ADObject | Set-ADObject @parameters -Replace $resolvedAttributes -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}

					# Do not process MayContain for defunct attributes
					if ($testItem.Configuration.IsDefunct) { continue }

					# Only proceed if any Object Class changes are intended
					$change = $testItem.Changed | Where-Object Property -EQ 'ObjectClass'
					if (-not $change) { continue }

					foreach ($class in $change.New | Where-Object { $_ -notin $change.Old }) {
						try { $classObject = Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=$($class))" -ErrorAction Stop -Properties mayContain }
						catch { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.Failed' -StringValues $class -EnableException $EnableException -Continue -ErrorRecord $_ }
						if (-not $classObject) { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.NotFound' -StringValues $class -EnableException $EnableException -Continue }
	
						if ($classObject.mayContain -notcontains $testItem.ADObject.LdapDisplayName) {
							Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Assigning.Attribute.ToObjectClass' -ActionStringValues $class, $testItem.Identity -Target $testItem.Identity -ScriptBlock {
								$classObject | Set-ADObject @parameters -Add @{ mayContain = $testItem.ADObject.LdapDisplayName } -ErrorAction Stop
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
					}

					foreach ($class in $change.Old | Where-Object { $_ -notin $change.New }) {
						try { $classObject = Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=$($class))" -ErrorAction Stop -Properties mayContain }
						catch { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.Failed' -StringValues $class -EnableException $EnableException -Continue -ErrorRecord $_ }
						if (-not $classObject) { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.NotFound' -StringValues $class -EnableException $EnableException -Continue }
	
						if ($classObject.mayContain -contains $testItem.ADObject.LdapDisplayName) {
							Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Removing.Attribute.FromObjectClass' -ActionStringValues $class, $testItem.Identity -Target $testItem.Identity -ScriptBlock {
								$classObject | Set-ADObject @parameters -Remove @{ mayContain = $testItem.ADObject.LdapDisplayName } -ErrorAction Stop
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
					}
				}
				#endregion Update Schema Attribute

				#region Rename Schema Attribute
				'Rename' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Rename.Attribute' -ActionStringValues $testItem.ADObject.cn, $testItem.Configuration.Name -Target $testItem -ScriptBlock {
						$testItem.ADObject | Rename-ADObject -NewName $testItem.Configuration.Name -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Rename Schema Attribute
			}
		}
	}
	end {
		if (Test-PSFFunctionInterrupt) { return }

		if (Test-SchemaAdminCredential) {
			Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Schema.Credentials.Release' -Target $forest.SchemaMaster -ScriptBlock {
				$null = Remove-SchemaAdminCredential @removeParameters -ErrorAction Stop
			} -EnableException $EnableException -PSCmdlet $PSCmdlet
		}
	}
}