function Register-FMNTAuthStore {
	<#
		.SYNOPSIS
			Register NTAuthStore certificates
		
		.DESCRIPTION
			Register NTAuthStore certificates
			This is the ideal / desired state for the NTAuthStore certificate configuration.
			Forests will be brought into this state by using Invoke-FMNTAuthStore.
		
		.PARAMETER Certificate
			The certifcate to apply.
		
		.PARAMETER Authorative
			Should the NTAuthStore configuration overwrite the existing configuration, rather than adding to it (default).

		.EXAMPLE
			PS C:\> Register-FMNTAuthStore -Certificate $NTAuthStoreCertificate

			Register a certiciate.
		
		.EXAMPLE
			PS C:\> Register-FMNTAuthStore -Authorative
			
			Sets our current configuration as authorative, removing all non-listed certificates from the store.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Certificate")]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Authorative")]
		[switch]
		$Authorative		
	)
	
	process {
		switch ($pscmdlet.ParameterSetName) {
			Certificate { $script:ntAuthStoreCertificates[$Certificate.Thumbprint] = $Certificate }
			Authorative { $script:ntAuthStoreAuthorative = $Authorative.ToBool() }
		}		
	}
}