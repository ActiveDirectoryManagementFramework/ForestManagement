function Get-FMSiteLink
{
	<#
	.SYNOPSIS
		Returns the configured link between two sites.
	
	.DESCRIPTION
		Returns the configured link between two sites.
	
	.PARAMETER SiteName
		The site to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-FMSiteLink

		Returns all configured sitelinks.
	#>
	[CmdletBinding()]
	Param (
		[string]
		$SiteName = "*"
	)
	
	process
	{
		($script:sitelinks.Values | Where-Object {
			($_.Site1 -like $SiteName) -or ($_.Site2 -like $SiteName)
		})
	}
}
