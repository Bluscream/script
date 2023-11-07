@echo off
setlocal
::_______________________________________________________________________
::
::      SETTINGS
::_______________________________________________________________________
::
    set UNZIP=C:\Users\blusc\scoop\apps\7zip\current\7z.exe
    set OUTPUT="%~dpn1%.EFU"

    set VERSION=0.2
    set AUTHOR=Maarten

::_______________________________________________________________________
::
::      INIT
::_______________________________________________________________________
::

::  Get SFN for %UNZIP% (to prevent a bug in FOR loop)
    for %%a in ("%UNZIP%") Do set UNZIP=%%~sa

    echo Filename,Size,Date Modified,Date Created,Attributes> %OUTPUT%

    
::_______________________________________________________________________
::
::      START
::_______________________________________________________________________
::
    echo.
    echo.____________________[ Version %VERSION% by %AUTHOR% ]_______________________
    echo.
    
    for /f "delims=" %%x in (%1) DO call :THISZIP "%%~x"


    echo._____________________________________________________________________
    echo.
    ECHO.           OUTPUT can be found in :
    ECHO.           %OUTPUT%
    echo.
    pause

goto :EOF




::=======================================================================
::=======================================================================
::      SUBS
::=======================================================================
::=======================================================================


::_______________________________________________________________________
::
:THISZIP
::_______________________________________________________________________
::
    echo Parsing ... %1
    set FILENAME=%~1
    set DOEN=0
    for /f "usebackq delims=" %%a in (`%UNZIP% L ""%1""`) DO call :PARSELINE "%%a"
goto :EOF
    
 

::_______________________________________________________________________
::
:PARSELINE
::_______________________________________________________________________
::
        set ff=%~1
        if "%ff:~0,10%" == "----------" (set /a DOEN=!%DOEN% & goto :EOF)
        if %DOEN% == 0 goto :EOF

        set NAMEPART=%ff:~53%
        set DATEPART=%ff:~0,10%
        for /f %%X in ("%DATEPART%") DO set DATEPART=%%X
        set SIZEPART=%ff:~27,12%
        for /f %%X in ("%SIZEPART%") DO set SIZEPART=%%X
        rem for /f "tokens=1-4" %%A in ("%ff%") DO (set DATEPART=%%A&set SIZEPART=%%D)

        echo."%FILENAME%\%NAMEPART%",%SIZEPART%,%DATEPART%,, >>%OUTPUT%
goto :EOF   

