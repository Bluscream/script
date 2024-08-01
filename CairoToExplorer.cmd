@echo off
taskkill /f /im explorer.exe
taskkill /f /im CairoDesktop.exe
runas /trustlevel:0x20000 /machine:amd64 explorer.exe
IF %ERRORLEVEL% NEQ 0 (
    start "" "explorer.exe"
)
pause
exit