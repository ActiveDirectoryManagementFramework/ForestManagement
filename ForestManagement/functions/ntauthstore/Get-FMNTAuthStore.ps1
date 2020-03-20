function Get-FMNTAuthStore {
	<#
	.SYNOPSIS
		Returns registered NTAuthStore Certificates.
	
	.DESCRIPTION
		Returns registered NTAuthStore Certificates.
	
	.PARAMETER Thumbprint
		The thumbprint of the certificate to filter by.
	
	.PARAMETER Name
		The name of the certificate to filter by.
	
	.EXAMPLE
		PS C:\> Get-FMNTAuthStore

		Returns all registered certificates intended for the NTAuthStore
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Thumbprint = '*',

		[string]
		$Name = '*'
	)
	
	process {
		$script:ntAuthStoreCertificates.Values | Where-Object Thumbprint -like $Thumbprint | Where-Object {
			$_.Subject -like $Name -or
			$_.Subject -like "CN=$Name" -or
			$_.FriendlyName -like $Name
		}
	}
}
