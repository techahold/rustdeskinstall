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
