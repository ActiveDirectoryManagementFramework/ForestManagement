function Register-FMSiteLink
{
	<#
	.SYNOPSIS
		Register a new sitelink configuration.
	
	.DESCRIPTION
		Register a new sitelink configuration.
	
	.PARAMETER Site1
		The first sitename in the pair of sites to be linked.
	
	.PARAMETER Site2
		The second sitename in the pair of sites to be linked.
	
	.PARAMETER Cost
		The cost of the connection between the two sites.
	
	.PARAMETER Interval
		The replication interval (in minutes) between two sites.
		Defaults to 15 minutes.
		Cannot be less than 15 minutes.
	
	.PARAMETER Description
		A description to add to the sitelink.
		For example, consider including a timestamp and the available bandwidth.
	
	.PARAMETER Option
		Any options for the sitelink.
		This is a bitmap with currently only one relevant setting:
		00000001 : Change Notify (Changes replicate instantly, rather than the configured interval. Only use for high-bandwidth connections)
	
	.EXAMPLE
		PS C:\> Register-FMSiteLink -Site1 MySite -Site2 MyOtherSite -Cost 80 -Description '2019 | 1GB/s' -Option 1

		Registers a new sitelink between MySite and MyOtherSite at a cost of 80, registering it as instant replication and adding docs on its bandwidth.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Site1,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Site2,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateRange(1,[int]::MaxValue)]
		[int]
		$Cost,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateRange(15,[int]::MaxValue)]
		[int]
		$Interval = 15,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string]
		$Description,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]
		$Option
	)
	
	process
	{
		$sitelinkName = "{0}-{1}" -f $Site1, $Site2
		$script:sitelinks[$sitelinkName] = [PSCustomObject]@{
			PSTypeName = 'ForestManagement.SiteLink.Configuration'
			Name = $sitelinkName
			Site1 = $Site1
			Site2 = $Site2
			Cost = $Cost
			Interval = $Interval
			Description = $Description
			Option = $Option
		}
	}
}
