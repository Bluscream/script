@echo off
taskkill /f /im explorer.exe
taskkill /f /im CairoDesktop.exe
SET ERRORLEVEL=0
runas /trustlevel:0x20000 /machine:amd64 "C:\Program Files\Cairo Shell\CairoDesktop.exe /restart=true /shell=true"
IF %ERRORLEVEL% NEQ 0 (
    start "" "C:\Program Files\Cairo Shell\CairoDesktop.exe" /restart=true /shell=true
)
exit