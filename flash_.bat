REM @echo off
pause
adb reboot bootloader
fastboot devices
REM fastboot --disable-verity --disable-verification flash vbmeta D:\Downloads\vbmeta.img
fastboot format userdata
REM fastboot flash userdata "D:\Downloads\lavender_eea_global_images_V12.5.1.0.QFGEUXM_20210903.0000.00_10.0_eea\images\userdata.img"
fastboot flash system %1
fastboot format userdata
fastboot reboot
pause