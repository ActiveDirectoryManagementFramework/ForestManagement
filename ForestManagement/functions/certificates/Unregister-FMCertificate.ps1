function Unregister-FMCertificate
{
	<#
	.SYNOPSIS
		Removes a certificate definition for the NTAuthStore.
	
	.DESCRIPTION
		Removes a certificate definition for the NTAuthStore.
		See Register-FMCertificate tfor details on defining a certificate.
	
	.PARAMETER Thumbprint
		The thumbprint of the certificate to remove.
	
	.PARAMETER Certificate
		The certificate to remove.
	
	.EXAMPLE
		PS C:\> Get-FMCertificate | Unregister-FMCertificate

		Clears all certificates from the list of defined NTAuth certificates
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Thumbprint,
		
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.Security.Cryptography.X509Certificates.X509Certificate2[]]
		$Certificate
	)
	
	process
	{
		foreach ($thumbprintString in $Thumbprint) {
			$script:dsCertificates.Remove($thumbprintString)
		}
		foreach ($certificateObject in $Certificate)
		{
			$script:dsCertificates.Remove($certificateObject.Thumbprint)
		}
	}
}

