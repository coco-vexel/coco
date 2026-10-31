@echo off
setlocal
set "BASE_URL=%~1"
if "%BASE_URL%"=="" (echo Missing release base URL.& exit /b 1)
set "SCRIPT=%TEMP%\coco-%RANDOM%-onlyoffice-docker-install.ps1"
curl -L -f -o "%SCRIPT%" "%BASE_URL%/install/onlyoffice-docker-install.ps1" >nul 2>nul || exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -BaseUrl "%BASE_URL%" -Apply
set "RC=%ERRORLEVEL%"
del "%SCRIPT%" >nul 2>nul
exit /b %RC%
