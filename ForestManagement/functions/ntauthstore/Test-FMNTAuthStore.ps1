function Test-FMNTAuthStore {
	<#
		.SYNOPSIS
			Tests, whether the NTAuthStore is in the desired state.
		
		.DESCRIPTION
			Tests, whether the NTAuthStore is in the desired state, that is, all defined certificates are already in place.
			Use Register-FMNTAuthStore to define desired the desired state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-FMNTAuthStore -Server contoso.com

			Checks whether the contoso.com forest has all the NTAuth certificates it should
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type ntAuthStoreCertificates -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters

		#region Utility Functions
		function New-TestResult {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory = $true)]
				[string]
				$Type,

				[Parameter(Mandatory = $true)]
				[string]
				$Identity,

				[object[]]
				$Changed,

				[Parameter(Mandatory = $true)]
				[AllowNull()]
				[PSFComputer]
				$Server,

				$Configuration,

				$ADObject
			)
	
			process {
				$object = [PSCustomObject]@{
					PSTypeName    = "ForestManagement.NTAuthStore.TestResult"
					Type          = $Type
					ObjectType    = "NTAuthStore"
					Identity      = $Identity
					Changed       = $Changed
					Server        = $Server
					Configuration = $Configuration
					ADObject      = $ADObject
				}
				Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value { $this.Identity } -Force
				$object
			}
		}
		#endregion Utility Functions

		$rootDSE = Get-ADRootDSE @parameters
		$storeObject = $null
		$storedCertificates = $null
		try {
			$storeObject = Get-ADObject @parameters -Identity "CN=NTAuthCertificates,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)" -ErrorAction Stop -Properties cACertificate
			$storedCertificates = $storeObject.cACertificate | ForEach-Object {
				[System.Security.Cryptography.X509Certificates.X509Certificate2]::new($_)
			}
			$hasStore = $storeObject -as [bool]
		}
		catch {
			$hasStore = $false
		}
	}
	process {
		$resDefault = @{
			Server = $Server
		}
		$configuredCertificates = Get-FMNTAuthStore
		foreach ($configuredCertificate in $configuredCertificates) {
			if ($storeObject) { $resDefault.ADObject = $storeObject }

			if (-not $hasStore) {
				New-TestResult @resDefault -Type 'Add' -Identity $configuredCertificate.Thumbprint -Configuration $configuredCertificate
				continue
			}

			if ($configuredCertificate.Thumbprint -notin $storedCertificates.Thumbprint) {
				New-TestResult @resDefault -Type 'Add' -Identity $configuredCertificate.Thumbprint -Configuration $configuredCertificate
				continue
			}
		}
		if (-not $hasStore) { return }
		if (-not $script:ntAuthStoreAuthorative) { return }
		
		$resDefault = @{
			Server = $Server
		}
		foreach ($storedCertificate in $storedCertificates) {
			if ($storedCertificate.Thumbprint -notin $configuredCertificates.Thumbprint) {
				New-TestResult @resDefault -Type 'Remove' -Identity $storedCertificate.Thumbprint -ADObject $storedCertificate
			}
		}
	}
}
