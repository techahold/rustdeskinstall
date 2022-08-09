$ErrorActionPreference= 'silentlycontinue'
# Replace wanipreg and keyreg with the relevant info

If (!(test-path "c:\temp")) {
    New-Item -ItemType Directory -Force -Path "c:\temp" > null
}
cd c:\temp

If (!(test-path "C:\Program Files\Rustdesk\RustDesk.exe")) {
cd c:\temp

Invoke-WebRequest https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9-windows_x64.zip -Outfile rustdesk.zip

expand-archive rustdesk.zip
cd rustdesk
start .\rustdesk-1.1.9-putes.exe --silent-install

# Set URL Handler
New-Item -Path "HKLM:\SOFTWARE\Classes\RustDesk" > null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\RustDesk" -Name "(Default)" -Value "URL:RustDesk Protocol" > null
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\RustDesk" -Name "URL Protocol" -Type STRING > null
New-Item -Path "HKLM:\SOFTWARE\Classes\RustDesk\DefaultIcon" > null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\RustDesk\DefaultIcon" -Name "(Default)" -Value "RustDesk.exe,0" > null
New-Item -Path "HKLM:\SOFTWARE\Classes\RustDesk\shell" > null 
New-Item -Path "HKLM:\SOFTWARE\Classes\RustDesk\shell\open" > null 
New-Item -Path "HKLM:\SOFTWARE\Classes\RustDesk\shell\open\command" > null 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\RustDesk\shell\open\command" -Name "(Default)" -Value '"C:\Program Files\RustDesk\RustDeskURLLauncher.exe" "%1"' > null
New-Item "C:\Program Files\RustDesk\urlhandler.ps1" > null
Set-Content "C:\Program Files\RustDesk\urlhandler.ps1" "`$url_handler = `$args[0]`n`$rustdesk_id = `$url_handler -creplace '(?s)^.*\:',''`nStart-Process -FilePath 'C:\Program Files\RustDesk\rustdesk.exe' -ArgumentList ""--connect `$rustdesk_id""" > null
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force  > null
Install-Module ps2exe -Force  > null
Invoke-ps2exe "C:\Program Files\RustDesk\urlhandler.ps1" "C:\Program Files\RustDesk\RustDeskURLLauncher.exe" > null
Remove-Item "C:\Program Files\RustDesk\urlhandler.ps1" > null

Start-sleep -s 20
}

# Write config
$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
New-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"
New-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'wanipreg' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'wanipreg'`nkey = 'keyreg'`nrelay-server = 'wanipreg'`napi-server = 'https://wanipreg'"

$rdpass = (-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_}))
start "C:\Program Files\RustDesk\RustDesk.exe" "--password $rdpass"

Start-sleep -s 5

# Get RustDesk ID

If (!("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml")) {
$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
$rustid=(Get-content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("id") })
$rustid = $rustid.Split("'")[1]

$rustpword = (Get-content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("password") })
$rustpword = $rustpword.Split("'")[1]
Write-output "$rustid"
Write-output "$rustpword"
Write-output "Config file found in user folder"
}
else {
$rustid=(Get-content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("id") })
$rustid = $rustid.Split("'")[1]

$rustpword = (Get-content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("password") })
$rustpword = $rustpword.Split("'")[1]
Write-output "$rustid"
Write-output "$rustpword"
Write-output "Config file found in windows service folder"
}

Start-sleep -s 10

taskkill /IM "rustdesk.exe" /F > null
net start rustdesk > null
