@echo off
echo logon-command-lief > C:\shared\marker.txt
powershell -NoProfile -ExecutionPolicy Bypass -File C:\shared\start.ps1 > C:\shared\powershell.log 2>&1
echo powershell-fertig-code-%ERRORLEVEL% >> C:\shared\marker.txt
