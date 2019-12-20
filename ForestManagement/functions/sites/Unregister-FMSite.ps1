function Unregister-FMSite
{
	<#
		.SYNOPSIS
			Removes a site from the list of registered sites.
		
		.DESCRIPTION
			Removes a site from the list of registered sites.
		
		.PARAMETER Name
			Name of the site to unregister
		
		.EXAMPLE
			PS C:\>  Unregister-FMSite -Name "MySite"

			Removes the site "MySite" from the list of registered sites
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $Name) {
			$script:sites.Remove($nameItem)
		}
	}
}
