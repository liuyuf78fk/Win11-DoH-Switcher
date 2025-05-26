<#
    Win11-DoH-Switcher
	Copyright (C) 2025  Liu Yu <f78fk@live.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
#>

# Require admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Start-Sleep 3
    exit
}

# Configuration parameters - USER CAN MODIFY THESE
$interfaceName = "WLAN" # Change this to your network interface name (e.g., "Ethernet", "Wi-Fi")

# Configuration file and directory paths
$configDir = "$env:APPDATA\Win11-DoH-Switcher"
$configFile = "$configDir\config.json"

# Initialize config directory if not exists
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Default configuration as a hashtable
$defaultConfig = @{
    SelectedProvider     = "Cloudflare"
    AllowFallbackToUdp   = $true
}

# Available DoH providers (with proper template formats)
$dohProviders = @{
    "Cloudflare" = @{
        PrimaryDNS = "1.1.1.1"
        SecondaryDNS = "1.0.0.1"
        DoHTemplate = "https://cloudflare-dns.com/dns-query"
    }
    "Google" = @{
        PrimaryDNS = "8.8.8.8"
        SecondaryDNS = "8.8.4.4"
        DoHTemplate = "https://dns.google/dns-query"
    }
    "Quad9" = @{
        PrimaryDNS = "9.9.9.9"
        SecondaryDNS = "149.112.112.112"
        DoHTemplate = "https://dns.quad9.net/dns-query"
    }
}

function Load-Config {
    if (Test-Path $configFile) {
        try {
            $loadedConfig = Get-Content $configFile -Raw | ConvertFrom-Json
            if (-not $loadedConfig.PSObject.Properties.Name -contains "SelectedProvider" -or 
                -not $dohProviders.ContainsKey($loadedConfig.SelectedProvider)) {
                $loadedConfig | Add-Member -MemberType NoteProperty -Name SelectedProvider -Value $defaultConfig.SelectedProvider -Force
            }
            if (-not $loadedConfig.PSObject.Properties.Name -contains "AllowFallbackToUdp") {
                $loadedConfig | Add-Member -MemberType NoteProperty -Name AllowFallbackToUdp -Value $defaultConfig.AllowFallbackToUdp -Force
            }
            return $loadedConfig
        } catch {
            Write-Host "Config file corrupted, using defaults" -ForegroundColor Yellow
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            return $defaultConfig.Clone()
        }
    }

    return $defaultConfig.Clone()
}


# Function to save configuration to file
function Save-Config {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8 -Force
}


# Function to get active network interface if specified one doesn't exist
function Get-NetworkInterface {
    param(
        [string]$PreferredInterface
    )
    
    $allInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($allInterfaces.Name -contains $PreferredInterface) {
        return $PreferredInterface
    }
    
    # Fallback to first active interface
    if ($allInterfaces.Count -gt 0) {
        return $allInterfaces[0].Name
    }
    
    throw "No active network interfaces found"
}

# Main menu display
function Show-MainMenu {
	
    Write-Host "`n=== DoH Configuration Script ===" -ForegroundColor White
	Write-Host "Author: Liu Yu <f78fk@live.com>`n" -ForegroundColor DarkGray
    Write-Host "Current Interface: $interfaceName`n" 
    Write-Host "1. Set DNS with DoH (Current: $($config.SelectedProvider), UDP Fallback: $($config.AllowFallbackToUdp))`n" 
    Write-Host "2. Reset to DHCP automatic DNS`n"
    Write-Host "3. Select DoH Provider (Current: $($config.SelectedProvider))`n" 
    Write-Host "4. Configure UDP Fallback (Current: $($config.AllowFallbackToUdp))`n" 
    Write-Host "5. Change Network Interface (Current: $interfaceName)`n" 
	Write-Host "6. Exit`n" 
	Write-Host "7. Displays the full TCP/IP configuration for all adapters`n"
    Write-Host "" 
}

# Provider selection menu
function Show-ProviderMenu {
    Clear-Host
    Write-Host "`n=== Select DoH Provider ===" -ForegroundColor Cyan
    $i = 1
    $providerNames = $dohProviders.Keys | Sort-Object
    foreach ($name in $providerNames) {
        Write-Host "$i. $name"
        $i++
    }
    Write-Host ""
    Write-Host "$i. Return to main menu"
    Write-Host ""
}

# UDP fallback configuration menu
function Show-FallbackMenu {
    Clear-Host
    Write-Host "`n=== Configure UDP Fallback ===" -ForegroundColor Cyan
    Write-Host "1. Enable UDP Fallback"
    Write-Host "2. Disable UDP Fallback"
    Write-Host ""
    Write-Host "3. Return to main menu"
    Write-Host ""
}

# Interface selection menu
function Show-InterfaceMenu {
    Clear-Host
    Write-Host "`n=== Select Network Interface ===" -ForegroundColor Cyan
    $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $i = 1
    foreach ($iface in $interfaces) {
        Write-Host "$i. $($iface.Name) ($($iface.InterfaceDescription))"
        $i++
    }
    Write-Host ""
    Write-Host "$i. Return to main menu"
    Write-Host ""
}

# Main script execution
# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Start-Sleep 3
    exit
}

