$ErrorActionPreference= 'silentlycontinue'
#Run as administrator and stays in the current directory
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
        Exit;
    }
}
# Replace wanipreg and keyreg with the relevant info for your install. IE wanipreg becomes your rustdesk server IP or DNS and keyreg becomes your public key.

$rustdesk_url = 'https://github.com/rustdesk/rustdesk/releases/latest'
$request = [System.Net.WebRequest]::Create($rustdesk_url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$rustdesk_version = $realTagUrl.split('/')[-1].Trim('v')
Write-Output("Installing Rustdesk version $rustdesk_version")

function OutputIDandPW([String]$rustdesk_id, [String]$rustdesk_pw) {
  Write-Output("######################################################")
  Write-Output("#                                                    #")
  Write-Output("# CONNECTION PARAMETERS:                             #")
  Write-Output("#                                                    #")
  Write-Output("######################################################")
  Write-Output("")
  Write-Output("  RustDesk-ID:       $rustdesk_id")
  Write-Output("  RustDesk-Password: $rustdesk_pw")
  Write-Output("")
}

If (!(Test-Path $env:Temp)) {
  New-Item -ItemType Directory -Force -Path $env:Temp > null
}

If (!(Test-Path "$env:ProgramFiles\Rustdesk\RustDesk.exe")) {

  cd $env:Temp

  If ([Environment]::Is64BitOperatingSystem) {
    $os_arch = "x64"
  } Else {
    $os_arch = "x32"
  }

  Invoke-WebRequest https://github.com/rustdesk/rustdesk/releases/download/1.2.0/rustdesk-1.2.0-x86_64.exe -Outfile rustdesk.exe

  Expand-Archive rustdesk.zip
  cd rustdesk
  Start-Process "rustdesk.exe" -argumentlist "--silent-install" -wait

  # Cleanup Tempfiles
  cd $env:Temp
  Remove-Item $env:Temp\rustdesk -Recurse > null
  Remove-Item $env:Temp\rustdesk.zip > null
}

# Write config
$RustDesk2_toml = @"
rendezvous_server = 'wanipreg'
nat_type = 1
serial = 0

[options]
custom-rendezvous-server = 'wanipreg'
key =  'keyreg'
relay-server = 'wanipreg'
api-server = 'https://wanipreg'
enable-audio = 'N'
"@

If (!(Test-Path $env:AppData\RustDesk\config\RustDesk2.toml)) {
  New-Item $env:AppData\RustDesk\config\RustDesk2.toml > null
}
Set-Content $env:AppData\RustDesk\config\RustDesk2.toml $RustDesk2_toml > null

If (!(Test-Path $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml)) {
  New-Item $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml > null
}
Set-Content $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml $RustDesk2_toml > null

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
Write-Output "$rustdesk_pw"

net start rustdesk > null

Stop-Process -Name RustDesk -Force > null
Start-Service -Name RustDesk > null
