@echo off
setlocal enabledelayedexpansion

set "log_file=%TEMP%\toast_history.log"
set "timestamp=%date% %time%"

@echo off
set title=%COMPUTERNAME%\%USERNAME%
echo !timestamp!;%title%;%* >> "%log_file%"
"C:\Windows\System32\windowspowershell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "C:\Scripts\hass-notify.ps1" "%title%" %*
start /MIN /WAIT "toast" "C:\Scripts\toast.exe" %1 %title%

IF %ERRORLEVEL% NEQ 0 (
    @REM echo !timestamp! ERROR: Failed to display toast notification. Error level: %ERRORLEVEL% >> "%log_file%"
    start /MIN /WAIT "toast" "%USERPROFILE%\.dotnet\tools\toast.exe" "%title%" %*
)
exit /b