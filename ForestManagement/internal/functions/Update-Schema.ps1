function Update-Schema {
    <#
    .SYNOPSIS
        Forces a schema update.
    
    .DESCRIPTION
        Forces a schema update.
        This allows immediately assigning new attributes in schema.
        Generally, it is recommended targeting the schema master dc.
    
    .PARAMETER Server
        The server / domain to work with.
    
    .PARAMETER Credential
        The credentials to use for this operation.
    
    .EXAMPLE
        PS C:\> Update-Schema -Server dc1.contoso.com

        Forces a schema update on dc1.contoso.com
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
    param (
        [string]
        $Server,

        [PSCredential]
        $Credential
    )

    $path = "LDAP://RootDSE"
    if ($Server) { $path = "LDAP://$Server/RootDSE" }
    if ($Credential) { $rootDSE = [adsi]::new($path, $Credential.UserName, $Credential.GetNetworkCredential().Password) }
    else { $rootDSE = [adsi]::new($path) }

    $null = $rootDSE.put("schemaUpdateNow", 1)
    $null = $rootDSE.SetInfo()
}