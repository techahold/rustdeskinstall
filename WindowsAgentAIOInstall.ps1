$ErrorActionPreference= 'silentlycontinue'

# Assign the value random password to the password variable
$rustdesk_pw=(-join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_}))

# Get your config string from your Web portal and Fill Below
$rustdesk_cfg="secure-string"

################################### Please Do Not Edit Below This Line #########################################

# Run as administrator and stays in the current directory
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
        Exit;
    }
}

$rdver = ((Get-ItemProperty  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk\").Version)

if($rdver -eq "1.2.2")
{
write-output "RustDesk $rdver is the newest version"

exit
}

If (!(Test-Path C:\Temp)) {
  New-Item -ItemType Directory -Force -Path C:\Temp > null
}

cd C:\Temp

powershell Invoke-WebRequest "https://github.com/rustdesk/rustdesk/releases/download/1.2.2/rustdesk-1.2.2-x86_64.exe" -Outfile "rustdesk.exe"
Start-Process .\rustdesk.exe --silent-install -wait

$ServiceName = 'Rustdesk'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null)
{
    Write-Output "Installing service"
    cd $env:ProgramFiles\RustDesk
    Start-Process .\rustdesk.exe --install-service -wait -Verbose
    Start-Sleep -seconds 20
}

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    Start-Sleep -seconds 5
    $arrService.Refresh()
}

cd $env:ProgramFiles\RustDesk\
.\RustDesk.exe --get-id | Write-Output -OutVariable rustdesk_id

.\RustDesk.exe --config $rustdesk_cfg

.\RustDesk.exe--password $rustdesk_pw

Write-Output "..............................................."
# Show the value of the ID Variable
Write-Output "RustDesk ID: $rustdesk_id"

# Show the value of the Password Variable
Write-Output "Password: $rustdesk_pw"
Write-Output "..............................................."
