function Invoke-FMCertificate
{
<#
	.SYNOPSIS
		Applies the desired certificates to the NTAuth store.
	
	.DESCRIPTION
		Applies the desired certificates to the NTAuth store.
		This allows distributing certificates that are trusted across the entire forest.
	
	.PARAMETER InputObject
		The test results to apply.
		Only specify objects returned by Test-FMCertificate.
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
		PS C:\> Invoke-FMCertificate -Server contoso.com
	
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
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type dsCertificates -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters
		
		$computerName = (Get-ADDomain @parameters).PDCEmulator
		$psParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential -Inherit
		try { $session = New-PSSession @psParameter -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'Invoke-FMCertificate.WinRM.Failed' -StringValues $computerName -ErrorRecord $_ -EnableException $EnableException -Cmdlet $PSCmdlet -Target $computerName
			return
		}
		
		#region Add Certificate Scriptblock
		$addCertificateScript = {
			param (
				$Certificate
			)
			
			$certPath = "$env:temp\cert_$(Get-Random -Minimum 10000 -Maximum 99999).cer"
			
			try { $Certificate.Certificate.GetRawCertData() | Set-Content $certPath -Encoding Byte -ErrorAction Stop }
			catch
			{
				[pscustomobject]@{
					Success = $false
					Stage   = 'Writing certificate file'
					Error   = $_
				}
				return
			}
			
			$res = certutil.exe -dspublish -f $certPath $Certificate.Type 2>&1
			if ($LASTEXITCODE -gt 0)
			{
				[pscustomobject]@{
					Success = $false
					Stage   = 'Applying certificate using certutil'
					Output  = $res
				}
				Remove-Item -Path $certPath -ErrorAction Ignore
				return
			}
			Remove-Item -Path $certPath -ErrorAction Ignore
			
			[pscustomobject]@{
				Success = $true
				Stage   = 'Done'
				Output  = $null
			}
		}
		#endregion Add Certificate Scriptblock
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		# Test All Certificates if no specific test result was specified
		if (-not $InputObject)
		{
			$InputObject = Test-FMCertificate @parameters
		}
		
		:main foreach ($testResult in $InputObject)
		{
			# Catch invalid input - can only process test results
			if ($testResult.PSObject.TypeNames -notcontains 'ForestManagement.Certificate.TestResult')
			{
				Stop-PSFFunction -String 'Invoke-FMCertificate.Invalid.Input' -StringValues $testResult -Target $testResult -Continue -EnableException $EnableException
			}
			
			switch ($testResult.Type)
			{
				'Add' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMCertificate.Add' -ActionStringValues $testResult.Configuration.Certificate.Subject, $testResult.Configuration.Type -Target $testResult -ScriptBlock {
						$result = Invoke-Command -Session $session -ArgumentList $testResult.Configuration -ScriptBlock $addCertificateScript
						if (-not $result.Success)
						{
							throw "Error executing $($result.Stage) : $($result.Error)"
						}
						
						$certificates = Get-ADCertificate -Parameters $parameters -Type $testResult.Configuration.Type
						if ($testResult.Configuration.Certificate.Thumbprint -notin $certificates.Thumbprint)
						{
							throw "Certificate could not be applied successfully! Ensure you have the permissions needed for this operation. Certutil output:`n$($result.Output)"
						}
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -ContinueLabel main
				}
				'Remove' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMCertificate.Remove' -ActionStringValues $testResult.ADObject.Subject, $testResult.ADObject.ADObject -Target $testResult -ScriptBlock {
						try { Set-ADObject @parameters -Identity $testResult.ADObject.ADObject -Remove @{ $testResult.ADObject.AttributeName = $testResult.ADObject.Certificate.GetRawCertData() } -ErrorAction Stop }
						catch
						{
							if ($_.Exception.ErrorCode -eq 8316) { Remove-ADObject @parameters -Identity $testResult.ADObject.ADObject -ErrorAction Stop -Confirm:$false }
							else { throw }
						}
						
						if ($testResult.ADObject.AltADObject)
						{
							try { Set-ADObject @parameters -Identity $testResult.ADObject.AltADObject -Remove @{ $testResult.ADObject.AttributeName = $testResult.ADObject.Certificate.GetRawCertData() } -ErrorAction Stop }
							catch
							{
								if ($_.Exception.ErrorCode -eq 8316) { Remove-ADObject @parameters -Identity $testResult.ADObject.AltADObject -ErrorAction Stop -Confirm:$false }
								else { throw }
							}
						}
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -ContinueLabel main
				}
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		Remove-PSSession -Session $session -Confirm:$false -WhatIf:$false
	}
}

