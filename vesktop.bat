@echo off
taskkill /f /im "Vesktop.exe"
timeout /t 1
REM start "" "C:\Users\blusc\AppData\Local\vesktop\Vesktop.exe"
"C:\Users\blusc\AppData\Local\vesktop\Vesktop.exe"
exit