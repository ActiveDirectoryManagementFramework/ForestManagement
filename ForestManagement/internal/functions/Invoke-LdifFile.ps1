function Invoke-LdifFile
{
	<#
		.SYNOPSIS
			Invokes a LDIF file against a target server / forest.
		
		.DESCRIPTION
			Invokes a LDIF file against a target server / forest.
			Note: This command assumes schema updates executed against the schema master (and will automatically switch to target that server).
			LDIF files are not technically constrained to performing schema updates however.
			Thus this function is not suitable to performing domain NC changes in a subdomain.
		
		.PARAMETER Path
			Path to the ldif file to import
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.

		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
		
		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
		
		.EXAMPLE
			PS C:\> Invoke-LdifFile -Path .\schema.ldif

			Imports the schema.ldif file into the current forest's schema.
	#>
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(Mandatory = $true)]
		[PsfValidateScript('ForestManagement.Validate.Path.SingleFile', ErrorString = 'ForestManagement.Validate.Path.SingleFile.Failed')]
		[string]
		$Path,

		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		$parameters['Server'] = (Get-ADForest @parameters).SchemaMaster
		$domain = Get-ADDomain @parameters
		
		$arguments = @()
		if ($Credential) {
			$arguments += "-b"
			$networkCredential = $Credential.GetNetworkCredential()
			$arguments += $networkCredential.UserName
			$arguments += $networkCredential.Domain
			$arguments += $networkCredential.Password
		}
		#  Load target server
		$arguments += '-s'
		$arguments += "$Server"

		# Other settings
		$arguments += '-i' # Import
		$arguments += '-k' # Ignore errors for items that already exist
		$arguments += '-c'
		$arguments += 'DC=X'
		$arguments += $domain.DistinguishedName

		# Load File
		$arguments += '-f'
		$arguments += (Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem)
	}
	process
	{
		Invoke-PSFProtectedCommand -ActionString 'Invoke-LdifFile.Invoking.File' -ActionStringValues $Path -ScriptBlock {
			$procInfo = Start-Process -FilePath ldifde.exe -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop -WindowStyle Hidden
			if ($procInfo.ExitCode) { throw (New-Object ComponentModel.Win32Exception($procInfo.ExitCode)) }
		} -EnableException $true -Target $Server -PSCmdlet $PSCmdlet
	}
}
