@echo off
set title=%COMPUTERNAME%\%USERNAME%
"C:\Windows\System32\windowspowershell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "C:\Scripts\hass-notify.ps1" "%title%" %*
start /MIN /WAIT "toast" "C:\Scripts\toast.exe" %1 %title%
IF %ERRORLEVEL% NEQ 0 (
    start /MIN /WAIT "toast" "%USERPROFILE%\.dotnet\tools\toast.exe" "%title%" %*
)
@REM pause
