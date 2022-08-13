$ErrorActionPreference= 'silentlycontinue'
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
