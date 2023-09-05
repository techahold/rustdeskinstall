$ErrorActionPreference= 'silentlycontinue'
#Run as administrator and stays in the current directory
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
        Exit;
    }
}
# Replace wanipreg and keyreg with the relevant info for your install. IE wanipreg becomes your rustdesk server IP or DNS and keyreg becomes your public key.

If (!(Test-Path $env:Temp)) {
  New-Item -ItemType Directory -Force -Path $env:Temp > null
}

If (!(Test-Path "$env:ProgramFiles\Rustdesk\RustDesk.exe")) {

$ErrorActionPreference= 'silentlycontinue'

If (!(Test-Path c:\Temp)) {
  New-Item -ItemType Directory -Force -Path c:\Temp > null
}

cd c:\Temp

powershell Invoke-WebRequest "https://github.com/rustdesk/rustdesk/releases/download/1.2.2/rustdesk-1.2.2-x86_64.exe" -Outfile "rustdesk.exe"
Start-Process .\rustdesk.exe --silent-install -wait

$ServiceName = 'Rustdesk'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null)
{
    Start-Sleep -seconds 20
}

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    Start-Sleep -seconds 5
    $arrService.Refresh()
}

net stop rustdesk

$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
Remove-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
New-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"
Remove-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
New-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"

net start rustdesk

$random_pass = (-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_}))
Start-Process "$env:ProgramFiles\RustDesk\RustDesk.exe"  -argumentlist "--password $random_pass" -wait

net stop rustdesk > null
$ProcessActive = Get-Process rustdesk -ErrorAction SilentlyContinue
if($ProcessActive -ne $null)
{
stop-process -ProcessName rustdesk -Force
}

$rustdesk_pw = (-join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})) 
Start-Process "$env:ProgramFiles\RustDesk\RustDesk.exe" "--password $rustdesk_pw" -wait

net start rustdesk > null

cd $env:ProgramFiles\RustDesk\
$rustdesk_id = (.\RustDesk.exe --get-id | out-host)

Write-Output "RustDesk ID is: $rustdesk_id"
Write-Output "RustDesk Password is: $rustdesk_pw"

Stop-Process -Name RustDesk -Force > null
Start-Service -Name RustDesk > null
}
