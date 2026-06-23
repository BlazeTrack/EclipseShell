@echo off
setlocal
cd /d "%~dp0"
"%cd%\gradle\wrapper\gradle-wrapper.jar" %*
