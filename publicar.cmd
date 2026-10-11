@echo off
rem ============================================================
rem  BotMp3 - doble clic para publicar en GitLab y preparar la
rem  peticion a F-Droid.  Se abre PowerShell y se ejecuta todo.
rem ============================================================
title Publicar BotMp3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publicar.ps1"
echo.
echo Pulsa una tecla para cerrar...
pause >nul
