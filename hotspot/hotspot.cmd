@REM Get current path

SET SCRIPT_PATH=%~dp0

@REM Run hotspot.ps1

PowerShell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\hotspot.ps1"  >> "%TEMP%\autohotspot.txt" 2>&1
