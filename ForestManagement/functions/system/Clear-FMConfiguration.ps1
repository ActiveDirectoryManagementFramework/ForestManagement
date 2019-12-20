function Clear-FMConfiguration
{
	<#
		.SYNOPSIS
			Clears the stored configuration data.
		
		.DESCRIPTION
			Clears the stored configuration data.
		
		.EXAMPLE
			PS C:\> Clear-FMConfiguration

			Clears the stored configuration data.
	#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		# Site Configurations
		$script:sites = @{ }

		# Subnet Configurations
		$script:subnets = @{ }

		# Sitelink Configurations
		$script:sitelinks = @{ }

		# Schema Definition
		$script:schema = @{ }

		# Schema Definitions for external LDIF files
		$script:schemaLdif = @{ }
	}
}
