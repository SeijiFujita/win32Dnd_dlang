@echo off
set path=C:\D\dmd.2.065.0\windows\bin;C:\D\dm\bin;


@echo on

dmd -g -wi -ofwin32Dnd.exe winMain.d debuglog.d utils.d data_object drop_source.d drop_target.d enum_format.d  lib/dmd_win32.lib -L/SUBSYSTEM:WINDOWS:5.01

@echo off
if NOT ERRORLEVEL 0 GOTO end


goto end


:end
pause
