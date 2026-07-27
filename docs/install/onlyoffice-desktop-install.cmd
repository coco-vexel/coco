@echo off
setlocal
set "BASE_URL=%~1"
set "API_BASE_URL=%~2"
if "%BASE_URL%"=="" (
  echo Missing release base URL.
  exit /b 1
)
call :validate_url "%BASE_URL%" "release BaseUrl" || exit /b 1
if "%API_BASE_URL%"=="" (
  echo Missing ONLYOFFICE Desktop API base URL.
  exit /b 1
)
call :validate_url "%API_BASE_URL%" "API base URL" || exit /b 1
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
call :download "%BASE_URL%/onlyoffice/index.html?v=ms2n6r7v" "%PLUGIN_DIR%\index.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/settings.html?v=ms2n6r7v" "%PLUGIN_DIR%\settings.html" || exit /b 1
call :download "%BASE_URL%/onlyoffice/workflow-editor.html?v=ms2n6r7v" "%PLUGIN_DIR%\workflow-editor.html" || exit /b 1

set "JS=%TEMP%\coco-onlyoffice-desktop-%RANDOM%.js"
> "%JS%" echo var fs = new ActiveXObject('Scripting.FileSystemObject');
>> "%JS%" echo var dir = WScript.Arguments.Item(0), base = WScript.Arguments.Item(1), guid = WScript.Arguments.Item(2), api = WScript.Arguments.Item(3);
>> "%JS%" echo function readText(file){ var s=new ActiveXObject('ADODB.Stream'); s.Type=2; s.Charset='utf-8'; s.Open(); s.LoadFromFile(file); var t=s.ReadText(); s.Close(); return t; }
>> "%JS%" echo function writeText(file,text){ var s=new ActiveXObject('ADODB.Stream'); s.Type=2; s.Charset='utf-8'; s.Open(); s.WriteText(text); s.SaveToFile(file,2); s.Close(); }
>> "%JS%" echo var files = ['index.html','settings.html','workflow-editor.html'];
>> "%JS%" echo for (var i=0;i^<files.length;i++){ var p=dir+'\\'+files[i]; var html=readText(p); html=html.replace(/(["'])\.\/v1\//g,'$1../v1/').replace(/(["'])\.\/assets\//g,'$1'+base+'/onlyoffice/assets/').replace('</head>','  ^<script src="./coco-runtime-config.js"^>^</script^>^</head^>'); writeText(p, html); }
>> "%JS%" echo var config = {name:'Coco',nameLocale:{zh:'Coco',en:'Coco'},guid:'asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}',version:'0.0.1',minVersion:'7.0.0',variations:[{description:'Coco',descriptionLocale:{zh:'Coco'},url:'index.html',icons:['resources/light/icon.png','resources/light/icon@2x.png'],isViewer:true,EditorsSupport:['word','cell','slide'],isVisual:true,isModal:false,isInsideMode:true,initDataType:'none',initData:'',isUpdateOften:false,buttons:[],size:[320,600],events:[]}]};
>> "%JS%" echo writeText(dir+'\\config.json', JSON.stringify(config, null, 2));
>> "%JS%" echo writeText(dir+'\\coco-runtime-config.js', 'window.__COCO_RUNTIME_CONFIG__ = ' + JSON.stringify({apiBaseUrl: api}, null, 2) + ';');
cscript //nologo "%JS%" "%PLUGIN_DIR%" "%BASE_URL%" "%ASC_GUID%" "%API_BASE_URL%"
set "RC=%ERRORLEVEL%"
del "%JS%" >nul 2>nul
if not "%RC%"=="0" exit /b %RC%

echo Coco ONLYOFFICE Desktop local shell installed:
echo   %PLUGIN_DIR%
echo API:
echo   %API_BASE_URL%
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
