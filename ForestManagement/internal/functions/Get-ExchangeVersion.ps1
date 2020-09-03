function Get-ExchangeVersion
{
<#
	.SYNOPSIS
		Return Exchange Version Information.
	
	.DESCRIPTION
		Return Exchange Version Information.
	
	.PARAMETER Binding
		The Binding to use.
	
	.PARAMETER Name
		The name to filter by.
	
	.EXAMPLE
		PS C:\> Get-ExchangeVersion
	
		Return a list of all Exchange Versions
#>
	[CmdletBinding()]
	param (
		[string]
		$Binding,
		
		[string]
		$Name = '*'
	)
	
	begin
	{
		# Useful source: https://eightwone.com/references/schema-versions/
		$versionMapping = @{
			'2013RTM' = [PSCustomObject]@{ Name = 'Exchange 2013 RTM'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15449; RangeUpper = 15137; Binding = '2013RTM' }
			'2013CU1' = [PSCustomObject]@{ Name = 'Exchange 2013 CU1'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15614; RangeUpper = 15254; Binding = '2013CU1' }
			'2013CU2' = [PSCustomObject]@{ Name = 'Exchange 2013 CU2'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15688; RangeUpper = 15281; Binding = '2013CU2' }
			'2013CU3' = [PSCustomObject]@{ Name = 'Exchange 2013 CU3'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15763; RangeUpper = 15283; Binding = '2013CU3' }
			'2013SP1' = [PSCustomObject]@{ Name = 'Exchange 2013 SP1'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15844; RangeUpper = 15292; Binding = '2013SP1' }
			'2013CU5' = [PSCustomObject]@{ Name = 'Exchange 2013 CU5'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15870; RangeUpper = 15300; Binding = '2013CU5' }
			'2013CU6' = [PSCustomObject]@{ Name = 'Exchange 2013 CU6'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15965; RangeUpper = 15303; Binding = '2013CU6' }
			'2013CU7' = [PSCustomObject]@{ Name = 'Exchange 2013 CU7'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15965; RangeUpper = 15312; Binding = '2013CU7' }
			'2013CU8' = [PSCustomObject]@{ Name = 'Exchange 2013 CU8'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15965; RangeUpper = 15312; Binding = '2013CU8' }
			'2013CU9' = [PSCustomObject]@{ Name = 'Exchange 2013 CU9'; ObjectVersionDefault = 13236; ObjectVersionConfig = 15965; RangeUpper = 15312; Binding = '2013CU9' }
			'2013CU10' = [PSCustomObject]@{ Name = 'Exchange 2013 CU10'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU10' }
			'2013CU11' = [PSCustomObject]@{ Name = 'Exchange 2013 CU11'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU11' }
			'2013CU12' = [PSCustomObject]@{ Name = 'Exchange 2013 CU12'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU12' }
			'2013CU13' = [PSCustomObject]@{ Name = 'Exchange 2013 CU13'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU13' }
			'2013CU14' = [PSCustomObject]@{ Name = 'Exchange 2013 CU14'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU14' }
			'2013CU15' = [PSCustomObject]@{ Name = 'Exchange 2013 CU15'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU15' }
			'2013CU16' = [PSCustomObject]@{ Name = 'Exchange 2013 CU16'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU16' }
			'2013CU17' = [PSCustomObject]@{ Name = 'Exchange 2013 CU17'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU17' }
			'2013CU18' = [PSCustomObject]@{ Name = 'Exchange 2013 CU18'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU18' }
			'2013CU19' = [PSCustomObject]@{ Name = 'Exchange 2013 CU19'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU19' }
			'2013CU20' = [PSCustomObject]@{ Name = 'Exchange 2013 CU20'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU20' }
			'2013CU21' = [PSCustomObject]@{ Name = 'Exchange 2013 CU21'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16130; RangeUpper = 15312; Binding = '2013CU21' }
			'2013CU22' = [PSCustomObject]@{ Name = 'Exchange 2013 CU22'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16131; RangeUpper = 15312; Binding = '2013CU22' }
			'2013CU23' = [PSCustomObject]@{ Name = 'Exchange 2013 CU23'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16133; RangeUpper = 15312; Binding = '2013CU23' }
			'2016Preview' = [PSCustomObject]@{ Name = 'Exchange 2016 Preview'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16041; RangeUpper = 15317; Binding = '2016Preview' }
			'2016RTM' = [PSCustomObject]@{ Name = 'Exchange 2016 RTM'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16210; RangeUpper = 15317; Binding = '2016RTM' }
			'2016CU1' = [PSCustomObject]@{ Name = 'Exchange 2016 CU1'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16211; RangeUpper = 15323; Binding = '2016CU1' }
			'2016CU2' = [PSCustomObject]@{ Name = 'Exchange 2016 CU2'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16212; RangeUpper = 15325; Binding = '2016CU2' }
			'2016CU3' = [PSCustomObject]@{ Name = 'Exchange 2016 CU3'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16212; RangeUpper = 15326; Binding = '2016CU3' }
			'2016CU4' = [PSCustomObject]@{ Name = 'Exchange 2016 CU4'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15326; Binding = '2016CU4' }
			'2016CU5' = [PSCustomObject]@{ Name = 'Exchange 2016 CU5'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15326; Binding = '2016CU5' }
			'2016CU6' = [PSCustomObject]@{ Name = 'Exchange 2016 CU6'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15330; Binding = '2016CU6' }
			'2016CU7' = [PSCustomObject]@{ Name = 'Exchange 2016 CU7'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15332; Binding = '2016CU7' }
			'2016CU8' = [PSCustomObject]@{ Name = 'Exchange 2016 CU8'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15332; Binding = '2016CU8' }
			'2016CU9' = [PSCustomObject]@{ Name = 'Exchange 2016 CU9'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15332; Binding = '2016CU9' }
			'2016CU10' = [PSCustomObject]@{ Name = 'Exchange 2016 CU10'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15332; Binding = '2016CU10' }
			'2016CU11' = [PSCustomObject]@{ Name = 'Exchange 2016 CU11'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16214; RangeUpper = 15332; Binding = '2016CU11' }
			'2016CU12' = [PSCustomObject]@{ Name = 'Exchange 2016 CU12'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16215; RangeUpper = 15332; Binding = '2016CU12' }
			'2016CU13' = [PSCustomObject]@{ Name = 'Exchange 2016 CU13'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16217; RangeUpper = 15332; Binding = '2016CU13' }
			'2016CU14' = [PSCustomObject]@{ Name = 'Exchange 2016 CU14'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16217; RangeUpper = 15332; Binding = '2016CU14' }
			'2016CU15' = [PSCustomObject]@{ Name = 'Exchange 2016 CU15'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16217; RangeUpper = 15332; Binding = '2016CU15' }
			'2016CU16' = [PSCustomObject]@{ Name = 'Exchange 2016 CU16'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16217; RangeUpper = 15332; Binding = '2016CU16' }
			'2016CU17' = [PSCustomObject]@{ Name = 'Exchange 2016 CU17'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16217; RangeUpper = 15332; Binding = '2016CU17' }
			'2019Preview' = [PSCustomObject]@{ Name = 'Exchange 2019 Preview'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16213; RangeUpper = 15332; Binding = '2019Preview' }
			'2019RTM' = [PSCustomObject]@{ Name = 'Exchange 2019 RTM'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16751; RangeUpper = 17000; Binding = '2019RTM' }
			'2019CU1' = [PSCustomObject]@{ Name = 'Exchange 2019 CU1'; ObjectVersionDefault = 13236; ObjectVersionConfig = 16752; RangeUpper = 17000; Binding = '2019CU1' }
			'2019CU2' = [PSCustomObject]@{ Name = 'Exchange 2019 CU2'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16754; RangeUpper = 17001; Binding = '2019CU2' }
			'2019CU3' = [PSCustomObject]@{ Name = 'Exchange 2019 CU3'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16754; RangeUpper = 17001; Binding = '2019CU3' }
			'2019CU4' = [PSCustomObject]@{ Name = 'Exchange 2019 CU4'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16754; RangeUpper = 17001; Binding = '2019CU4' }
			'2019CU5' = [PSCustomObject]@{ Name = 'Exchange 2019 CU5'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16754; RangeUpper = 17001; Binding = '2019CU5' }
			'2019CU6' = [PSCustomObject]@{ Name = 'Exchange 2019 CU6'; ObjectVersionDefault = 13237; ObjectVersionConfig = 16754; RangeUpper = 17001; Binding = '2019CU6' }
		}
	}
	process
	{
		if ($Binding) { return $versionMapping[$Binding] }
		$versionMapping.Values | Where-Object Name -Like $Name
	}
}