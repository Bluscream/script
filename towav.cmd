@echo off
setlocal enabledelayedexpansion

REM Check if LAME is available
where /q lame.exe
if errorlevel 1 (
    echo LAME not found. Please install LAME and add it to your PATH.
    exit /b
)

REM Iterate over all dropped MP3 files
for %%A in (%*) do (
    REM Extract filename without extension
    set "filename=%%~nA"
    
    REM Convert MP3 to WAV using LAME
    lame.exe -m s --preset standard "%%A" "!filename!.wav"
)

echo Conversion completed.
pause
