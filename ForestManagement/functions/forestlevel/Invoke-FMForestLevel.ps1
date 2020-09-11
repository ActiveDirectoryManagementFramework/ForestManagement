function Invoke-FMForestLevel
{
<#
	.SYNOPSIS
		Applies the desired forest level if needed.
	
	.DESCRIPTION
		Applies the desired forest level if needed.
	
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
		PS C:\> Invoke-FMForestLevel -Server contoso.com
	
		Raises the forest "contoso.com" to the desired level if needed.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
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
		Assert-Configuration -Type ForestLevel -Cmdlet $PSCmdlet
	}
	process
	{
		foreach ($testItem in Test-FMForestLevel @parameters)
		{
			switch ($testItem.Type)
			{
				'Raise'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-FMForestLevel.Raise.Level' -ActionStringValues $testItem.Configuration.Level -Target $testItem.ADObject -ScriptBlock {
						Set-ADForestMode @parameters -ForestMode $testItem.Configuration.DesiredLevel -Identity $testItem.ADObject -ErrorAction Stop -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
			}
		}
	}
}