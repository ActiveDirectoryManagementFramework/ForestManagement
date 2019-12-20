function Invoke-FMServer
{
	<#
	.SYNOPSIS
		Ensures domain controllers are assigned to sites suitable for their IP addresses.
	
	.DESCRIPTION
		Ensures domain controllers are assigned to sites suitable for their IP addresses.
	
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
		PS C:\> Invoke-FMServer

		Ensures all domain controllers in the current forest are in the correct site.
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
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		$testResult = Test-FMServer @parameters
	}
	process
	{
		foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				'AddressNotFound'
				{
					if (-not $testItem.ADObject.DNSHostName) {
						Write-PSFMessage -Level Warning -String 'Invoke-FMServer.Server.NotFound' -StringValues $testItem.Identity -Target $testItem.Identity
					}
					else {
						Write-PSFMessage -Level Warning -String 'Invoke-FMServer.Server.FailedToResolve' -StringValues $testItem.Identity -Target $testItem.Identity
					}
				}
				'NoMatchingSubnet'
				{
					Write-PSFMessage -Level Warning -String 'Invoke-FMServer.Server.NoSubnet' -StringValues $testItem.Identity, $testItem.ADObject.IPAddress -Target $testItem.Identity
				}
				'BadSite'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMServer.Server.Moving' -ActionStringValues $testItem.SupposedSite -Target $testItem.Identity -ScriptBlock {
						Move-ADDirectoryServer @parameters -Identity $testItem.ADobject.DistinguishedName -Site $testItem.SupposedSite -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
			}
		}
	}
}
