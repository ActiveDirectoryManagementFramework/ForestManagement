Set-PSFScriptblock -Name 'ForestManagement.Validate.Subnet' -Scriptblock {
    if (-not $_.Contains("/")) { return $false }
    if (($_ -split "/").Count -gt 2) { return $false }
    
    $base, $range = $_ -split "/"

    $ipv4Pattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$'
    if ($base -notmatch $ipv4Pattern) { return $false }
    
    $rangeNumber = $range -as [int]
    if (-not $rangeNumber) { return $false }
    if ($rangeNumber -lt 1) { return $false }
    if ($rangeNumber -gt 32) { return $false }
    $true
}