function Unregister-FMSubnet
{
	<#
		.SYNOPSIS
			Removes a subnet mapping.
		
		.DESCRIPTION
			Removes a subnet mapping.
		
		.PARAMETER Name
			Name of the subnets to unregister
		
		.EXAMPLE
			PS C:\>  Unregister-FMSubnet -Name "1.2.3.4/32"

			Removes the subnet "1.2.3.4/32"
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameItem in $SiteName) {
			$script:subnets.Remove($nameItem)
		}
	}
}
