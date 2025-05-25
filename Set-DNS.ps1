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

# Menu
Write-Host "`n=== DNS Configuration Script ===" -ForegroundColor Cyan
Write-Host "1. Set Cloudflare DNS (1.1.1.1) with STRICT DoH (enable UDP fallback)"
Write-Host "2. Reset to DHCP automatic DNS"
Write-Host ""

# Get user choice
$choice = Read-Host "Enter option (1 or 2)"

# Configuration
switch ($choice) {
    "1" {
        # Set Cloudflare DNS
        Set-DnsClientServerAddress -InterfaceAlias "WLAN" -ServerAddresses ("1.1.1.1", "1.0.0.1")
        
        # Configure DoH with NO FALLBACK
        Set-DnsClientDohServerAddress -ServerAddress "1.1.1.1" `
            -DohTemplate "https://cloudflare-dns.com/dns-query{?dns}" `
            -AllowFallbackToUdp $true `
            -AutoUpgrade $true
        
        Set-DnsClientDohServerAddress -ServerAddress "1.0.0.1" `
            -DohTemplate "https://cloudflare-dns.com/dns-query{?dns}" `
            -AllowFallbackToUdp $true `
            -AutoUpgrade $true
        
        Write-Host "`nSuccess! Configured:" -ForegroundColor Green
        Write-Host "- Primary DNS: 1.1.1.1 (DoH enforced)"
        Write-Host "- Secondary DNS: 1.0.0.1 (DoH enforced)"
        Write-Host "- UDP fallback: DISABLED"
    }
    "2" {
        # Reset to DHCP
        Set-DnsClientServerAddress -InterfaceAlias "WLAN" -ResetServerAddresses
        Write-Host "`nSuccess! DNS reset to DHCP automatic configuration" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid selection. Please run again and choose 1 or 2." -ForegroundColor Red
        Start-Sleep 2
        exit
    }
}

# Verify configuration
Write-Host "`n=== Current DNS Settings ===" -ForegroundColor Yellow
Get-DnsClientServerAddress -InterfaceAlias "WLAN" | Format-Table -AutoSize

Write-Host "`n=== DoH Configuration ===" -ForegroundColor Yellow
Get-DnsClientDohServerAddress | Format-Table -AutoSize

# Keep window open
Write-Host ""
Read-Host "Press Enter to exit..."