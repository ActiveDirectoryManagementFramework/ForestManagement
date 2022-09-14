function Invoke-FMSiteLink
{
	<#
		.SYNOPSIS
			Update a forest's sitelink to conform to the defined configuration.
		
		.DESCRIPTION
			Update a forest's sitelink to conform to the defined configuration.
			Configuration is defined using Register-FMSiteLink.
		
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
			PS C:\> Invoke-FMSiteLink

			Updates the current forest's sitelinks to conform to the defined configuration.
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
		#TODO: Implement Pipeline Support
		$testResult = Test-FMSiteLink @parameters
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SiteLinks -Cmdlet $PSCmdlet
	}
	process
	{
		foreach ($testItem in $testResult) {
			switch ($testItem.Type) {
				#region Delete undesired Sitelink
				'ForestOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Removing.SiteLink' -Target $testItem.Name -ScriptBlock {
						Remove-ADReplicationSiteLink @parameters -Identity $testItem.Name -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				#endregion Delete undesired Sitelink

				#region Create new Sitelink
				'ConfigurationOnly' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Creating.SiteLink' -Target $testItem.Name -ScriptBlock {
						$parametersCreate = $parameters.Clone()
						$parametersCreate += @{
							ErrorAction = 'Stop'
							Name = $testItem.Name
							Description = $testItem.Description
							Cost = $testItem.Cost
							ReplicationFrequencyInMinutes = $testItem.ReplicationInterval
							SitesIncluded = $testItem.Site1, $testItem.Site2
						}
						if ($testItem.Options) { $parametersCreate['OtherAttributes'] = @{ Options = $testItem.Options } }
						New-ADReplicationSiteLink @parametersCreate
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				#endregion Create new Sitelink

				#region Update existing Sitelink
				'InEqual' {
					if ($testItem.ADObject.Name -ne $testItem.IdealName) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Renaming.SiteLink' -ActionStringValues $testItem.IdealName -Target $testItem.Name -ScriptBlock {
							Rename-ADObject @parameters -Identity $testItem.ADObject.DistinguishedName -NewName $testItem.IdealName -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
					}

					$parametersUpdate = $parameters.Clone()
					$parametersUpdate += @{
						ErrorAction = 'Stop'
						Identity = $testItem.ADObject.ObjectGUID
					}
					if ($testItem.Cost -ne $testItem.ADObject.Cost) { $parametersUpdate['Cost'] = $testItem.Cost }
					if ($testItem.Description -ne ([string]($testItem.ADObject.Description))) { $parametersUpdate['Description'] = $testItem.Description }
					if ($testItem.Options -ne ([int]($testItem.ADObject.Options))) { $parametersUpdate['Replace'] = @{ Options = $testItem.Options } }
					if ($testItem.ReplicationInterval -ne $testItem.ADObject.replInterval) { $parametersUpdate['ReplicationFrequencyInMinutes'] = $testItem.replInterval }

					# If the only change pending was the name, don't call a meaningles Set-ADReplicationSiteLink
					if ($parametersUpdate.Keys.Count -le (2 + $parameters.Keys.Count)) { continue }

					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Updating.SiteLink' -ActionStringValues ($testItem.Changed -join ", ") -Target $testItem.Name -ScriptBlock {
						Set-ADReplicationSiteLink @parametersUpdate
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				#endregion Update existing Sitelink
			}
		}
	}
}
