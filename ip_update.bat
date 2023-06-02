@echo off
setlocal enabledelayedexpansion

for /f "delims=" %%i in ('hostname --all-ip-addresses 2^>nul') do set "ips=%%i"
if "%ips%"=="" (
    for /f "delims=" %%i in ('hostname -I 2^>nul') do set "ips=%%i"
)
set "ips=!ips: =,!"
set "ips=!ips:~0,-1!"

set "macs="
for /f "tokens=2" %%i in ('findstr /R /C:"..-..-..-..-..-.." /sys/class/net/*/address 2^>nul') do (
    if not defined macs (
        set "macs=%%i"
    ) else (
        set "macs=!macs!,%%i"
    )
)
set "macs=!macs:~1!"

set "hosts=http://minopia.de http://local.minopia.de http://remote.minopia.de http://192.168.2.38 http://192.168.2.39"

for %%h in (%hosts%) do (
    set "url=%%h/api/ip.php?name=homeserver^&domains=home.server,homeserver.ip,minopia.de,local.minopia.de,minopia.local,homeserver.pi,stackoverflow.minopia.de^&ips=!ips!^&macs=!macs!"
    echo !url!
    for /f "delims=" %%r in ('curl -m 5 !url! 2^>^&1') do set "response=%%r"
    echo !response!
    echo !response! | findstr /C:"Operation timed out" >nul && exit /b
)
