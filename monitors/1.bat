@ECHO OFF

MultiMonitorTool.exe /SetMonitors "Name=SAM08AC Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" "Name=MAC0101 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0" "Name=MED07B8 BitsPerPixel=0 Width=0 Height=0 DisplayFlags=0 DisplayFrequency=0 DisplayOrientation=0 PositionX=0 PositionY=0" "Name=HJW0001 BitsPerPixel=0 Width=0 Height=0 DisplayFlags=0 DisplayFrequency=0 DisplayOrientation=0 PositionX=0 PositionY=0"
@REM EXIT /B

@REM MONITOR\SAM08AC\{4d36e96e-e325-11ce-bfc1-08002be10318}\0005
MultiMonitorTool.exe /SetMonitors "Name=SAM08AC Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"
@REM MONITOR\MAC0101\{4d36e96e-e325-11ce-bfc1-08002be10318}\0009
MultiMonitorTool.exe /SetMonitors "Name=MAC0101 Primary=1 BitsPerPixel=32 Width=1920 Height=1080 DisplayFlags=0 DisplayFrequency=60 DisplayOrientation=0 PositionX=0 PositionY=0"

@REM MONITOR\MED07B8\{4d36e96e-e325-11ce-bfc1-08002be10318}\0003
MultiMonitorTool.exe /SetMonitors "Name=MED07B8 BitsPerPixel=0 Width=0 Height=0 DisplayFlags=0 DisplayFrequency=0 DisplayOrientation=0 PositionX=0 PositionY=0"

@REM MONITOR\HJW0001\{4d36e96e-e325-11ce-bfc1-08002be10318}\0004
MultiMonitorTool.exe /SetMonitors "Name=HJW0001 BitsPerPixel=0 Width=0 Height=0 DisplayFlags=0 DisplayFrequency=0 DisplayOrientation=0 PositionX=0 PositionY=0"

EXIT /B