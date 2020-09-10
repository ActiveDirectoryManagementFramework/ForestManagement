$modules = @("Pester", "PSScriptAnalyzer", "PSFramework", "PSModuleDevelopment", 'ResolveString', 'Principal', 'ADMF.Core', 'DomainManagement')

foreach ($module in $modules) {
    Write-Host "Installing $module" -ForegroundColor Cyan
    Install-Module $module -Force -SkipPublisherCheck
    Import-Module $module -Force -PassThru
}