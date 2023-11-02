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
		$domainObject = Get-ADDomain @parameters
		
		$arguments = @()
		if ($Credential) {
			$arguments += "-b"
			$networkCredential = $Credential.GetNetworkCredential()
			$userName = $networkCredential.UserName
			$domain = $networkCredential.Domain
			if (-not $domain -and $userName -match '@') {
				$userName, $domain = $userName -split '@',2
			}
			$arguments += $userName
			if ($domain) { $arguments += $domain }
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
		$arguments += $domainObject.DistinguishedName

		# Load File
		$arguments += '-f'
		$arguments += (Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem)
	}
	process
	{
		Invoke-PSFProtectedCommand -ActionString 'Invoke-LdifFile.Invoking.File' -ActionStringValues $Path -ScriptBlock {
			$procInfo = Start-Process -FilePath ldifde.exe -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop -WindowStyle Hidden
			if ($procInfo.ExitCode) {
				$winError = [System.ComponentModel.Win32Exception]::new($procInfo.ExitCode)
				switch ($procInfo.ExitCode) {
					8224 { $outerError = [System.InvalidOperationException]::new("Failed to apply ldif file. Validate domain health, especially FSMO assignment and replication health. $($winError.Message)", $winError) }
					default { $outerError = [System.InvalidOperationException]::new("Failed to apply ldif file: $($winError.Message)", $winError) }
				}
				throw $outerError
			}
		} -EnableException $true -Target $Server -PSCmdlet $PSCmdlet
	}
}