# Load configuration
$config = Load-Config

# Get current interface (with fallback)
try {
    $interfaceName = Get-NetworkInterface -PreferredInterface $interfaceName
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Start-Sleep 3
    exit
}

# Main loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Enter option (1-7)"
    
    switch ($choice) {
        "1" {
            # Apply selected DoH provider settings
            $provider = $dohProviders[$config.SelectedProvider]
            
            try {
                # First set the DNS servers
                Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses ($provider.PrimaryDNS, $provider.SecondaryDNS)
                
                # Then configure DoH for each server
                @($provider.PrimaryDNS, $provider.SecondaryDNS) | ForEach-Object {
                    $params = @{
                        ServerAddress = $_
                        DohTemplate = $provider.DoHTemplate
                        AllowFallbackToUdp = $config.AllowFallbackToUdp
                        AutoUpgrade = $true
                    }
                    try {
                        Set-DnsClientDohServerAddress @params
                    } catch {
                        Write-Host "Warning: Could not set DoH for $_ - $_" -ForegroundColor Yellow
                    }
                }
                
                Write-Host "`nSuccess! Configured:" -ForegroundColor Green
                Write-Host "- Interface: $interfaceName"
                Write-Host "- Provider: $($config.SelectedProvider)"
                Write-Host "- Primary DNS: $($provider.PrimaryDNS) (DoH enforced)"
                Write-Host "- Secondary DNS: $($provider.SecondaryDNS) (DoH enforced)"
                Write-Host "- UDP fallback: $($config.AllowFallbackToUdp)"
                
                # Verify configuration
                Write-Host "`n=== Current DNS Settings ===" -ForegroundColor Yellow
                Get-DnsClientServerAddress -InterfaceAlias $interfaceName | Format-Table -AutoSize
                
                Write-Host "`n=== DoH Configuration ===" -ForegroundColor Yellow
                Get-DnsClientDohServerAddress | Format-Table -AutoSize
                
            } catch {
                Write-Host "Error applying settings: $_" -ForegroundColor Red
            }
            
            Read-Host "`nPress Enter to continue..."
        }
        "2" {
            # Reset to DHCP
            try {
                Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ResetServerAddresses
                Write-Host "`nSuccess! DNS reset to DHCP automatic configuration" -ForegroundColor Green
            } catch {
                Write-Host "Error resetting DNS: $_" -ForegroundColor Red
            }
            Start-Sleep 1
        }
        "3" {
            # Provider selection
            while ($true) {
                Show-ProviderMenu
                $providerNames = $dohProviders.Keys | Sort-Object
                $providerChoice = Read-Host "Select provider (1-$($providerNames.Count)) or $($providerNames.Count+1) to return"
                
                if ($providerChoice -eq ($providerNames.Count + 1)) {
                    break
                }
                
                if ($providerChoice -ge 1 -and $providerChoice -le $providerNames.Count) {
                    $selectedProvider = $providerNames[$providerChoice - 1]
                    $config.SelectedProvider = $selectedProvider
                    Save-Config -Config $config
                    Write-Host "`nSelected provider: $selectedProvider" -ForegroundColor Green
                    Start-Sleep 1
                    break
                } else {
                    Write-Host "Invalid selection" -ForegroundColor Red
                    Start-Sleep 1
                }
            }
        }
        "4" {
            # UDP fallback configuration
            while ($true) {
                Show-FallbackMenu
                $fallbackChoice = Read-Host "Enter option (1-3)"
                
                switch ($fallbackChoice) {
                    "1" {
                        $config.AllowFallbackToUdp = $true
                        Save-Config -Config $config
                        Write-Host "`nUDP fallback enabled" -ForegroundColor Green
                        Start-Sleep 1
                        break
                    }
                    "2" {
                        $config.AllowFallbackToUdp = $false
                        Save-Config -Config $config
                        Write-Host "`nUDP fallback disabled" -ForegroundColor Green
                        Start-Sleep 1
                        break
                    }
                    "3" {
                        break
                    }
                    default {
                        Write-Host "Invalid selection" -ForegroundColor Red
                        Start-Sleep 1
                    }
                }
                
                if ($fallbackChoice -eq "1" -or $fallbackChoice -eq "2" -or $fallbackChoice -eq "3") {
                    break
                }
            }
        }
        "5" {
            # Change network interface
            try {
                $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
                if ($interfaces.Count -eq 0) {
                    throw "No active network interfaces found"
                }
                
                Show-InterfaceMenu
                $interfaceChoice = Read-Host "Select interface (1-$($interfaces.Count)) or $($interfaces.Count+1) to return"
                
                if ($interfaceChoice -ge 1 -and $interfaceChoice -le $interfaces.Count) {
                    $interfaceName = $interfaces[$interfaceChoice - 1].Name
                    Write-Host "`nSelected interface: $interfaceName" -ForegroundColor Green
                    Start-Sleep 1
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
                Start-Sleep 1
            }
        }
        "6" {
            # Exit Program
            Write-Host "Exiting..."
			
			Exit
			
        }
        "7" {
            # Display all network configurations
            Write-Host "ipconfig /all"
			ipconfig /all
        }
        default {
            Write-Host "Invalid selection. Please choose 1-7." -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
