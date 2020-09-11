function Test-FMForestLevel
{
<#
	.SYNOPSIS
		Tests whether the target forest has at least the desired functional level.
	
	.DESCRIPTION
		Tests whether the target forest has at least the desired functional level.
	
	.PARAMETER Server
		The server / domain to work with.
		
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Test-FMForestLevel -Server contoso.com
	
		Tests whether the forest contoso.com has at least the desired functional level.
#>
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
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
		$levelValues = @{
			'2008R2' = 4
			'2012'   = 5
			'2012R2' = 6
			'2016'   = 7
		}
		$level = Get-FMForestLevel
		$desiredLevel = $levelValues[$level.Level]
		$tempConfiguration = $level | ConvertTo-PSFHashtable
		$tempConfiguration['DesiredLevel'] = [Microsoft.ActiveDirectory.Management.ADForestMode]$desiredLevel
		$forest = Get-ADForest @parameters
		if ($forest.ForestMode -lt $desiredLevel)
		{
			New-TestResult -ObjectType ForestLevel -Type Raise -Identity $forest -Server $Server -Configuration ([pscustomobject]$tempConfiguration) -ADObject $forest
		}
	}
}
