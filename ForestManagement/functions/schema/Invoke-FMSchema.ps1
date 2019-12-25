function Invoke-FMSchema
{
	<#
		.SYNOPSIS
			Updates the schema to conform to the desired state.
		
		.DESCRIPTION
			Updates the schema to conform to the desired state.
			Can add new attributes and update existing ones.

			Use Register-FMSchema to define the desired state.
			Use the module's configuration settings to govern schema admin credentials.
			The configuration can be read with Get-PSFConfig and updated with Set-PSFConfig.
		
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
		Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Schema.Credentials' -Target $forest.SchemaMaster -ScriptBlock {
			[PSCredential]$cred = Get-SchemaAdminCredential @parameters | Write-Output | Select-Object -First 1
			if ($cred) { $parameters['Credential'] = $cred }
		} -EnableException $EnableException -PSCmdlet $PSCmdlet
		if (Test-PSFFunctionInterrupt) { return }
		#endregion Resolve Credentials

		$testResult = Test-FMSchema @parameters

		# Prepare parameters to use for when discarding the schema credentials
		if ($cred -and ($cred -ne $Credential)) { $removeParameters['SchemaAccountCredential'] = $cred }
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		:main foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				#region Create new Schema Attribute
				'ConfigurationOnly' {
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
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue -RetryCount 10
					}
				}
				#endregion Create new Schema Attribute

				#region Update Schema Attribute
				'InEqual' {
					$resolvedAttributes = Resolve-SchemaAttribute -Configuration $testItem.Configuration -ADObject $testItem.ADObject
					if ($resolvedAttributes.Keys.Count -ge 1) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Updating.Attribute' -ActionStringValues ($resolvedAttributes.Keys -join ', ') -Target $testItem.Identity -ScriptBlock {
							$testItem.ADObject | Set-ADObject @parameters -Replace $resolvedAttributes -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
					}

					foreach ($class in  $testItem.Configuration.ObjectClass) {
						try { $classObject = Get-ADObject @parameters -SearchBase $rootDSE.schemaNamingContext -LDAPFilter "(name=$($class))" -ErrorAction Stop -Properties mayContain }
						catch { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.Failed' -StringValues $class -EnableException $EnableException -Continue -ErrorRecord $_ }
						if (-not $classObject) { Stop-PSFFunction -String 'Invoke-FMSchema.Reading.ObjectClass.NotFound' -StringValues $class -EnableException $EnableException -Continue }

						if ($classObject.mayContain -notcontains $testItem.ADObject.LdapDisplayName) {
							Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Assigning.Attribute.ToObjectClass' -ActionStringValues $class -Target $testItem.Identity -ScriptBlock {
								$classObject | Set-ADObject @parameters -Add @{ mayContain = $testItem.ADObject.LdapDisplayName } -ErrorAction Stop
							} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
						}
					}
				}
				#endregion Update Schema Attribute
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }

		Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchema.Schema.Credentials.Release' -Target $forest.SchemaMaster -ScriptBlock {
			$null = Remove-SchemaAdminCredential @removeParameters -ErrorAction Stop
		} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
	}
}