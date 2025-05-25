@REM Win11-DoH-Switcher
@REM Copyright (C) 2025  Liu Yu <f78fk@live.com>
@REM
@REM This program is free software: you can redistribute it and/or modify
@REM it under the terms of the GNU General Public License as published by
@REM the Free Software Foundation, either version 3 of the License, or
@REM (at your option) any later version.
@REM
@REM This program is distributed in the hope that it will be useful,
@REM but WITHOUT ANY WARRANTY; without even the implied warranty of
@REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@REM GNU General Public License for more details.

@echo off
:: Check admin rights
fltmc >nul 2>&1 && goto :ADMIN

:: Not elevated, create temporary VBS to trigger UAC
echo Requesting administrator privileges...
echo Set UAC = CreateObject("Shell.Application") > "%temp%\RunAsAdmin.vbs"
echo UAC.ShellExecute "%~dpnx0", "", "", "runas", 1 >> "%temp%\RunAsAdmin.vbs"
wscript "%temp%\RunAsAdmin.vbs"
exit /b

:ADMIN
:: Already elevated, run PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0Set-DNS.ps1"
pause