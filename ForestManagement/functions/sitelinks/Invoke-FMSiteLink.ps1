function Invoke-FMSiteLink {
	<#
		.SYNOPSIS
			Update a forest's sitelink to conform to the defined configuration.
		
		.DESCRIPTION
			Update a forest's sitelink to conform to the defined configuration.
			Configuration is defined using Register-FMSiteLink.
		
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
			PS C:\> Invoke-FMSiteLink

			Updates the current forest's sitelinks to conform to the defined configuration.
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
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type SiteLinks -Cmdlet $PSCmdlet
	}
	process {
		if (-not $InputObject) {
			$InputObject = Test-FMSiteLink @parameters
		}
		
		foreach ($testItem in $InputObject) {
			switch ($testItem.Type) {
				#region Delete undesired Sitelink
				'Delete' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Removing.SiteLink' -Target $testItem.Name -ScriptBlock {
						Remove-ADReplicationSiteLink @parameters -Identity $testItem.Name -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				#endregion Delete undesired Sitelink

				#region Create new Sitelink
				'Create' {
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Creating.SiteLink' -Target $testItem.Name -ScriptBlock {
						$parametersCreate = $parameters.Clone()
						$parametersCreate += @{
							ErrorAction                   = 'Stop'
							Name                          = $testItem.Name
							Description                   = $testItem.Description
							Cost                          = $testItem.Cost
							ReplicationFrequencyInMinutes = $testItem.ReplicationInterval
							SitesIncluded                 = $testItem.Site1, $testItem.Site2
						}
						if ($testItem.Options) { $parametersCreate['OtherAttributes'] = @{ Options = $testItem.Options } }
						New-ADReplicationSiteLink @parametersCreate
					} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
				}
				#endregion Create new Sitelink

				#region Update existing Sitelink
				'Update' {
					if ($testItem.ADObject.Name -ne $testItem.IdealName) {
						Invoke-PSFProtectedCommand -ActionString 'Invoke-FMSiteLink.Renaming.SiteLink' -ActionStringValues $testItem.IdealName -Target $testItem.Name -ScriptBlock {
							Rename-ADObject @parameters -Identity $testItem.ADObject.DistinguishedName -NewName $testItem.IdealName -ErrorAction Stop
						} -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
					}

					$parametersUpdate = $parameters.Clone()
					$parametersUpdate += @{
						ErrorAction = 'Stop'
						Identity    = $testItem.ADObject.ObjectGUID
					}
					foreach ($change in $testItem.Changed) {
						switch ($change.Property) {
							'Cost' { $parametersUpdate['Cost'] = $change.NewValue }
							'Description' { $parametersUpdate['Description'] = $change.NewValue }
							'Options' { $parametersUpdate['Replace'] = @{ Options = $change.NewValue } }
							'ReplicationInterval' { $parametersUpdate['ReplicationFrequencyInMinutes'] = $change.NewValue }
						}
					}

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