@echo off
set title=%COMPUTERNAME%\%USERNAME%

toast "%title%" "%*"
powershell -ExecutionPolicy Bypass -File C:\Scripts\hass-notify.ps1 "%*" "%title%"