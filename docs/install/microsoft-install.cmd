@echo off
setlocal
set "MANIFEST_URL=%~1"
set "CATALOG=%~2"
if "%MANIFEST_URL%"=="" (
  echo Missing manifest URL.
  exit /b 1
)
if /i not "%MANIFEST_URL:~0,8%"=="https://" (
  echo Microsoft Office dialogs require HTTPS.
  exit /b 1
)
if "%CATALOG%"=="" set "CATALOG=%USERPROFILE%\Documents\CocoOfficeAddins"
if not exist "%CATALOG%" mkdir "%CATALOG%"
set "DEST=%CATALOG%\coco-microsoft-manifest.xml"

call :download "%MANIFEST_URL%" "%DEST%" || exit /b 1
reg add "HKCU\Software\Microsoft\Office\16.0\WEF\Developer" /v "%DEST%" /t REG_SZ /d "%DEST%" /f >nul 2>nul
reg add "HKCU\Software\Microsoft\Office\15.0\WEF\Developer" /v "%DEST%" /t REG_SZ /d "%DEST%" /f >nul 2>nul

echo Coco Microsoft add-in registered:
echo   manifest: %DEST%
echo Fully close Word, then reopen it.
exit /b 0

:download
set "URL=%~1"
set "OUT=%~2"
curl -L -f -o "%OUT%" "%URL%" >nul 2>nul
if "%ERRORLEVEL%"=="0" exit /b 0
certutil -urlcache -split -f "%URL%" "%OUT%" >nul 2>nul
exit /b %ERRORLEVEL%
