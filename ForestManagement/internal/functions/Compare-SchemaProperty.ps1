function Compare-SchemaProperty {
    <#
    .SYNOPSIS
        Compares configuration vs. adobject of schema attributes.
    
    .DESCRIPTION
        Compares configuration vs. adobject of schema attributes.
        Designed for use when comparing schema attributes, for example in Test-FMSchemaLdif.

        Returns $true when the values are INEQUAL.
    
    .PARAMETER Setting
        The settings object containing the desired state for an attribute.
    
    .PARAMETER ADObject
        The ADObject of the attribute to compare.
    
    .PARAMETER PropertyName
        The property to compare.
    
    .PARAMETER RootDSE
        The RootDSE object connected to.
        Used for objectCategory comparisons.

    .PARAMETER Add
        Is satisfied with the defined items being part of the AD object property, without requiring an exact match between configuration and ad.
    
    .EXAMPLE
        PS C:\> Compare-SchemaProperty -Setting $setting -ADObject $adObject -PropertyName attributeSecurityGUID -RootDSE $rootDSE

        Returns, whether the values found in $setting and $adObject are different from each other.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Setting,
        [Parameter(Mandatory=$true)]
        $ADObject,
        [Parameter(Mandatory=$true)]
        $PropertyName,
        [Parameter(Mandatory=$true)]
        $RootDSE,
        [switch]
        $Add
    )

    switch ($PropertyName) {
        'schemaIDGUID' {
            return (($Setting.$PropertyName.GuidData -join '|') -ne ($ADObject.$PropertyName -join '|'))
        }
        'attributeSecurityGUID' {
            return (($Setting.$PropertyName.GuidData -join '|') -ne ($ADObject.$PropertyName -join '|'))
        }
        'objectCategory' {
            return (($Setting.$PropertyName -replace '<SchemaContainerDN>',$RootDSE.schemaNamingContext) -ne ($ADObject.$PropertyName -join '|'))
        }
        'DistinguishedName' {
            # Don't compare identifiers!
            return $false
        }
        'Description' {
            # Prevent encoding errors / issues from falsifying the results
            if (($null -eq $Setting.$PropertyName) -and ($null -eq ($ADObject.$PropertyName | Select-Object -Unique))) { return $false }
            if ($null -eq $Setting.$PropertyName) { return $true }
            if ($null -eq ($ADObject.$PropertyName | Select-Object -Unique)) { return $true }
            return (($Setting.$PropertyName -replace "[^\d\w]","_") -ne ($ADObject.$PropertyName -replace "[^\d\w]","_"))
        }
        'mayContain' {
            if (($null -eq $Setting.$PropertyName) -and ($null -eq ($ADObject.$PropertyName | Select-Object -Unique))) { return $false }
            if ($null -eq $Setting.$PropertyName) { return $true }
            if ($null -eq ($ADObject.$PropertyName | Select-Object -Unique)) { return $true }
            return [bool](Compare-Object ($Setting.$PropertyName | Select-Object -Unique) ($ADObject.$PropertyName | Select-Object -Unique) | Where-Object SideIndicator -eq '<=')
        }
        default {
            if (($null -eq $Setting.$PropertyName) -and ($null -eq ($ADObject.$PropertyName | Select-Object -Unique))) { return $false }
            if ($null -eq $Setting.$PropertyName) { return $true }
            if ($null -eq ($ADObject.$PropertyName | Select-Object -Unique)) { return $true }
            if ($Add) { return [bool](Compare-Object ($Setting.$PropertyName | Select-Object -Unique) ($ADObject.$PropertyName | Select-Object -Unique) | Where-Object SideIndicator -eq '<=') }
            return [bool](Compare-Object $Setting.$PropertyName $ADObject.$PropertyName)
        }
    }
}