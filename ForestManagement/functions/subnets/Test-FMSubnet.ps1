function Test-FMSubnet {
	<#
		.SYNOPSIS
			Compares a forest's Subnet configuration against its desired state.
		
		.DESCRIPTION
			Compares a forest's Subnet configuration against its desired state.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
	
		.EXAMPLE
			PS C:\> Test-FMSubnet

			Compares the current forest's Subnet configuration against its desired state.
	#>
	
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[PSCredential]
		$Credential
	)
	
	begin {
		#region Functions
		function New-Update {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$Identity,

				$Property,

				$OldValue,

				$NewValue
			)

			$datum = [PSCustomObject]@{
				PSTypeName = 'ForestManagement.Subnet.Update'
				Identity   = $Identity
				Property   = $Property
				OldValue   = $OldValue
				NewValue   = $NewValue
			}
			Add-Member -InputObject $datum -MemberType ScriptMethod -Name ToString -Value {
				'{0}: {1} -> {2}' -f $this.Property, $this.OldValue, $this.NewValue
			} -Force
			$datum
		}
		#endregion Functions

		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-Callback @parameters -Cmdlet $PSCmdlet
		Assert-Configuration -Type Subnets -Cmdlet $PSCmdlet
		$allSubnets = Get-ADReplicationSubnet @parameters -Filter * -Properties Description | Select-Object *, @{
			Name       = "SiteName"
			Expression = { ($_.Site | Get-ADObject @parameters).Name }
		}
	}
	process {
		$resultDefaults = @{
			ObjectType = 'Subnet'
			Server     = $Server
		}

		#region Test all Subnets found in the forest
		foreach ($subnetItem in $allSubnets) {
			if ($script:subnets.Keys -notcontains $subnetItem.Name) {
				New-TestResult @resultDefaults -Type Delete -Identity $subnetItem.Name -ADObject $subnetItem -Properties @{
					SiteName    = $subnetItem.SiteName
					Name        = $subnetItem.Name
					Description = $subnetItem.Description
					Location    = $subnetItem.Location
				}
				continue
			}

			$configuredSubnet = $script:subnets[$subnetItem.Name]
			
			$deltaProperties = @()
			if ($subnetItem.SiteName -ne $configuredSubnet.SiteName) {
				$deltaProperties += New-Update -Identity $subnetItem.Name -OldValue $subnetItem.SiteName -NewValue $configuredSubnet.SiteName -Property 'Site'
			}
			if ([string]($subnetItem.Description) -ne $configuredSubnet.Description) {
				$deltaProperties += New-Update -Identity $subnetItem.Name -OldValue ([string]$subnetItem.Description) -NewValue $configuredSubnet.Description -Property 'Description'
			}
			if ([string]($subnetItem.Location) -ne $configuredSubnet.Location) {
				$deltaProperties += New-Update -Identity $subnetItem.Name -OldValue ([string]$subnetItem.Location) -NewValue $configuredSubnet.Location -Property 'Location'
			}

			if (-not $deltaProperties) { continue }
			New-TestResult @resultDefaults -Type Update -Identity $subnetItem.Name -ADObject $subnetItem -Configuration $configuredSubnet -Properties @{
				SiteName    = $configuredSubnet.SiteName
				Name        = $configuredSubnet.Name
				Description = $configuredSubnet.Description
				Location    = $configuredSubnet.Location
			} -Changed $deltaProperties
		}
		#endregion Test all Subnets found in the forest

		#region Catch subnets only in configuration but NOT in forest
		foreach ($configuredSubnet in $script:subnets.Values) {
			if ($allSubnets.Name -contains $configuredSubnet.Name) { continue }

			New-TestResult @resultDefaults -Type Create -Identity $configuredSubnet.Name -Configuration $configuredSubnet -Properties @{
				SiteName    = $configuredSubnet.SiteName
				Name        = $configuredSubnet.Name
				Description = $configuredSubnet.Description
				Location    = $configuredSubnet.Location
			}
		}
		#endregion Catch subnets only in configuration but NOT in forest
	}
}
