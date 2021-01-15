function Invoke-FMSchemaLdif
{
	<#
		.SYNOPSIS
			Applies missing LDIF files to a forest's schema.
		
		.DESCRIPTION
			Applies missing LDIF files to a forest's schema.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.

		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
		
		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
		
		.EXAMPLE
			PS C:\> Invoke-FMSchemaLdif

			Tests the configured LDIF schema files and applies all still missing updates.
	#>
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential,

		[switch]
		$EnableException
	)
	
	begin
	{
		#region Resolve Schema Master
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SchemaLdif -Cmdlet $PSCmdlet
		try {
			$forest = Get-ADForest @parameters -ErrorAction Stop
		}
		catch {
			Stop-PSFFunction -String 'Invoke-FMSchemaLdif.Connect.Failed' -StringValues $Server -ErrorRecord $_ -EnableException $EnableException -Exception $_.Exception.GetBaseException()
			return
		}
		$parameters["Server"] = $forest.SchemaMaster
		$removeParameters = $parameters.Clone()
		#endregion Resolve Schema Master

		#region Resolve Credentials
		$cred = $null
		if (Test-SchemaAdminCredential) {
			Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaLdif.Schema.Credentials' -Target $forest.SchemaMaster -ScriptBlock {
				[PSCredential]$cred = Get-SchemaAdminCredential @parameters | Write-Output | Select-Object -First 1
				if ($cred) { $parameters['Credential'] = $cred }
			} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
			if (Test-PSFFunctionInterrupt) { return }
		}
		#endregion Resolve Credentials

		# Prepare parameters to use for when discarding the schema credentials
		if ($cred -and ($cred -ne $Credential)) { $removeParameters['SchemaAccountCredential'] = $cred }

		# Grab test results to get list of items to process
		$testResult = Test-FMSchemaLdif @parameters -EnableException:$EnableException
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		foreach ($testItem in $testResult) {
			Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaLdif.Invoke.File' -ActionStringValues $testItem.Identity -Target $forest.SchemaMaster -ScriptBlock {
				Invoke-LdifFile @parameters -Path $testItem.Configuration.Path -ErrorAction Stop
			} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }

		if (Test-SchemaAdminCredential) {
			Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSchemaLdif.Schema.Credentials.Release' -Target $forest.SchemaMaster -ScriptBlock {
				Remove-SchemaAdminCredential @removeParameters -ErrorAction Stop
			} -EnableException $EnableException -PSCmdlet $PSCmdlet
		}
	}
}
