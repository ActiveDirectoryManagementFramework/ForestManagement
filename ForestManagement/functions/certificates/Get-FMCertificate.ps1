function Get-FMCertificate {
	<#
	.SYNOPSIS
		Returns registered Certificates.
	
	.DESCRIPTION
		Returns registered Certificates.
	
	.PARAMETER Thumbprint
		The thumbprint of the certificate to filter by.
	
	.PARAMETER Name
		The name of the certificate to filter by.
	
	.PARAMETER Type
		The type of certificate to look for
	
	.EXAMPLE
		PS C:\> Get-FMCertificate

		Returns all registered certificates intended for any of the forest certificate stores
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	Param (
		[string]
		$Thumbprint = '*',

		[string]
		$Name = '*',
		
		[string]
		$Type = '*'
	)
	
	process {
		($script:dsCertificates.Values) | Where-Object { $_.Certificate.Thumbprint -like $Thumbprint } | Where-Object {
			$_.Certificate.Subject -like $Name -or
			$_.Certificate.Subject -like "CN=$Name" -or
			$_.Certificate.FriendlyName -like $Name
		} | Where-Object Type -Like $Type
	}
}

