function Get-FMSite
{
<#
.SYNOPSIS
	Returns the list of configured sites.

.DESCRIPTION
	Returns the list of configured sites.
	Sites can be configured using Register-FMSite.
	Those configurations represent the "Should be" state as defined for the entire organization.

.PARAMETER Name
	Name to filter by.
	Defaults to "*"

.EXAMPLE
	PS C:\> Get-FMSite

	Returns all configured sites.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = "*"
	)
	
	process
	{
		($script:sites.Values | Where-Object Name -like $Name)
	}
}
