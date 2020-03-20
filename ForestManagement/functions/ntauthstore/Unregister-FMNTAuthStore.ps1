function Unregister-FMNTAuthStore
{
	<#
	.SYNOPSIS
		Removes a certificate definition for the NTAuthStore.
	
	.DESCRIPTION
		Removes a certificate definition for the NTAuthStore.
		See Register-FMNTAuthStore tfor details on defining a certificate.
	
	.PARAMETER Thumbprint
		The thumbprint of the certificate to remove.
	
	.EXAMPLE
		PS C:\> Get-FMNTAuthStore | Unregister-FMNTAuthStore

		Clears all certificates from the list of defined NTAuth certificates
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Thumbprint
	)
	
	process
	{
		foreach ($thumbprintString in $Thumbprint) {
			$script:ntAuthStoreCertificates.Remove($thumbprintString)
		}
	}
}
