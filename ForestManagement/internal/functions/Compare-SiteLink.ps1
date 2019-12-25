function Compare-SiteLink
{
	<#
	.SYNOPSIS
		Compares two sitelink objects.
	
	.DESCRIPTION
		Compares two sitelink objects.
		Returns the DifferenceSiteLink if it uses the same sites as the reference sitelink, no matter the order.
	
	.PARAMETER ReferenceSiteLink
		The sitelink to compare to input with.
	
	.PARAMETER DifferenceSiteLink
		The sitelink(s) to compare.
	
	.EXAMPLE
		$script:sitelinks.Values | Compare-SiteLink $refSiteLink

		Returns any registered sitelinks that span the same sites as $refSiteLink (Should never be more than 1!)
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0)]
		$ReferenceSiteLink,

		[Parameter(ValueFromPipeline = $true)]
		$DifferenceSiteLink
	)
	
	process
	{
		foreach ($diffSiteLink in $DifferenceSiteLink) {
			if (($diffSiteLink.Site1 -eq $ReferenceSiteLink.Site1) -and ($diffSiteLink.Site2 -eq $ReferenceSiteLink.Site2)) {
				$diffSiteLink
				continue
			}
			if (($diffSiteLink.Site1 -eq $ReferenceSiteLink.Site2) -and ($diffSiteLink.Site2 -eq $ReferenceSiteLink.Site1)) {
				$diffSiteLink
				continue
			}
		}
	}
}
