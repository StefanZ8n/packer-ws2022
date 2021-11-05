# Written by Stefan Zimmermann

# Configure basic telemetry settings
# https://docs.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\DataCollection"
$settingName = "AllowTelemetry"
$settingValue = "0" # Security
New-ItemProperty -Path $registryPath -Name $settingName -Value $settingValue -PropertyType DWORD -Force | Out-Null

# Show file extentions by default in Windows Explorer
# https://social.technet.microsoft.com/Forums/en-US/78efe17d-1faa-4da1-a0e2-3387493a1e97/powershell-loading-unloading-and-reading-hku?forum=ITCG
$registryPath = "HKU:\UserHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
$null = reg load HKU\UserHive C:\Users\Default\NTUSER.DAT
$settingName = "HideFileExt"
$settingValue = "0"
New-ItemProperty -Path $registryPath -Name $settingName -Value $settingValue -PropertyType DWORD -Force

[gc]::Collect() # Required that unloading is possible
$null = reg unload HKU\UserHive
$null = Remove-PSDrive -Name HKU

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y microsoft-edge

choco install -y --package-parameters=/SSHServerFeature openssh

choco install -y powershell-core

choco install -y 7zip

choco install -y notepadplusplus.install

# Enable PowerShell core as the default SSH Shell
# See https://gitlab.com/DarwinJS/ChocoPackages/-/blob/master/openssh/tools/Set-SSHDefaultShell.ps1
. $env:programfiles\OpenSSH-Win64\Set-SSHDefaultShell.ps1 -PathSpecsToProbeForShellEXEString "$env:programfiles\PowerShell\*\pwsh.exe;$env:programfiles\PowerShell\*\Powershell.exe;c:\windows\system32\windowspowershell\v1.0\powershell.exe"