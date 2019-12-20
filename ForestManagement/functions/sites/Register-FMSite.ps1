function Register-FMSite
{
	<#
		.SYNOPSIS
			Register a new site configuration.
		
		.DESCRIPTION
			Register a new site configuration.
			This is the ideal / desired state for the site setup.
			Forests will be brought into this state by using Invoke-FMSite.
		
		.PARAMETER Name
			Name of the site to apply.
		
		.PARAMETER Description
			Description the site should have.
		
		.PARAMETER Location
			Location the site should be part of.
		
		.PARAMETER OldNames
			Previous names for this site.
			Forests that have a site still using one of these names will have those sites renamed.
		
		.EXAMPLE
			PS C:\> Register-FMSite -Name ABCDE -Description "Some Site" -Location 'Atlantis'

			Registers a new desired site.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Location,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$OldNames
	)
	
	process
	{
		$hashtable = @{
			PSTypeName = 'ForestManagement.Site.Configuration'
			Name = $Name
			Description = $Description
			Location = $Location
		}
		if ($OldNames) { $hashtable["OldNames"] = $OldNames }
		$script:sites[$Name] = [PSCustomObject]$hashtable
	}
}
