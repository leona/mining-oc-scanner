@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
setlocal
cd /d %~dp0
python3 src/app.py --restore 1
pause
