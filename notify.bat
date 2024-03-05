@REM @echo off
set title=%COMPUTERNAME%\%USERNAME%

start /MIN /WAIT "toast" "%USERPROFILE%\.dotnet\tools\toast.exe" "%title%" %*
start /MIN /WAIT "hass-notify" "C:\Windows\System32\windowspowershell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "C:\Scripts\hass-notify.ps1" "%title%" %*
pause