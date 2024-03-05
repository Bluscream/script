@echo off
setlocal enabledelayedexpansion
:: Clear the log file on startup
echo Starting Runner at %date% %time%
title Runner - %date% %time%
:: Capture the command line arguments
set "args=%*"
:start
:: Log the command being executed
echo Executing: %args%
:: Start the application with the provided arguments and wait for it to close
start /wait /b "" %args%
:: Wait for 1 second before restarting the loop
timeout /t 1 /nobreak >nul
goto start
endlocal
