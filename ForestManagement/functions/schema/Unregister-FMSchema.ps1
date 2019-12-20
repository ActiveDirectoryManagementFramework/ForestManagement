function Unregister-FMSchema
{
	<#
	.SYNOPSIS
		Removes a configured schema extension.
	
	.DESCRIPTION
		Removes a configured schema extension.
	
	.PARAMETER Name
		Name(s) of the schema extensions to unregister.
	
	.EXAMPLE
		PS C:\> Unregister-FMSchema -Name $names

		Removes the list of names stored in $names from the registered schema extension configurations.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('AdminDisplayName')]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameLabel in $Name) {
			$script:schema.Remove($nameLabel)
		}
	}
}
