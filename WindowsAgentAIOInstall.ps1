# Replace wanipreg and keyreg with the relevant info

$ErrorActionPreference= 'silentlycontinue'

If (!(test-path "c:\temp")) {
    New-Item -ItemType Directory -Force -Path "c:\temp"
}
cd c:\temp

If (!(test-path "C:\Program Files\Rustdesk\RustDesk.exe")) {
cd c:\temp

Invoke-WebRequest https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9-windows_x64.zip -Outfile rustdesk.zip

expand-archive rustdesk.zip
cd rustdesk
start .\rustdesk-1.1.9-putes.exe --silent-install
}

# Write config
If (!("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml")) {
$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
New-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"
}
else {
New-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"
}

Start-sleep -s 20

# Get RustDesk ID

If (!("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml")) {
$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
$rustid=(Get-content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("id") })
$rustid = $rustid.Split("'")[1]

$rustpword = (Get-content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("password") })
$rustpword = $rustpword.Split("'")[1]
Write-output "Config file found in user folder"
Write-output "$rustid"
Write-output "$rustpword"
}
else {
$rustid=(Get-content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("id") })
$rustid = $rustid.Split("'")[1]

$rustpword = (Get-content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("password") })
$rustpword = $rustpword.Split("'")[1]
Write-output "Config file found in windows service folder"
Write-output "$rustid"
Write-output "$rustpword"
}

Start-sleep -s 10

net stop rustdesk
net start rustdesk
