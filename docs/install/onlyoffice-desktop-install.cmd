@echo off
setlocal
set "BASE_URL=%~1"
set "API_BASE_URL=%~2"
if "%BASE_URL%"=="" (
  echo Missing release base URL.
  exit /b 1
)
call :validate_url "%BASE_URL%" "release BaseUrl" || exit /b 1
if not "%API_BASE_URL%"=="" (
  call :validate_url "%API_BASE_URL%" "API base URL" || exit /b 1
)
if "%LOCALAPPDATA%"=="" (
  echo LOCALAPPDATA is not available.
  exit /b 1
)

set "GUID={8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
set "ASC_GUID=asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
set "PLUGIN_ROOT=%LOCALAPPDATA%\ONLYOFFICE\DesktopEditors\data\sdkjs-plugins"
set "PLUGIN_DIR=%PLUGIN_ROOT%\%GUID%"

if exist "%PLUGIN_ROOT%\%ASC_GUID%" rmdir /s /q "%PLUGIN_ROOT%\%ASC_GUID%"
if exist "%PLUGIN_DIR%" rmdir /s /q "%PLUGIN_DIR%"
mkdir "%PLUGIN_DIR%\resources\light" >nul 2>nul

call :download "%BASE_URL%/onlyoffice/resources/light/icon.png" "%PLUGIN_DIR%\resources\light\icon.png" || exit /b 1
call :download "%BASE_URL%/onlyoffice/resources/light/icon@2x.png" "%PLUGIN_DIR%\resources\light\icon@2x.png" || exit /b 1
call :download "%BASE_URL%/onlyoffice/index.html?v=ms7e0gz5" "%PLUGIN_DIR%\index.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/settings.html?v=ms7e0gz5" "%PLUGIN_DIR%\settings.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/workflow-editor.html?v=ms7e0gz5" "%PLUGIN_DIR%\workflow-editor.html" || exit /b 1

rem Use PowerShell for post-processing. Windows Script Host may run old JScript
rem engines where JSON and modern regexp behavior are unreliable.
set "PS1=%TEMP%\coco-onlyoffice-desktop-%RANDOM%.ps1"
> "%PS1%" echo param([string]$Dir,[string]$BaseUrl,[string]$ApiBaseUrl)
>> "%PS1%" echo $ErrorActionPreference = 'Stop'
>> "%PS1%" echo foreach ($name in @('index.html','settings.html','workflow-editor.html')) {
>> "%PS1%" echo   $path = Join-Path $Dir $name
>> "%PS1%" echo   $html = Get-Content -LiteralPath $path -Raw -Encoding UTF8
>> "%PS1%" echo   $html = $html -replace '(["''])\./v1/', '$1../v1/'
>> "%PS1%" echo   $html = $html -replace '(["''])\./assets/', ('$1' + $BaseUrl + '/onlyoffice/assets/')
>> "%PS1%" echo   if ($ApiBaseUrl) { $html = $html -replace '</head>', '  ^<script src="./coco-runtime-config.js"^>^</script^>^</head^>' }
>> "%PS1%" echo   Set-Content -LiteralPath $path -Value $html -Encoding UTF8
>> "%PS1%" echo }
>> "%PS1%" echo if ($ApiBaseUrl) {
>> "%PS1%" echo   $runtime = 'window.__COCO_RUNTIME_CONFIG__ = ' + (@{ apiBaseUrl = $ApiBaseUrl } ^| ConvertTo-Json -Compress) + ';'
>> "%PS1%" echo   Set-Content -LiteralPath (Join-Path $Dir 'coco-runtime-config.js') -Value $runtime -Encoding UTF8
>> "%PS1%" echo }
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%PLUGIN_DIR%" "%BASE_URL%" "%API_BASE_URL%"
set "RC=%ERRORLEVEL%"
del "%PS1%" >nul 2>nul
if not "%RC%"=="0" exit /b %RC%

> "%PLUGIN_DIR%\config.json" echo {
>> "%PLUGIN_DIR%\config.json" echo   "name": "Coco",
>> "%PLUGIN_DIR%\config.json" echo   "nameLocale": { "zh": "Coco", "en": "Coco" },
>> "%PLUGIN_DIR%\config.json" echo   "guid": "%ASC_GUID%",
>> "%PLUGIN_DIR%\config.json" echo   "version": "0.0.1",
>> "%PLUGIN_DIR%\config.json" echo   "minVersion": "7.0.0",
>> "%PLUGIN_DIR%\config.json" echo   "variations": [
>> "%PLUGIN_DIR%\config.json" echo     {
>> "%PLUGIN_DIR%\config.json" echo       "description": "Coco",
>> "%PLUGIN_DIR%\config.json" echo       "descriptionLocale": { "zh": "Coco" },
>> "%PLUGIN_DIR%\config.json" echo       "url": "index.html",
>> "%PLUGIN_DIR%\config.json" echo       "icons": ["resources/light/icon.png", "resources/light/icon@2x.png"],
>> "%PLUGIN_DIR%\config.json" echo       "isViewer": true,
>> "%PLUGIN_DIR%\config.json" echo       "EditorsSupport": ["word", "cell", "slide"],
>> "%PLUGIN_DIR%\config.json" echo       "isVisual": true,
>> "%PLUGIN_DIR%\config.json" echo       "isModal": false,
>> "%PLUGIN_DIR%\config.json" echo       "isInsideMode": true,
>> "%PLUGIN_DIR%\config.json" echo       "initDataType": "none",
>> "%PLUGIN_DIR%\config.json" echo       "initData": "",
>> "%PLUGIN_DIR%\config.json" echo       "isUpdateOften": false,
>> "%PLUGIN_DIR%\config.json" echo       "buttons": [],
>> "%PLUGIN_DIR%\config.json" echo       "size": [320, 600],
>> "%PLUGIN_DIR%\config.json" echo       "events": []
>> "%PLUGIN_DIR%\config.json" echo     }
>> "%PLUGIN_DIR%\config.json" echo   ]
>> "%PLUGIN_DIR%\config.json" echo }

echo Coco ONLYOFFICE Desktop local shell installed:
echo   %PLUGIN_DIR%
if not "%API_BASE_URL%"=="" (
  echo API:
  echo   %API_BASE_URL%
)
echo Fully quit and restart ONLYOFFICE Desktop Editors.
exit /b 0

:download
set "URL=%~1"
set "OUT=%~2"
curl -L -f -o "%OUT%" "%URL%" >nul 2>nul
if "%ERRORLEVEL%"=="0" exit /b 0
certutil -urlcache -split -f "%URL%" "%OUT%" >nul 2>nul
exit /b %ERRORLEVEL%

:validate_url
set "VALUE=%~1"
set "LABEL=%~2"
if /i "%VALUE:~0,8%"=="https://" exit /b 0
if /i "%VALUE:~0,17%"=="http://localhost" exit /b 0
if /i "%VALUE:~0,16%"=="http://127.0.0.1" exit /b 0
echo ONLYOFFICE Desktop requires an HTTPS %LABEL%, except localhost HTTP for local development.
exit /b 1
