@echo off
title Reparador de Git - EclipseShell
echo ===================================================
echo     REPARANDO PUNTERO CORRUPTO DE GIT...
echo ===================================================
echo.

:: 1. Intentar borrar el archivo main corrupto en cmd y powershell
if exist .git\refs\heads\main (
    echo [INFO] Eliminando archivo corrupto 'main'...
    del /f /q .git\refs\heads\main
) else (
    echo [INFO] El archivo .git\refs\heads\main ya no existe o se borrara con PowerShell.
)

:: Por si las moscas, forzar el borrado usando PowerShell internamente
powershell -Command "if (Test-Path '.git\refs\heads\main') { Remove-Item '.git\refs\heads\main' -Force; echo '[INFO] Forzado con PowerShell exitosamente.' }"

echo.
echo ===================================================
echo     SINCRONIZANDO CON EL REPOSITORIO REMOTO...
echo ===================================================
echo.

:: 2. Traer el historial limpio de GitHub
echo [EJECUTANDO] git fetch origin...
git fetch origin

echo.
:: 3. Reajustar el puntero local guardando tus cambios intactos
echo [EJECUTANDO] git reset --soft origin/main...
git reset --soft origin/main

echo.
echo ===================================================
echo     ¡PROCESO COMPLETADO CON EXITO!
echo ===================================================
echo Tus archivos en verde listos para commit no se perdieron.
echo Ya puedes volver a usar VS Code o GitHub Desktop normalmente.
echo.
pause