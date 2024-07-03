@title OpenWebSearch Redux & echo off & set ?= open start menu web search, widgets links or help in your chosen browser - by AveYo
for /f %%E in ('"prompt $E$S& for %%e in (1) do rem"') do echo;%%E[2t 2>nul & rem AveYo: minimize prompt
call :reg_var "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID ProgID
if /i "%ProgID%" equ "MSEdgeHTM" echo;Default browser is set to Edge! Change it or remove OpenWebSearch script. & pause & exit /b
call :reg_var "HKCR\%ProgID%\shell\open\command" "" Browser
set Choice=& for %%. in (%Browser%) do if not defined Choice set "Choice=%%~."
call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set "Edge=" & for %%. in (%FallBack%) do if not defined Edge set "Edge=%%~."
set "URI=" & set "URL=" & set "NOOP=" & set "PassTrough=%Edge:msedge=edge%"
set "CLI=%CMDCMDLINE:"=``% "
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe`` =%"
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe =%"
if defined CLI set "CLI=%CLI:*msedge.exe`` =%"
if defined CLI set "CLI=%CLI:*msedge.exe =%"
set "FIX=%CLI:~-1%"
if defined CLI if "%FIX%"==" " set "CLI=%CLI:~0,-1%"
if defined CLI set "RED=%CLI:microsoft-edge=%"
if defined CLI set "URL=%CLI:http=%"
if defined CLI set "ARG=%CLI:``="%"
if "%CLI%" equ "%RED%" (set NOOP=1) else if "%CLI%" equ "%URL%" (set NOOP=1)
if defined NOOP if not exist "%PassTrough%" echo;@mklink /h "%PassTrough%" "%Edge%" >"%Temp%\OpenWebSearchRepair.cmd"
if defined NOOP if not exist "%PassTrough%" schtasks /run /tn OpenWebSearchRepair 2>nul >nul
if defined NOOP if not exist "%PassTrough%" timeout /t 3 >nul
if defined NOOP if exist "%PassTrough%" start "" "%PassTrough%" %ARG%
if defined NOOP exit /b
set "URL=%CLI:*microsoft-edge=%"
set "URL=http%URL:*http=%"
set "FIX=%URL:~-2%"
if defined URL if "%FIX%"=="``" set "URL=%URL:~0,-2%"
call :dec_url
start "" "%Choice%" "%URL%"
exit

:reg_var [USAGE] call :reg_var "HKCU\Volatile Environment" value-or-"" variable [extra options]
set {var}=& set {reg}=reg query "%~1" /v %2 /z /se "," /f /e& if %2=="" set {reg}=reg query "%~1" /ve /z /se "," /f /e
for /f "skip=2 tokens=* delims=" %%V in ('%{reg}% %4 %5 %6 %7 %8 %9 2^>nul') do if not defined {var} set "{var}=%%V"
if not defined {var} (set {reg}=& set "%~3="& exit /b) else if %2=="" set "{var}=%{var}:*)    =%"& rem AveYo: v3
if not defined {var} (set {reg}=& set "%~3="& exit /b) else set {reg}=& set "%~3=%{var}:*)    =%"& set {var}=& exit /b

:dec_url brute url percent decoding by AveYo
set ".=%URL:!=}%"&setlocal enabledelayedexpansion& rem brute url percent decoding
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%%!"&set ".=!.:{20= !"
set ".=!.:{=%%!" &rem set ",=!.:%%=!" & if "!,!" neq "!.!" endlocal& set "URL=%.:}=!%" & call :dec_url
endlocal& set "URL=%.:}=!%" & exit /b
rem done
