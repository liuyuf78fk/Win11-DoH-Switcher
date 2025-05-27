# Windows 11 DoH Switcher

A PowerShell-based DNS configuration tool that enables flexible DNS-over-HTTPS (DoH) setup with multiple provider options and customizable settings.

## Features

- **Multi-provider DoH support**: Choose from Cloudflare, Google, Quad9 and more
- **Customizable UDP fallback**: Enable or disable UDP fallback as needed
- **Network interface awareness**: Works with any active network interface
- **Configuration persistence**: Remembers your preferred settings between runs
- **Admin auto-elevation**: Automatic UAC privilege escalation via batch launcher
- **Native Windows integration**: Uses built-in PowerShell cmdlets with no dependencies

## Supported DoH Providers

| Provider  | Primary DNS | Secondary DNS | DoH Endpoint |
|-----------|------------|--------------|--------------|
| Cloudflare | 1.1.1.1 | 1.0.0.1 | `https://cloudflare-dns.com/dns-query` |
| Google | 8.8.8.8 | 8.8.4.4 | `https://dns.google/dns-query` |
| Quad9 | 9.9.9.9 | 149.112.112.112 | `https://dns.quad9.net/dns-query` |

## Installation

1. Download or clone the repository
2. No installation required - runs directly from downloaded files

## Usage

### Quick Start
1. Double-click `Set-DNS.bat` (admin rights auto-requestor)
2. Follow the menu prompts

### Detailed Options
- **1**: Apply DNS with DoH using current provider and settings
- **2**: Reset to DHCP automatic DNS configuration
- **3**: Select DoH provider (Cloudflare, Google, etc.)
- **4**: Configure UDP fallback (enable/disable)
- **5**: Change network interface (for multi-interface systems)

## Files

- `Set-DNS.ps1`: Main PowerShell script containing all logic
- `Set-DNS.bat`: Admin rights auto-elevation launcher (UAC prompt handler)
- `config.json`: Automatically created configuration file (stored in %APPDATA%)

## Technical Implementation

- Uses native Windows PowerShell commands:
  - `Set-DnsClientServerAddress` for DNS server configuration
  - `Set-DnsClientDohServerAddress` for DoH enforcement
  - `Get-NetAdapter` for interface detection
- Configuration stored in JSON format at `%APPDATA%\Win11-DoH-Switcher\config.json`
- No internet access required after download
- No third-party dependencies

## Requirements

- Windows 11 (may work on Windows 10 1809+)
- PowerShell 5.1 or later
- Administrator privileges (automatically requested)

## Adding More Providers

To add additional DoH providers:

1. Register the DoH Server in Windows 11 (Required)

   ```powershell
   Set-DnsClientDohServerAddress -ServerAddress "DNS_IP" -DohTemplate "DoH_URL" -AllowFallbackToUdp $true -AutoUpgrade $true
   ```

   *Example (for AdGuard DNS):*

   ```powershell
   Add-DnsClientDohServerAddress -ServerAddress "94.140.14.14" -DohTemplate "https://dns.adguard-dns.com/dns-query" -AllowFallbackToUdp $true -AutoUpgrade $true
   Add-DnsClientDohServerAddress -ServerAddress "94.140.15.15" -DohTemplate "https://dns.adguard-dns.com/dns-query" -AllowFallbackToUdp $true -AutoUpgrade $true
   ```
2. Edit `Set-DNS.ps1`

3. Add new entries to the `$dohProviders` hashtable
   - Follow the existing format
   - Example entry (AdGuard DNS):

     ```powershell
     "AdGuardDNS" = @{
         PrimaryDNS    = "94.140.14.14"
         SecondaryDNS = "94.140.15.15"
         DoHTemplate  = "https://dns.adguard-dns.com/dns-query"
     }
     ```

4. The new providers will automatically appear in the selection menu
