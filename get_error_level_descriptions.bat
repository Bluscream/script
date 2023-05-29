@echo off

setlocal enabledelayedexpansion

set "output_file=error_codes.txt"

for /L %%i in (0,1,1000) do (
    set "error_code=%%i"
    for /F "delims=" %%j in ('net helpmsg !error_code! 2^>nul') do (
        echo !error_code!=%%j >> "%output_file%"
    )
)

echo Done! The output has been saved to "%output_file%".

endlocal
