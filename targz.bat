@echo off
setlocal enabledelayedexpansion

:: Check for 7-Zip executables
for %%e in (7z.exe 7za.exe 7zg.exe) do (
    where /q %%e
    if !errorlevel! equ 0 (
        set "sevenzipExe=%%e"
        goto :compress
    )
)

:: If none of the executables are found, exit the script
echo 7-Zip executable not found. Please install 7-Zip.
exit /b 1

:compress
:: The rest of the script assumes %sevenzipExe% contains the path to the 7-Zip executable

:: Check if at least two arguments are provided (output archive name and at least one file/folder path)
if "%~2"=="" (
    echo Usage: %~nx0 [outputArchive.tar.gz] [file/folder1] [file/folder2] ... [file/folderN]
    exit /b 1
)

:: Set the output archive name from the first argument
set "outputArchive=%~1"

:: Remove the first argument from the list of arguments to pass to the 7z command
shift

:: Compress the files/folders
"%sevenzipExe%" a -ttar -so "%outputArchive%" %* | "%sevenzipExe%" a -si -tgzip "%outputArchive%"

echo Compression completed. The archive is %outputArchive%.
