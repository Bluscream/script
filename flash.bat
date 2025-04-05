@echo off
setlocal enabledelayedexpansion

REM Check if fastboot is available
fastboot --version >nul 2>&1
if errorlevel 1 (
    echo Error: fastboot is not in your PATH
    pause
    exit /b 1
)

REM Ask for confirmation before proceeding
echo.
echo Warning: This will flash new partitions to your device.
echo Are you sure you want to continue? (Y/N)
set /p confirm=""

if /i not "!confirm!"=="Y" (
    echo Operation cancelled by user
    pause
    exit /b 0
)

echo.


REM Process each dropped file
for %%i in (%*) do (
    REM Get the filename without extension
    for %%j in ("%%~ni") do (
        echo Processing %%j...
        
        REM Execute the flash command
        fastboot flash %%j %%i
        REM >nul 2>&1
        
        REM Check success/failure
        if !errorlevel! equ 0 (
            echo Success: Flashed %%j
        ) else (
            echo Failed: Could not flash %%j
        )
    )
)

pause