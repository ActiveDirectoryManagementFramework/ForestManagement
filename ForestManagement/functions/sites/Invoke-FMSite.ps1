function Invoke-FMSite
{
	<#
		.SYNOPSIS
			Adjusts the targeted forest to comply with the site configuration.
		
		.DESCRIPTION
			Adjusts the targeted forest to comply with the site configuration.
			Use Register-FMSiteConfiguration to register configuration settings.
		
		.PARAMETER InputObject
			Test results provided by the associated test command.
			Only the provided changes will be executed, unless none were specified, in which ALL pending changes will be executed.
		
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
			PS C:\> Invoke-FMSite

			Scans the forest for discrepancies from the desired state
			Then attempts to rectify the state.
	#>
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
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
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Sites -Cmdlet $PSCmdlet
	}
	process
	{
		if (-not $InputObject) {
			$InputObject = Test-FMSite @parameters
		}

		foreach ($testItem in $InputObject) {
			switch ($testItem.Type) {
				'Delete' {
					$siteObject = Get-ADReplicationSite @parameters -Identity $testItem.Name
					$servers = Get-ADObject @parameters -LDAPFilter '(objectClass=server)' -SearchBase $siteObject.DistinguishedName
					if ($servers) {
						Write-PSFMessage -Level Warning -String 'Invoke-FMSite.Removing.Site.ChildServers' -StringValues ($servers.Name -join ", ") -Tag 'failed','sites'
					}
					else {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSite.Removing.Site' -Target $testItem.Name -ScriptBlock {
							Remove-ADReplicationSite @parameters -Identity $testItem.Name -ErrorAction Stop -Confirm:$false
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
					}
				}
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSite.Creating.Site' -Target $testItem.Name -ScriptBlock {
						New-ADReplicationSite @parameters -Name $testItem.Name -Description $testItem.Description -OtherAttributes @{ Location = $testItem.Location } -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				'Update' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSite.Updating.Site' -ActionStringValues ($testItem.Changed -join ", ") -Target $testItem.Name -ScriptBlock {
						Set-ADReplicationSite @parameters -Identity $testItem.Name -Description $testItem.Description -Replace @{ Location = $testItem.Location } -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				'Rename' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSite.Renaming.Site' -ActionStringValues $testItem.NewName -Target $testItem.Name -ScriptBlock {
						Get-ADReplicationSite @parameters -Identity $testItem.Name | Rename-ADObject @parameters -NewName $testItem.NewName
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
			}
		}
	}
}
