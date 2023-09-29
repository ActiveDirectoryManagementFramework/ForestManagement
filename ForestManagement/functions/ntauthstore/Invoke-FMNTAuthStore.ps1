function Invoke-FMNTAuthStore {
<#
	.SYNOPSIS
		Applies the desired certificates to the NTAuth store.
	
	.DESCRIPTION
		Applies the desired certificates to the NTAuth store.
		This allows distributing certificates that are trusted across the entire forest.
	
	.PARAMETER InputObject
		The test results to apply.
		Only specify objects returned by Test-FMNTAuthStore.
		By default, if you do not specify this parameter it will run the test and apply all deltas found.
	
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
		PS C:\> Invoke-FMNTAuthStore -Server contoso.com
	
		Applies the defined NTAuthStore configuration to the contoso.com domain.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
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
		Assert-Configuration -Type ntAuthStoreCertificates -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters
		
		$computerName = (Get-ADDomain @parameters).PDCEmulator
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential -Inherit
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch {
			Stop-PSFFunction -String 'Invoke-FMNTAuthStore.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		
		#region Add Certificate Scriptblock
		$addCertificateScript = {
			param (
				$Certificate
			)
			
			$certPath = "$env:temp\cert_$(Get-Random -Minimum 10000 -Maximum 99999).cer"
			
			try { $Certificate.GetRawCertData() | Set-Content $certPath -Encoding Byte -ErrorAction Stop }
			catch {
				[pscustomobject]@{
					Success = $false
					Stage   = 'Writing certificate file'
					Error   = $_
				}
				return
			}
			
			$res = certutil.exe -dspublish -f $certPath NTAuthCA 2>&1
			if ($LASTEXITCODE -gt 0) {
				[pscustomobject]@{
					Success = $false
					Stage   = 'Applying certificate using certutil'
					Error   = $res
				}
				Remove-Item -Path $certPath -ErrorAction Ignore
				return
			}
			Remove-Item -Path $certPath -ErrorAction Ignore
			
			[pscustomobject]@{
				Success = $true
				Stage   = 'Done'
				Error   = $null
			}
		}
		#endregion Add Certificate Scriptblock
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }
		
		# Test All NTAuthStore Certificates if no specific test result was specified
		if (-not $InputObject) {
			$InputObject = Test-FMNTAuthStore @parameters
		}
		
		:main foreach ($testResult in $InputObject) {
			# Catch invalid input - can only process test results
			if ($testResult.PSObject.TypeNames -notcontains 'ForestManagement.NTAuthStore.TestResult') {
				Stop-PSFFunction -String 'Invoke-FMNTAuthStore.Invalid.Input' -StringValues $testResult -Target $testResult -Continue -EnableException $EnableException
			}
			
			switch ($testResult.Type) {
				'Add' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMNTAuthStore.Add' -ActionStringValues $testResult.Configuration.Subject -Target $testResult -ScriptBlock {
						$result = Invoke-Command -Session $session -ArgumentList $testResult.Configuration -ScriptBlock $addCertificateScript
						if (-not $result.Success) {
							throw "Error executing $($result.Stage) : $($result.Error)"
						}
						$rootDSE = Get-ADRootDSE @parameters
						$storeObject = Get-ADObject @parameters -Identity "CN=NTAuthCertificates,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)" -ErrorAction Stop -Properties cACertificate
						$storedCertificates = $storeObject.cACertificate | ForEach-Object {
							[System.Security.Cryptography.X509Certificates.X509Certificate2]::new($_)
						}
						if ($testResult.Configuration.Thumbprint -notin $storedCertificates.Thumbprint)
						{
							throw "Certificate could not be applied successfully for unclarified reasons! Ensure you have the permissions needed for this operation."
						}
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -ContinueLabel main
				}
				'Remove' {
					$rootDSE = Get-ADRootDSE @parameters
					
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMNTAuthStore.Remove' -ActionStringValues $testResult.ADObject.Subject -Target $testResult -ScriptBlock {
						Set-ADObject @parameters -Identity "CN=NTAuthCertificates,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)" -Remove @{ cACertificate = $testResult.ADObject.GetRawCertData() } -ErrorAction Stop
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -ContinueLabel main
				}
			}
		}
	}
	end {
		if (Test-PSFFunctionInterrupt) { return }
		
		Remove-PSSession -Session $session -Confirm:$false -WhatIf:$false
	}
}
