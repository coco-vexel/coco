@echo off
setlocal
set "ENTRY_URL=%~1"
set "PLUGIN_NAME=%~2"
if "%PLUGIN_NAME%"=="" set "PLUGIN_NAME=coco-wps"
if "%ENTRY_URL%"=="" (
  echo Missing entry URL.
  exit /b 1
)

set "PUBLISH_XML="
if not "%APPDATA%"=="" if exist "%APPDATA%\kingsoft\wps\jsaddons\publish.xml" set "PUBLISH_XML=%APPDATA%\kingsoft\wps\jsaddons\publish.xml"
if "%PUBLISH_XML%"=="" if not "%LOCALAPPDATA%"=="" if exist "%LOCALAPPDATA%\Kingsoft\WPS Office\jsaddons\publish.xml" set "PUBLISH_XML=%LOCALAPPDATA%\Kingsoft\WPS Office\jsaddons\publish.xml"
if "%PUBLISH_XML%"=="" if not "%APPDATA%"=="" set "PUBLISH_XML=%APPDATA%\kingsoft\wps\jsaddons\publish.xml"
if "%PUBLISH_XML%"=="" set "PUBLISH_XML=%USERPROFILE%\.kingsoft\wps\jsaddons\publish.xml"

for %%D in ("%PUBLISH_XML%") do if not exist "%%~dpD" mkdir "%%~dpD"
set "JS=%TEMP%\coco-wps-install-%RANDOM%.js"
> "%JS%" echo var fs = new ActiveXObject('Scripting.FileSystemObject');
>> "%JS%" echo var path = WScript.Arguments.Item(0), name = WScript.Arguments.Item(1), url = WScript.Arguments.Item(2);
>> "%JS%" echo function readText(file){ if(!fs.FileExists(file)) return '^<?xml version="1.0" encoding="utf-8"?^>\r\n^<jsplugins^>\r\n^</jsplugins^>\r\n'; var s=new ActiveXObject('ADODB.Stream'); s.Type=2; s.Charset='utf-8'; s.Open(); s.LoadFromFile(file); var t=s.ReadText(); s.Close(); return t; }
>> "%JS%" echo function writeText(file,text){ var s=new ActiveXObject('ADODB.Stream'); s.Type=2; s.Charset='utf-8'; s.Open(); s.WriteText(text); s.SaveToFile(file,2); s.Close(); }
>> "%JS%" echo function escXml(v){ return String(v).replace(/^&/g,'^&amp;').replace(/^</g,'^&lt;').replace(/^>/g,'^&gt;').replace(/"/g,'^&quot;'); }
>> "%JS%" echo function escRe(v){ return String(v).replace(/[\\^$.*+?()[\]{}^|]/g,'\\$^&'); }
>> "%JS%" echo var xml = readText(path);
>> "%JS%" echo if (xml.indexOf('^<jsplugins') ^< 0) xml = '^<?xml version="1.0" encoding="utf-8"?^>\r\n^<jsplugins^>\r\n' + xml + '\r\n^</jsplugins^>\r\n';
>> "%JS%" echo var entry = '  ^<jspluginonline name="' + escXml(name) + '" type="wps" url="' + escXml(url) + '" debug="" enable="enable_dev" install="null"/^>';
>> "%JS%" echo var re = new RegExp('^\\s*^<jspluginonline[^\n\r^>]*name="' + escRe(name) + '"[\\s\\S]*?/^>\\s*','m');
>> "%JS%" echo if (re.test(xml)) xml = xml.replace(re, entry + '\r\n'); else xml = xml.replace(/^<\/jsplugins^>/, entry + '\r\n^</jsplugins^>');
>> "%JS%" echo writeText(path, xml);

cscript //nologo "%JS%" "%PUBLISH_XML%" "%PLUGIN_NAME%" "%ENTRY_URL%"
set "RC=%ERRORLEVEL%"
del "%JS%" >nul 2>nul
if not "%RC%"=="0" exit /b %RC%

echo Coco WPS plugin registered:
echo   %ENTRY_URL%
echo publish.xml:
echo   %PUBLISH_XML%
echo Restart WPS Writer, then open the Coco entry from the ribbon.
