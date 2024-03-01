@echo off
setlocal enabledelayedexpansion

REM Check if 7-Zip is installed
where 7z.exe >nul 2>nul
if errorlevel 1 (
    echo 7-Zip is not installed. Please install it and try again.
    exit /b 1
)

REM Loop through each argument (folder path)
for %%A in (%*) do (
    REM Get the folder name
    for %%B in ("%%~dpA.") do set "folderName=%%~nxB"
    
    REM Compress the folder
    7z a -tzip "!folderName!.zip" "%%~dpA*" -r -mx9
)

echo Done compressing folders.
pause
