function Invoke-FMForestLevel
{
<#
	.SYNOPSIS
		Applies the desired forest level if needed.
	
	.DESCRIPTION
		Applies the desired forest level if needed.
	
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
		PS C:\> Invoke-FMForestLevel -Server contoso.com
	
		Raises the forest "contoso.com" to the desired level if needed.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
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
		Assert-Configuration -Type ForestLevel -Cmdlet $PSCmdlet
		Set-FMDomainContext @parameters

		# Must be executed against the Domain Naming Master
		$forest = Get-ADForest @parameters
		$parameters.Server = $forest.DomainNamingMaster
	}
	process
	{
		if (-not $InputObject) {
			$InputObject = Test-FMForestLevel @parameters
		}

		foreach ($testItem in $InputObject)
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