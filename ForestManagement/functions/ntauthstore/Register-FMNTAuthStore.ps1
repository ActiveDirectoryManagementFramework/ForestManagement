function Register-FMNTAuthStore {
	<#
		.SYNOPSIS
		Regisgter NTAuthStore certificates
		
		.DESCRIPTION
		Regisgter NTAuthStore certificates
		This is the ideal / desired state for the NTAuthStore certificate configuration.
		Forests will be brought into this state by using Invoke-FMNTAuthStore.
		
		.PARAMETER Certificate
		The certifcate to apply.
		
		.PARAMETER Authorative
		Should the NTAuthStore configuration overwrite the existing configuration, rather than adding to it (default).

		.EXAMPLE
		Register-FMNTAuthStore -Certificate $NTAuthStoreCertificate

		Register a certiciate.
		
		.EXAMPLE
		Register-FMNTAuthStore -Authorative
		
		Register the autorative state.
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