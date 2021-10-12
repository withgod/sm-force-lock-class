@echo off

set TF2_ROOT=D:\games\srcds\tf2\tf
set SOURCEMOD_ROOT=%TF2_ROOT%\addons\sourcemod
set SPCOMP=%SOURCEMOD_ROOT%\scripting\spcomp.exe

cd %~dp0\..\

%SPCOMP% -o plugins\force-class-interval.smx scripting\force-class-interval.sp

copy plugins\force-class-interval.smx %SOURCEMOD_ROOT%\plugins
copy translations\force-class-interval.phrases.txt %SOURCEMOD_ROOT%\translations

pause
