function Set-FMContentMode {
	<#
	.SYNOPSIS
		Configures the way the module handles forest level objects not defined in configuration.
	
	.DESCRIPTION
		Configures the way the module handles forest level objects not defined in configuration.
		Depending on the desired forest configuration, dealing with undesired objects may be desirable.

		This module handles the following configurations:
		Mode Additive: In this mode, all configured content is considered in addition to what is already there. Objects not in scope of the configuration are ignored.
		Mode Constrained: In this mode, objects not configured are handled based on path rules:
		- Include: If Include Paths are configured, only objects in the specified OUs are under management. Only objects in these OUs will be considered for deletion if not configured.
		- Exclude: If Exclude Paths are configured, objects in the excluded OUs are ignored, all objects outside of these OUs will be considered for deletion if not configured.
		If both Include and Exclude OUs are configured, they are merged without applying the implied top-level Include of an Exclude-only configuration.
		In this scenario, if a top-level Include is desired, it needs to be explicitly set.

		When specifying Include and Exclude DNs, specify the full DN, inserting '%ConfigurationDN%' (without the quotes) for the configuration NC root and '%SchemaDN%' for the schema NC.
	
	.PARAMETER Mode
		The mode to operate under.
		In Additive mode, objects not configured are being ignored.
		In Constrained mode, objects not configured may still be under maanagement, depending on Include and Exclude rules.
	
	.PARAMETER Include
		Paths in which to look for objects under management.
		Use this to explicitly list which Pathss should be inspected for objects to manage.
		Only applied in Constrained mode.
		Specify the full DN, inserting '%ConfigurationDN%' (without the quotes) for the configuration NC root and '%SchemaDN%' for the schema NC.
	
	.PARAMETER Exclude
		Paths in which to NOT look for objects under management.
		All other Paths are subject to management and having undesired objects deleted.
		Only applied in Constrained mode.
		Specify the full DN, inserting '%ConfigurationDN%' (without the quotes) for the configuration NC root and '%SchemaDN%' for the schema NC.

	.PARAMETER ExcludeComponents
		Components to exclude from the Forest Content Mode.
		By including them here, non-configured objects of that type will no longer get deleted.
		(Details may vary, depending on the specific Component. See their respective documentation.)

		Each entry should use the Component name as Key and a boolean as Value in the hashtable.
		If the value is considered $true, the Component is excluded.
		Settings from multiple configuration sets will be merged, rather than fully replacing the old hashtable with a new one.

		Supported Components:
		- AccessRules: Excluding them will test only configured paths for access control entries (ACE).
	
	.EXAMPLE
		PS C:\> Set-DMContentMode -Mode 'Constrained' -Include 'OU=Administration,%DomainDN%'

		Enables Constrained mode and configures the top-level OU "Administration" as an OU under management.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[ValidateSet('Additive', 'Constrained')]
		[string]
		$Mode,

		[AllowEmptyCollection()]
		[string[]]
		$Include,

		[AllowEmptyCollection()]
		[string[]]
		$Exclude,

		[AllowEmptyCollection()]
		[string[]]
		$UserExcludePattern,

		[bool]
		$RemoveUnknownWmiFilter,

		[hashtable]
		$ExcludeComponents
	)
	
	process {
		if ($Mode) { $script:contentMode.Mode = $Mode }
		if (Test-PSFParameterBinding -ParameterName Include) { $script:contentMode.Include = $Include }
		if (Test-PSFParameterBinding -ParameterName Exclude) { $script:contentMode.Exclude = $Exclude }
		if (Test-PSFParameterBinding -ParameterName UserExcludePattern) { $script:contentMode.UserExcludePattern = $UserExcludePattern }
		if (Test-PSFParameterBinding -ParameterName RemoveUnknownWmiFilter) { $script:contentMode.RemoveUnknownWmiFilter = $RemoveUnknownWmiFilter }
		if ($ExcludeComponents) {
			foreach ($pair in $ExcludeComponents.GetEnumerator()) {
				if ($script:contentMode.ExcludeComponents.Keys -notcontains $pair.Key) {
					Write-PSFMessage -Level Warning -String 'Set-FMContentMode.Error.UnknownExcludedComponent' -StringValues $pair.Key
					continue
				}
				$script:contentMode.ExcludeComponents[$pair.Key] = $pair.Value -as [bool]
			}
		}
	}
}
