@echo off
setlocal
set "CONTAINER=%~1"
set "BASE_URL=%~2"
set "APPLY=%~3"
if "%CONTAINER%"=="" set "CONTAINER=onlyoffice-documentserver"
if "%BASE_URL%"=="" (
  echo Missing release base URL.
  exit /b 1
)
set "API_BASE_URL=%BASE_URL:/coco=/api/v1%"
set "GUID={8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
set "ASC_GUID=asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
set "PLUGIN_ROOT=/var/www/onlyoffice/documentserver/sdkjs-plugins"
set "DEPLOY_PATH=%PLUGIN_ROOT%/%ASC_GUID%"
set "PLUGIN_DIR=%USERPROFILE%\Downloads\coco-onlyoffice-plugin\%ASC_GUID%"

rem ONLYOFFICE Docker cannot install a remote plugin URL directly. It reads the plugin
rem from /var/www/onlyoffice/documentserver/sdkjs-plugins inside the container, so this
rem script builds a local shim directory first and optionally docker-cp's it in.
if exist "%PLUGIN_DIR%" rmdir /s /q "%PLUGIN_DIR%"
mkdir "%PLUGIN_DIR%\resources\light" >nul 2>nul
call :download "%BASE_URL%/onlyoffice/resources/light/icon.png" "%PLUGIN_DIR%\resources\light\icon.png" || exit /b 1
call :download "%BASE_URL%/onlyoffice/resources/light/icon@2x.png" "%PLUGIN_DIR%\resources\light\icon@2x.png" || exit /b 1
call :download "%BASE_URL%/onlyoffice/index.html?v=ms7d07e7" "%PLUGIN_DIR%\index.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/settings.html?v=ms7d07e7" "%PLUGIN_DIR%\settings.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/workflow-editor.html?v=ms7d07e7" "%PLUGIN_DIR%\workflow-editor.html" || exit /b 1

rem Use a temporary PowerShell helper for JSON/string rewriting. Windows Script Host
rem JScript can be too old on some machines and may not provide JSON, which previously
rem caused "JSON is undefined" during install.
set "PS1=%TEMP%\coco-onlyoffice-docker-%RANDOM%.ps1"
> "%PS1%" echo param([string]$Dir,[string]$BaseUrl,[string]$ApiBaseUrl)
>> "%PS1%" echo $ErrorActionPreference = 'Stop'
>> "%PS1%" echo $runtime = 'window.__COCO_RUNTIME_CONFIG__ = ' + (@{ apiBaseUrl = $ApiBaseUrl } ^| ConvertTo-Json -Compress) + ';'
>> "%PS1%" echo Set-Content -Encoding UTF8 -LiteralPath (Join-Path $Dir 'coco-runtime-config.js') -Value $runtime
>> "%PS1%" echo foreach ($name in @('index.html','settings.html','workflow-editor.html')) {
>> "%PS1%" echo   $path = Join-Path $Dir $name
>> "%PS1%" echo   $html = Get-Content -Raw -LiteralPath $path
>> "%PS1%" echo   # ONLYOFFICE plugin APIs are served by Document Server next to the plugin.
>> "%PS1%" echo   $html = $html -replace '(["''])\./v1/', '$1../v1/'
>> "%PS1%" echo   # Assets stay on the Coco release host; the shim keeps stable filenames.
>> "%PS1%" echo   # Updating server assets then takes effect without reinstalling the Docker plugin.
>> "%PS1%" echo   $html = $html -replace '(["''])\./assets/', ('$1' + $BaseUrl + '/onlyoffice/assets/')
>> "%PS1%" echo   # Runtime config must load before the Vite module bundle.
>> "%PS1%" echo   $html = $html -replace '</head>', '  ^<script src="./coco-runtime-config.js"^>^</script^>^</head^>'
>> "%PS1%" echo   Set-Content -Encoding UTF8 -LiteralPath $path -Value $html
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
>> "%PLUGIN_DIR%\config.json" echo       "url": "index.html?v=ms7d07e7",
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

echo Coco ONLYOFFICE Docker plugin package generated:
echo   %PLUGIN_DIR%
echo.
echo Deploy this directory to ONLYOFFICE Document Server:
echo   %DEPLOY_PATH%
echo.
echo Example:
echo   docker cp "%PLUGIN_DIR%\." "%CONTAINER%:%DEPLOY_PATH%"
echo   docker restart "%CONTAINER%"
echo.
echo Remote UI:
echo   %BASE_URL%/onlyoffice/?v=ms7d07e7
echo API:
echo   %API_BASE_URL%

if /i "%APPLY%"=="apply" (
  docker exec "%CONTAINER%" sh -lc "rm -rf '%PLUGIN_ROOT%/%ASC_GUID%' '%PLUGIN_ROOT%/%GUID%'" || exit /b 1
  docker cp "%PLUGIN_DIR%\." "%CONTAINER%:%DEPLOY_PATH%" || exit /b 1
  docker restart "%CONTAINER%" >nul || exit /b 1
  echo.
  echo Applied to container:
  echo   %CONTAINER%
)

exit /b 0

:download
set "URL=%~1"
set "OUT=%~2"
curl -L -f -o "%OUT%" "%URL%" >nul 2>nul
if "%ERRORLEVEL%"=="0" exit /b 0
certutil -urlcache -split -f "%URL%" "%OUT%" >nul 2>nul
exit /b %ERRORLEVEL%
