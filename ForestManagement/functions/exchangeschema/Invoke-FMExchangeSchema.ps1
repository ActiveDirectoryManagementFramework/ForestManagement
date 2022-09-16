function Invoke-FMExchangeSchema
{
<#
	.SYNOPSIS
		Applies the desired Exchange version to the tareted Forest.
	
	.DESCRIPTION
		Applies the desired Exchange version to the tareted Forest.
		Requires Schema Admin & Enterprise Admin privileges.
	
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
		PS C:\> Invoke-FMExchangeSchema -Server contoso.com
	
		Applies the desired Exchange version to the contoso.com Forest.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '')]
	[CmdletBinding(SupportsShouldProcess = $true)]
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
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type ExchangeSchema -Cmdlet $PSCmdlet
		$forestObject = Get-ADForest @parameters
		
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		$psParameter.ComputerName = $Server
		
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'Invoke-FMExchangeSchema.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		
		#region Functions
		function Test-ExchangeIsoPath
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
			[CmdletBinding()]
			param (
				[System.Management.Automation.Runspaces.PSSession]
				$Session,
				
				[string]
				$Path
			)
			
			Invoke-Command -Session $Session -ScriptBlock {
				Test-Path -Path $using:Path
			}
		}
		
		function Invoke-ExchangeSchemaUpdate
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
			[CmdletBinding()]
			param (
				[System.Management.Automation.Runspaces.PSSession]
				$Session,
				
				[string]
				$Path,
				
				[string]
				$OrganizationName,
				
				[switch]
				$SchemaOnly,

				[ValidateSet('InstallSchema', 'UpdateSchema', 'Install', 'Update', 'EnableSplit', 'DisableSplit')]
				[string]
				$Mode,

				[bool]
				$SplitPermission,

				[bool]
				$AllDomains
			)
			
			$result = Invoke-Command -Session $Session -ScriptBlock {
				param (
					$Parameters
				)
				$exchangeIsoPath = Resolve-Path -Path $Parameters.Path
				
				# Mount Volume
				$diskImage = Mount-DiskImage -ImagePath $exchangeIsoPath -PassThru
				$volume = Get-Volume -DiskImage $diskImage
				$limit = (Get-Date).AddMinutes(1)
				while (-not $volume.DriveLetter) {
					$volume = Get-Volume -DiskImage $diskImage
					if ($volume.DriveLetter) { break }
					if ((Get-Date) -gt $limit) {
						try { Dismount-DiskImage -ImagePath $exchangeIsoPath }
						catch { }
						throw "Timeout waiting for volume drive letter!"
					}
					Start-Sleep -Milliseconds 250
				}
				$installPath = "$($volume.DriveLetter):\setup.exe"
				
				#region Perform Installation
				$resultText = switch ($Parameters.Mode) {
					'InstallSchema' { & $installPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareSchema 2>&1 }
					'UpdateSchema' { & $installPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareSchema 2>&1 }
					'Install' {
						if (-not $Parameters.SplitPermission) { & $installPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAD /OrganizationName:$($Parameters.OrganizationName) 2>&1 }
						else { & $installPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAD /ActiveDirectorySplitPermissions:true /OrganizationName:$($Parameters.OrganizationName) 2>&1 }
					}
					'Update' { & $installPath /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAD /OrganizationName:$($Parameters.OrganizationName) 2>&1 }
					'EnableSplit' {
						& $installPath /PrepareAD /ActiveDirectorySplitPermissions:true /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1
						if (-not $Parameters) { & $installPath /PrepareDomain /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1 }
						else { & $installPath /PrepareAllDomains /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1 }
					}
					'DisableSplit' {
						& $installPath /PrepareAD /ActiveDirectorySplitPermissions:false /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1
						if (-not $Parameters) { & $installPath /PrepareDomain /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1 }
						else { & $installPath /PrepareAllDomains /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF 2>&1 }
					}
				}
				$results = [pscustomobject]@{
					Success = $LASTEXITCODE -lt 1
					Message = $resultText -join "`n"
				}
				#endregion Perform Installation
				
				# Dismount Volume
				try { Dismount-DiskImage -ImagePath $exchangeIsoPath }
				catch { }
				
				# Report result
				$results
			} -ArgumentList ($PSBoundParameters | ConvertTo-PSFHashtable -Exclude Session)
			Write-PSFMessage -Message ($result.Message -join "`n") -Tag exchange, result
			if (-not $result.Success)
			{
				throw "Error applying exchange update: $($result.Message)"
			}
		}
		#endregion Functions
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		if (-not $InputObject) {
			$InputObject = Test-FMExchangeSchema @parameters
		}

		foreach ($testItem in $InputObject)
		{
			#region Apply Updates if needed
			switch ($testItem.Type)
			{
				#region Install Exchange Schema
				'CreateSchema'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Installing' -ActionStringValues $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode InstallSchema -Path $testItem.Configuration.LocalImagePath -OrganizationName $testItem.Configuration.OrganizationName -ErrorAction Stop -SchemaOnly
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Install Exchange Schema
				
				#region Update Exchange Schema
				'UpdateSchema'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Updating' -ActionStringValues $testItem.ADObject, $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode UpdateSchema -Path $testItem.Configuration.LocalImagePath -OrganizationName $testItem.ADObject.OrganizationName -ErrorAction Stop -SchemaOnly
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Update Exchange Schema
				
				#region Install Exchange Schema & AD Objects
				'Create'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Installing' -ActionStringValues $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode Install -Path $testItem.Configuration.LocalImagePath -OrganizationName $testItem.Configuration.OrganizationName -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Install Exchange Schema & AD Objects
				
				#region Update Exchange Schema & AD Objects
				'Update'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.Updating' -ActionStringValues $testItem.ADObject, $testItem.Configuration -Target $forestObject -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode Update -Path $testItem.Configuration.LocalImagePath -OrganizationName $testItem.ADObject.OrganizationName -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Update Exchange Schema & AD Objects

				'DisableSplitP'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.DisablingSplitPermissions' -ActionStringValues $testItem.Configuration -Target $Server -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode DisableSplit -AllDomains $testItem.Configuration.AllDomains -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				'EnableSplitP'
				{
					if (-not (Test-ExchangeIsoPath -Session $session -Path $testItem.Configuration.LocalImagePath)) {
						Stop-PSFFunction -String 'Invoke-FMExchangeSchema.IsoPath.Missing' -StringValues $testItem.Configuration.LocalImagePath -EnableException $EnableException -Continue -Category ResourceUnavailable -Target $Server
					}
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMExchangeSchema.EnablingSplitPermissions' -ActionStringValues $testItem.Configuration -Target $Server -ScriptBlock {
						Invoke-ExchangeSchemaUpdate -Session $session -Mode EnableSplit -AllDomains $testItem.Configuration.AllDomains -Path $testItem.Configuration.LocalImagePath -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
			#endregion Apply Updates if needed
		}
	}
	end
	{
		if ($session) { Remove-PSSession -Session $session -ErrorAction Ignore -Confirm:$false -WhatIf:$false }
	}
}
