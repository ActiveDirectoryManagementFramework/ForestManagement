function Unregister-FMSchemaLdif
{
	<#
		.SYNOPSIS
			Removes a registered ldif file from the configured state.
		
		.DESCRIPTION
			Removes a registered ldif file from the configured state.
		
		.PARAMETER Name
			The name to select the ldif file by.
		
		.EXAMPLE
			PS C:\> Get-FMSchemaLdif | Unregister-FMSchemaLdif

			Unregisters all registered ldif files.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameLabel in $Name) {
			$script:schemaLdif.Remove($nameLabel)
		}
	}
}
