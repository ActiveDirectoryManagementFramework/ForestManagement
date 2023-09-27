function Register-FMCertificate {
	<#
		.SYNOPSIS
			Register directory services certificates
		
		.DESCRIPTION
			Register directory services certificates
		
		.PARAMETER Certificate
			The certifcate to apply.
	
		.PARAMETER Type
			The kind of certificate this is.
			Can be: NTAuthCA, RootCA, SubCA, CrossCA or KRA.
		
		.PARAMETER Authorative
			Should the certificate configuration overwrite the existing configuration, rather than adding to it (default).
	
		.PARAMETER Remove
			Thumbprint of a certificate to remove rather than add.

		.PARAMETER ContextName
			The name of the context defining the setting.
			This allows determining the configuration set that provided this setting.
			Used by the ADMF, available to any other configuration management solution.

		.EXAMPLE
			PS C:\> Register-FMCertificate -Certificate $certificate -Type RootCA

			Register a certiciate as RootCA certificate.
		
		.EXAMPLE
			PS C:\> Register-FMCertificate -Authorative -Type RootCA
			
			Sets our current configuration as authorative, removing all non-listed certificates from the store.
	
		.EXAMPLE
			PS C:\> Register-FMCertificate -Remove $cert.Thumbprint -Type SubCA
	
			Registers a certificate for removal from the SubCA list.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('NTAuthCA', 'RootCA', 'SubCA', 'CrossCA', 'KRA')]
		[string]
		$Type,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Certificate")]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Authorative")]
		[bool]
		$Authorative,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Remove')]
		[string]
		$Remove,

		[string]
		$ContextName = '<Undefined>'
	)
	
	process {
		switch ($pscmdlet.ParameterSetName) {
			Certificate {
				$object = [pscustomobject]@{
					Certificate = $Certificate
					Type        = $Type
					Action      = 'Add'
					ContextName = $ContextName
				}
				Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value {
					'+ {0} > {1}' -f $this.Type, $this.Certificate.Subject
				} -Force
				$script:dsCertificates[$Certificate.Thumbprint] = $object
			}
			Authorative { $script:dsCertificatesAuthorative[$Type] = $Authorative }
			Remove {
				$object = [pscustomobject]@{
					Thumbprint  = $Remove
					Type        = $Type
					Action      = 'Remove'
					ContextName = $ContextName
				}
				Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value {
					'- {0} > {1}' -f $this.Type, $this.Thumbprint
				} -Force
				$script:dsCertificates[$Remove] = $object
			}
		}
	}
}
