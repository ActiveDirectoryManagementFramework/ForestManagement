function Register-FMSchemaLdif
{
	<#
		.SYNOPSIS
			Registers an ldif file for validation and application.
		
		.DESCRIPTION
			Registers an ldif file for validation and application.
		
		.PARAMETER Name
			The name to register the file under.
		
		.PARAMETER Path
			The path to the file to register.
		
		.EXAMPLE
			PS C:\> Register-FMSchemaLdif -Name Skype -Path "$PSScriptRoot\skype.ldif"

			Registers the Skype for Business schema extensions.
	#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[PsfValidateScript('ForestManagement.Validate.Path.SingleFile', ErrorString = 'ForestManagement.Validate.Path.SingleFile.Failed')]
		[string]
		$Path
	)
	
	begin
	{
		$resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem
	}
	process
	{
		$script:schemaLdif[$Name] = [PSCustomObject]@{
			PSTypeName = 'ForestManagement.SchemaLdif.Configuration'
			Name = $Name
			Path = $resolvedPath
			Settings = (Import-LdifFile -Path $Path)
		}
	}
}