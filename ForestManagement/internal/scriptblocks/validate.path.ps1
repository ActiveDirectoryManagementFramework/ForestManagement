Set-PSFScriptblock -Name 'ForestManagement.Validate.Path.SingleFile' -Scriptblock {
    try {
        Resolve-PSFPath -Path $_ -Provider FileSystem -SingleItem
        return $true
    }
    catch { return $false }
}