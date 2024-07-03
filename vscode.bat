@echo off
setlocal enabledelayedexpansion

:: Check if exactly one argument is passed
if "%~1"=="" (
    echo No arguments supplied.
    exit /b
)
if not "%~2"=="" (
    echo Too many arguments supplied.
    exit /b
)

:: Function to validate URL
:validateUrl
set "url=%~1"
set "isValid=0"

rem Replace spaces with nothing and check if it starts with https://github.com/
set "cleanUrl=!url: =!"
if "!cleanUrl:~0,18!"=="https://github.com/" set "isValid=1"

rem Check if it starts with https://gitlab.com/
if !isValid! equ 0 (
    set "cleanUrl=!url: =!"
    if "!cleanUrl:~0,17!"=="https://gitlab.com/" set "isValid=1"
)

if !isValid! equ 1 (
    rem Clone the repository
    git clone "!url!" "%cd%\repository"
    
    rem Change directory to the cloned repo
    cd "%cd%\repository"
    
    rem Execute the command in the cloned directory
    start "" "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" .
) else (
    start "" "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" "%~1"
)

endlocal
