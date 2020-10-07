function Get-Certificate
{
<#
	.SYNOPSIS
		Returns forest certificates.
	
	.DESCRIPTION
		Returns forest certificates.
	
	.PARAMETER Parameters
		Hashtable containing AD connection values.
		May contain Server and Credential nodes but nothing else.
	
	.PARAMETER Type
		The kind of certificate to retrieve
	
	.EXAMPLE
		PS C:\> Get-Certificate -Parameters $parameters -Type NTAuthCA
	
		Returns all NTAuth certificates in the targeted forest.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Parameters,
		
		[Parameter(Mandatory = $true)]
		[ValidateSet('NTAuthCA', 'RootCA', 'SubCA', 'CrossCA', 'KRA')]
		[string]
		$Type
	)
	
	begin
	{
		#region Utility Functions
		function Get-CertificateInternal
		{
			[CmdletBinding()]
			param (
				[string]
				$Object,
				
				[string]
				$Path,
				
				[string]
				$AltPath,
				
				[string]
				$NotInPath,
				
				[string]
				$AttributeName = 'cACertificate',
				
				[System.Collections.Hashtable]
				$Parameters
			)
			
			#region Single Object Processing
			if ($Object -eq 'Single')
			{
				try { $adObject = Get-ADObject @Parameters -Identity $Path -ErrorAction Stop -Properties $AttributeName }
				catch { return } # Object doesn't exist
				
				foreach ($certData in $adObject.$AttributeName)
				{
					$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certData)
					[pscustomobject]@{
						Certificate = $certificate
						Subject	    = $certificate.Subject
						Thumbprint  = $certificate.Thumbprint
						ADObject    = $adObject
						AltADObject = $null
						AttributeName = $AttributeName
					} | Add-Member -MemberType ScriptMethod -Name ToString -Value { '{0} (<{1:yyyy-MM-dd})' -f $this.Subject, $this.Certificate.NotAfter } -Force -PassThru
				}
				return
			}
			#endregion Single Object Processing
			
			$adObjects = Get-ADObject @Parameters -SearchBase $Path -SearchScope OneLevel -Filter * -ErrorAction Stop -Properties $AttributeName
			$existingCerts = foreach ($adObject in $adObjects)
			{
				foreach ($certData in $adObject.$AttributeName)
				{
					if (-not $certData) { continue }
					$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certData)
					[pscustomobject]@{
						Certificate = $certificate
						Subject	    = $certificate.Subject
						Thumbprint  = $certificate.Thumbprint
						ADObject    = $adObject
						AltADObject = $null
						AttributeName = $AttributeName
					} | Add-Member -MemberType ScriptMethod -Name ToString -Value { '{0} (<{1:yyyy-MM-dd})' -f $this.Subject, $this.Certificate.NotAfter } -Force -PassThru
				}
			}
			
			#region AltPath
			# Contained in the original container and ALSO in the alternative container (e.g. RootCA Certificate)
			if ($AltPath)
			{
				$altAdObjects = Get-ADObject @Parameters -SearchBase $AltPath -SearchScope OneLevel -Filter * -ErrorAction Stop -Properties $AttributeName
				foreach ($adObject in $altAdObjects)
				{
					$certificates = foreach ($certData in $adObject.$AttributeName)
					{
						if (-not $certData) { continue }
						[System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certData)
					}
					foreach ($existingCert in $existingCerts)
					{
						if ($existingCert.Thumbprint -notin $certificates.Thumbprint) { continue }
						$existingCert.AltADObject = $adObject
					}
				}
				$existingCerts = $existingCerts | Where-Object AltADObject
			}
			#endregion AltPath
			
			#region NotInPath
			# Contained in the original container and NOT in the alternative container (e.g. SubCA Certificate)
			if ($NotInPath)
			{
				$notInAdObjects = Get-ADObject @Parameters -SearchBase $NotInPath -SearchScope OneLevel -Filter * -ErrorAction Stop -Properties $AttributeName
				$certificates = foreach ($adObject in $notInAdObjects)
				{
					foreach ($certData in $adObject.$AttributeName)
					{
						if (-not $certData) { continue }
						[System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certData)
					}
				}
				$existingCerts = $existingCerts | Where-Object Thumbprint -NotIn $certificates.Thumbprint
			}
			#endregion NotInPath
			
			$existingCerts
		}
		#endregion Utility Functions
		
		$rootDSE = Get-ADRootDSE @parameters
		
		$mapping = @{
			NTAuthCA = @{
				Object = 'Single'
				Path   = "CN=NTAuthCertificates,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
			}
			RootCA   = @{
				Object = 'Multi'
				Path   = "CN=Certification Authorities,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
				AltPath = "CN=AIA,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
			}
			SubCA    = @{
				Object = 'Multi'
				Path   = "CN=AIA,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
				NotInPath = "CN=Certification Authorities,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
			}
			CrossCA  = @{
				Object = 'Multi'
				Path   = "CN=AIA,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
				AttributeName = 'crossCertificatePair'
			}
			KRA	     = @{
				Object = 'Multi'
				Path   = "CN=KRA,CN=Public Key Services,CN=Services,$($rootDSE.configurationNamingContext)"
				AttributeName = 'userCertificate'
			}
		}
	}
	process
	{
		$table = $mapping[$type]
		Get-CertificateInternal -Parameters $parameters @table
	}
}