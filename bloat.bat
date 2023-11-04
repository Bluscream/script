@echo off
start /wait /min powershell.exe -executionpolicy ByPass -WindowStyle Hidden -File "C:\Scripts\kill_commandline.ps1" -PartialCommandLine "bloat.ahk" | ECHO > nul
start /wait "" "C:\Program Files\AutoHotKey\Scripts\bloat.ahk" /mybloat