function ConvertTo-SchemaLdifPhase
{
    <#
    .SYNOPSIS
        Converts ldif files into a phased state index.

    .DESCRIPTION
        Converts ldif files into a phased state index.
        For each phase/file for each object it calculates the resulting state after ALL commands in the file have been executed.
        This allows stepping through the individual ldif files in the order they are to be applied and figure out the last applied deployment state.
        
    .PARAMETER LdifData
        The set of Ldif file definitions as returned by Get-FMSchemaLdif

    .EXAMPLE
        PS C:\> $ldifPhases = ConvertTo-SchemaLdifPhase -LdifData (Get-FMSchemaLdif)

        Returns the hashtable containing the different phases of all registered ldif files.
	#>
	[OutputType([Hashtable])]
    [CmdletBinding()]
    param (
        $LdifData
    )

    #region Utility Functions
    function Add-Node {
        [CmdletBinding()]
        param (
            [string]
            $DistinguishedName,

            [string]
            $LdifName,

            [Hashtable]
            $MappingTable
        )

        if (-not $MappingTable.ContainsKey($DistinguishedName)) {
            $MappingTable[$DistinguishedName] = @{ }
        }
        if (-not $MappingTable[$DistinguishedName][$LdifName]) {
            $MappingTable[$DistinguishedName][$LdifName] = @{
                State = @{ }
                Add = @{ }
                Replace = @{ }
            }
        }
    }
    function Write-Change {
        [CmdletBinding()]
        param (
            [string]
            $DistinguishedName,

            [string]
            $LdifName,

            $Change,

            [Hashtable]
            $MappingTable
        )

        Add-Node -DistinguishedName $DistinguishedName -LdifName $LdifName -MappingTable $MappingTable
        $datasheet = $MappingTable[$DistinguishedName][$LdifName]

        switch -regex ($Change.changetype) {
            'add' {
                $datasheet.State = @{ }
                foreach ($propertyName in $Change.PSObject.Properties.Name) {
                    if ($propertyName -in 'changeType', 'FM_OrderCount') { continue }
                    $datasheet.State[$propertyName] = $Change.$propertyName
                }
            }
            'modify' {
                #region We already have a defined state
                if ($datasheet.State.Count -gt 0) {
                    if ($Change.add) {
                        if ($datasheet.State.$($Change.add)) {
                            $datasheet.State.$($Change.add) = @($datasheet.State.$($Change.add)) + @($Change.$($Change.add))
                        }
                        else {
                            $datasheet.State[$Change.add] = $Change.$($Change.add)
                        }
                    }
                    elseif ($Change.replace) {
                        $datasheet.State[$Change.replace] = $Change.$($Change.replace)
                    }
                    else {
                        foreach ($propertyName in $Change.PSObject.Properties.Name) {
                            if ($propertyName -in 'DistinguishedName','changetype','FM_OrderCount') { continue }
                            $datasheet.State[$propertyName] = $Change.$propertyName
                        }
                    }
                }
                #endregion We already have a defined state

                #region Undefined state
                else {
                    if ($Change.add) {
                        if ($datasheet.Add.$($Change.add)) {
                            $datasheet.Add.$($Change.add) = @($datasheet.Add.$($Change.add)) + @($Change.$($Change.add))
                        }
                        else {
                            $datasheet.Add[$Change.add] = $Change.$($Change.add)
                        }
                    }
                    elseif ($Change.replace) {
                        $datasheet.Replace[$Change.replace] = $Change.$($Change.replace)
                    }
                    else {
                        foreach ($propertyName in $Change.PSObject.Properties.Name) {
                            if ($propertyName -in 'DistinguishedName','changetype','FM_OrderCount') { continue }
                            $datasheet.Replace[$propertyName] = $Change.$propertyName
                        }
                    }
                }
                #endregion Undefined state
            }
        }
    }

    function Copy-State {
        [CmdletBinding()]
        param (
            [Hashtable]
            $MappingTable,

            [string]
            $OldLdif,

            [string]
            $NewLdif
        )

        foreach ($name in $MappingTable.Keys) {
            Add-Node -DistinguishedName $name -LdifName $NewLdif -MappingTable $MappingTable

            foreach ($key in $MappingTable[$name][$OldLdif].State.Keys) {
                $MappingTable[$name][$NewLdif].State[$key] = $MappingTable[$name][$OldLdif].State[$key] | Write-Output
            }
            foreach ($key in $MappingTable[$name][$OldLdif].Add.Keys) {
                $MappingTable[$name][$NewLdif].Add[$key] = $MappingTable[$name][$OldLdif].Add[$key] | Write-Output
            }
            foreach ($key in $MappingTable[$name][$OldLdif].Replace.Keys) {
                $MappingTable[$name][$NewLdif].Replace[$key] = $MappingTable[$name][$OldLdif].Replace[$key] | Write-Output
            }
        }
    }

    function Remove-NoOp {
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
        [CmdletBinding()]
        param (
            $LdifData,

            [Hashtable]
            $MappingTable
        )

        $identities = $MappingTable.Keys | Write-Output
        foreach ($identity in $identities) {
            foreach ($ldifFile in $LdifData) {
                if (-not $MappingTable[$identity][$ldifFile.Name]) { continue }
                if ($ldifFile.Settings.DistinguishedName -contains $identity) { continue }
                $MappingTable[$identity].Remove($ldifFile.Name)
            }
        }
    }
    #endregion Utility Functions

    $mappingTable = @{ }

    $sortedLdif = $ldifData | Sort-Object Weight
    $previousLdif = ''
    foreach ($ldifItem in $sortedLdif) {
        if ($previousLdif) {
            Copy-State -MappingTable $mappingTable -OldLdif $previousLdif -NewLdif $ldifItem.Name
        }

        foreach ($setting in ($ldifItem.Settings | Sort-Object FM_OrderCount)) {
            Write-Change -DistinguishedName $setting.DistinguishedName -LdifName $ldifItem.Name -Change $setting -MappingTable $mappingTable
        }

        $previousLdif = $ldifItem.Name
    }

    Remove-NoOp -LdifData $sortedLdif -MappingTable $mappingTable
    $mappingTable
}