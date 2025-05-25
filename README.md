# Windows11 DoH Switcher

A simple PowerShell + Batch tool to configure Cloudflare DNS (1.1.1.1) with strict DNS-over-HTTPS (no UDP fallback) or reset to DHCP automatic settings.

## Features

- One-click configuration of Cloudflare DNS with DoH enforcement
- Strict no-fallback mode (HTTPS only)
- UAC auto-elevation (just click "Yes" when prompted)
- Works on Windows 11

## How to Use

1. Download the repository
2. Double-click `Set-DNS.bat`
3. Choose option:
   - `1`: Set Cloudflare DNS (1.1.1.1) with strict DoH
   - `2`: Reset to DHCP automatic DNS

## Files

- `Set-DNS.ps1`: Main PowerShell script
- `Set-DNS.bat`: Batch launcher with auto-elevation

## Technical Details

- Uses native Windows commands (`Set-DnsClientServerAddress`, `Set-DnsClientDohServerAddress`)
- No third-party dependencies
- Admin rights required (automatically requested)

## Interface Configuration Note

The script defaults to using `WLAN` as the network interface name. If your WiFi uses a different interface name:

1. Find your actual interface name:
   ```cmd
   netsh interface show interface
   ```
   
2. Edit `Set-DNS.ps1` and replace all occurrences of `[WLAN]` with your interface name

