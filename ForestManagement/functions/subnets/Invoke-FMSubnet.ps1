function Invoke-FMSubnet
{
	<#
		.SYNOPSIS
			Corrects the subnet configuration of a forest.
		
		.DESCRIPTION
			Corrects the subnet configuration of a forest.
		
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
			PS C:\> Invoke-FMSubnet

			Corrects the subnet configuration of the current forest.
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
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Subnets -Cmdlet $PSCmdlet
		$testResult = Test-FMSubnet @parameters | Sort-Object {
			switch ($_.Type) {
				'ForestOnly' { 1 }
				'InEqual' { 2 }
				default { 3 }
			}
		}
	}
	process
	{
		#TODO: Implement Pipeline Support
		foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				'ForestOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSubnet.Deleting.Subnet' -Target $testItem.Name -ScriptBlock {
						Remove-ADReplicationSubnet @parameters -Identity $testItem.Name -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				'ConfigurationOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSubnet.Creating.Subnet' -Target $testItem.Name -ScriptBlock {
						New-ADReplicationSubnet @parameters -Name $testItem.Name -Site $testItem.SiteName -Description $testItem.Description -Location $testItem.Location -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				'InEqual' {
					$parametersSetSplat = $parameters.Clone()
					$parametersSetSplat['Identity'] = $testItem.Identity
					if ($testItem.SiteName -ne $testItem.ADObject.SiteName) { $parametersSetSplat['Site'] = $testItem.SiteName }
					if ($testItem.Description -ne ([string]($testItem.ADObject.Description))) { $parametersSetSplat['Description'] = $testItem.Description }
					if ($testItem.Location -ne ([string]($testItem.ADObject.Location))) { $parametersSetSplat['Location'] = $testItem.Location }

					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSubnet.Updating.Subnet' -ActionStringValues ($testItem.Changed -join ", ") -Target $testItem.Name -ScriptBlock {
						Set-ADReplicationSubnet @parametersSetSplat -ErrorAction Stop
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
			}
		}
	}
}
