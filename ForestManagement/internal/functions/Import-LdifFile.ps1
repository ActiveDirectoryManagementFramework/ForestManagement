function Import-LdifFile
{
	<#
	.SYNOPSIS
		Parses an LDIF file and returns the changes it applies.
	
	.DESCRIPTION
		Parses an LDIF file and returns the changes it applies.
		Note: schemaupdatenow commands are skipped.
	
	.PARAMETER Path
		The path to the LDIF file to parse.
	
	.EXAMPLE
		PS C:\> Import-LdifFile -Path $ldifFile

		Parses the ldif file and returns changes it applies.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Path
	)
	
	begin
	{
		#region Utility Functions
		function Resolve-AttributeName
		{
			[OutputType([string])]
			[CmdletBinding()]
			param (
				[string]
				$Name
			)
			
			switch ($Name)
			{
				'dn' { 'DistinguishedName' }
				default { $Name }
			}
		}
		function Resolve-AttributeValue
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
			[CmdletBinding()]
			param (
				[string]
				$Value,
				
				[bool]
				$IsBase64,
				
				[string]
				$AttributeName
			)
			
			if ($IsBase64)
			{
				switch ($AttributeName)
				{
					'schemaIDGUID' {
						[PSCustomObject]@{
							Guid = [System.Guid]::new([System.Convert]::FromBase64String($Value))
							GuidData = [System.Convert]::FromBase64String($Value)
						}
					}
					'attributeSecurityGUID' {
						[PSCustomObject]@{
							Guid = [System.Guid]::new([System.Convert]::FromBase64String($Value))
							GuidData = [System.Convert]::FromBase64String($Value)
						}
					}
					default { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value)) }
				}
			}
			else
			{
				if ($Value -eq "TRUE") { return $true }
				if ($Value -eq "FALSE") { return $false }
				if ($Value -eq "") { return '' }
				if ($null -ne ($Value -as [int])) { return ($Value -as [int]) }
				$Value
			}
		}
		#endregion Utility Functions
		
		$lines = Get-Content -Path $Path
		$currentObject = @{ }
		$lastKey = ''
	}
	process
	{
		$isBase64 = $false
		foreach ($line in $lines)
		{
			if (-not $line) { continue }
			if ($line -like '#*') { continue }
			if ($line -like 'dn:*')
			{
				if (($currentObject.Keys.Count -gt 1) -and ($currentObject['replace'] -ne 'schemaupdatenow')) { [pscustomobject]$currentObject }
				$currentObject = @{
					PSTypeName	      = 'ForestManagement.Schema.Ldif.Setting'
					DistinguishedName = ($line -replace '^dn:', '').Trim() -replace ',DC=X$' -replace ',CN=Schema,CN=Configuration$'
				}
				$lastKey = 'DistinguishedName'
				continue
			}
			if ($line -match '^([^:]+):(?<colon>:*) (.*)$')
			{
				$isBase64 = $matches['colon'] -eq ':'
				$attributeName = Resolve-AttributeName -Name $matches[1]
				$attributeValue = Resolve-AttributeValue -Value $matches[2] -IsBase64 $isBase64 -AttributeName $attributeName
				# Prevent duplicate object classes - top is redundant and not listed in AD
				if (($attributeName -eq 'ObjectClass') -and ($attributeValue -eq 'Top')) { continue }
				if ($currentObject.ContainsKey($attributeName))
				{
					$values = @($currentObject[$attributeName])
					$values += $attributeValue
					$currentObject[$attributeName] = $values
				}
				else
				{
					$currentObject[$attributeName] = $attributeValue
				}
				$lastKey = $attributeName
			}
			# Handle value continuation on the next line
			# Values break line when exceeding a total width of 80 characters
			elseif ($line -match '^ (.+)$')
			{
				$currentObject[$lastKey] = $currentObject[$lastKey] + (Resolve-AttributeValue -Value $matches[1] -IsBase64 $isBase64 -AttributeName $lastKey)
			}
		}
	}
	end
	{
		# Process last item
		if ($currentObject.Keys.Count -gt 0)
		{
			if ($currentObject['replace'] -ne 'schemaupdatenow') { [pscustomobject]$currentObject }
		}
	}
}
