function Unregister-FMSiteLink
{
	<#
		.SYNOPSIS
			Removes a link between two sites from configuration.
		
		.DESCRIPTION
			Removes a link between two sites from configuration.
		
		.PARAMETER Site1
			The site1 of the link.
		
		.PARAMETER Site2
			The site2 of the link.
		
		.EXAMPLE
			PS C:\> Unregister-FMSiteLink -Site1 MySite -Site2 MyOtherSite

			Removes a sitelink from configuration.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Site1,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Site2
	)
	
	process
	{
		$sitelinkName = "{0}-{1}" -f $Site1, $Site2
		$sitelinkName2 = "{1}-{0}" -f $Site1, $Site2
		$script:sitelinks.Remove($sitelinkName)
		$script:sitelinks.Remove($sitelinkName2)
	}
}
