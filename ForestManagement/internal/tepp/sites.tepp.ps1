Register-PSFTeppScriptblock -Name "ForestManagement.Sites" -ScriptBlock {
    $module = Get-Module ForestManagement
    & $module { $script:sites.Keys }
}

Register-PSFTeppScriptblock -Name "ForestManagement.Site2New" -ScriptBlock {
    $module = Get-Module ForestManagement
    $sites = & $module { $script:sites.Keys }
    $sitelinks = & $module { $script:sitelinks.Values }

    if (-not $fakeBoundParameter.Site1) {
        return $sites | Sort-Object -Unique
    }

    $results = foreach ($site in $sites) {
        if ($site -eq $fakeBoundParameter.Site1) { continue }
        if ($siteLinks | Where-Object { ($_.Site1 -eq $fakeBoundParameter.Site1) -and ($_.Site2 -eq $site) }) { continue }
        if ($siteLinks | Where-Object { ($_.Site2 -eq $fakeBoundParameter.Site1) -and ($_.Site1 -eq $site) }) { continue }
        $site
    }
    $results | Sort-Object -Unique
}

Register-PSFTeppScriptblock -Name "ForestManagement.Linked.Site1" -ScriptBlock {
    $module = Get-Module ForestManagement
    $siteLinks = & $module { $script:sitelinks.Values }

    if (-not $fakeBoundParameter.Site2) {
        return $siteLinks.Site1 | Sort-Object -Unique
    }
    ($siteLinks | Where-Object Site2 -eq $fakeBoundParameter.Site2).Site1 | Sort-Object -Unique
}

Register-PSFTeppScriptblock -Name "ForestManagement.Linked.Site2" -ScriptBlock {
    $module = Get-Module ForestManagement
    $siteLinks = & $module { $script:sitelinks.Values }

    if (-not $fakeBoundParameter.Site1) {
        return $siteLinks.Site2 | Sort-Object -Unique
    }
    ($siteLinks | Where-Object Site1 -eq $fakeBoundParameter.Site1).Site2 | Sort-Object -Unique
}