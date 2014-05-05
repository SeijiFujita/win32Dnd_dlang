@echo off
set path=C:\D\dmd.2.065.0\windows\bin;C:\D\dm\bin;
@echo on

setlocal EnableDelayedExpansion
set "files="
for %%i in (..\win32\*.d) do set files=!files! %%i
dmd -g -I..\ -version=Unicode -version=WindowsXP -lib -ofdmd_win32_debug.lib %files%
dmd -O -I..\ -version=Unicode -version=WindowsXP -lib -ofdmd_win32.lib %files%
echo %files% > dmd_win32lib.txt
pause
