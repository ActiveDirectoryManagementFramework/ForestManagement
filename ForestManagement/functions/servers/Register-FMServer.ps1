function Register-FMServer {
    <#
    .SYNOPSIS
        Configure the server-site assignment.
    
    .DESCRIPTION
        Configure the server-site assignment.
    
    .PARAMETER NoAutoAssignment
        Setting this to true will disable any automatically calculated site assignments.
        When enabled, only explicitly configured site assignments will be applied.
    
    .EXAMPLE
        PS C:\> Get-Content .\servers.json | ConvertFrom-Json | Write-Output | Register-FMServer
        
        Apply all configuration settings stored in servers.json
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Auto')]
        [bool]
        $NoAutoAssignment
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            #region Auto Assignment
            'Auto'
            {
                $script:serverAutoAssignment = -not $NoAutoAssignment
            }
            #endregion Auto Assignment
        }
    }
}