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

		.PARAMETER Weight
			Ldif files will be applied in a certain order.
			The weight of an Ldif file determines, the order it is applied in.
			The lower the number, the earlier the file will be applied.

			Default: 50

		.PARAMETER MissingObjectExemption
			Testing in a forest will cause it to complain about all objects the ldif file tries to modify, not create and doesn't exist.
			Using this parameter you can exempt individual classes from triggering this warning.

		.PARAMETER ContextName
			The name of the context defining the setting.
			This allows determining the configuration set that provided this setting.
			Used by the ADMF, available to any other configuration management solution.
		
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
		$Path,

		[int]
		$Weight = 50,

		[string[]]
		$MissingObjectExemption,

		[string]
		$ContextName = '<Undefined>'
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
			MissingObjectExemption = ($MissingObjectExemption | ForEach-Object { $_ -replace '(^CN=)|(^)','CN=' })
			Weight = $Weight
			ContextName = $ContextName
		}
	}
}