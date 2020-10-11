function Test-FMCertificate
{
	<#
		.SYNOPSIS
			Tests, whether the certificate stores are in the desired state.
		
		.DESCRIPTION
			Tests, whether the certificate stores are in the desired state, that is, all defined certificates are already in place.
			Use Register-FMCertificate to define desired the desired state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-FMCertificate -Server contoso.com

			Checks whether the contoso.com forest has all the certificates it should
	#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type dsCertificates -Cmdlet $PSCmdlet
	}
	process
	{
		$resDefault = @{
			Server = $Server
			ObjectType = 'Certificate'
		}
		
		foreach ($type in 'NTAuthCA', 'RootCA', 'SubCA', 'CrossCA', 'KRA')
		{
			$certificates = Get-ADCertificate -Parameters $parameters -Type $type
			$desiredState = Get-FMCertificate -Type $type
			
			foreach ($desiredCert in $desiredState)
			{
				if ($desiredCert.Action -eq 'Add' -and $desiredCert.Certificate.Thumbprint -in $certificates.Thumbprint) { continue }
				if ($desiredCert.Action -eq 'Remove' -and $desiredCert.Thumbprint -notin $certificates.Thumbprint) { continue }
				
				$adObject = $null
				if ($desiredCert.Action -eq 'Remove') { $adObject = $certificates | Where-Object Thumbprint -EQ $desiredCert.Thumbprint }
				
				New-TestResult @resDefault -Type $desiredCert.Action -Identity $desiredCert -Configuration $desiredCert -ADObject $adObject
			}
			
			if (-not $script:dsCertificatesAuthorative[$type]) { continue }
			
			foreach ($certificate in $certificates)
			{
				if ($certificate.Thumbprint -in $desiredState.Certificate.Thumbprint) { continue }
				if ($certificate.Thumbprint -in $desiredState.Thumbprint) { continue }
				
				New-TestResult @resDefault -Type 'Remove' -Identity $certificate -ADObject $certificate
			}
		}
	}
}