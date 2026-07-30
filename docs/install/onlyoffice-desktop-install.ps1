param(
  [string]$BaseUrl = '',
  [string]$ApiBaseUrl = ''
)

$ErrorActionPreference = 'Stop'
function Test-CocoAllowedDesktopUrl([string]$Value) {
  if (-not $Value) {
    return $false
  }
  try {
    $uri = [System.Uri]::new($Value)
    if ($uri.Scheme -eq 'https') {
      return $true
    }
    return $uri.Scheme -eq 'http' -and ($uri.Host -eq 'localhost' -or $uri.Host -eq '127.0.0.1' -or $uri.Host -eq '::1')
  } catch {
    return $false
  }
}
if (-not $BaseUrl) {
  throw 'Missing -BaseUrl. Run this script from the command shown on install.html.'
}
if (-not (Test-CocoAllowedDesktopUrl $BaseUrl)) {
  throw 'ONLYOFFICE Desktop requires an HTTPS release BaseUrl, except localhost HTTP for local development. Open the HTTPS install page or pass -BaseUrl https://... .'
}
if ($ApiBaseUrl -and -not (Test-CocoAllowedDesktopUrl $ApiBaseUrl)) {
  throw 'ONLYOFFICE Desktop requires an HTTPS ApiBaseUrl, except localhost HTTP for local development. Pass -ApiBaseUrl https://.../api/v1 .'
}
$Guid = '{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'
$AscGuid = 'asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'

if (-not $env:LOCALAPPDATA) {
  throw 'LOCALAPPDATA is not available. This installer is for Windows ONLYOFFICE Desktop Editors.'
}

$PluginRoot = Join-Path $env:LOCALAPPDATA 'ONLYOFFICE\DesktopEditors\data\sdkjs-plugins'
$PluginDir = Join-Path $PluginRoot $Guid
$DocumentServerPluginDir = Join-Path $PluginRoot $AscGuid
foreach ($dir in @($PluginDir, $DocumentServerPluginDir)) {
  if (Test-Path $dir) {
    Remove-Item -LiteralPath $dir -Recurse -Force
  }
}
New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PluginDir 'resources\light') | Out-Null
Invoke-WebRequest -UseBasicParsing "$BaseUrl/onlyoffice/resources/light/icon.png" -OutFile (Join-Path $PluginDir 'resources\light\icon.png')
Invoke-WebRequest -UseBasicParsing "$BaseUrl/onlyoffice/resources/light/icon@2x.png" -OutFile (Join-Path $PluginDir 'resources\light\icon@2x.png')

$config = @{
  name = 'Coco'
  nameLocale = @{ zh = 'Coco 助手'; en = 'Coco' }
  guid = $AscGuid
  version = '0.0.1'
  minVersion = '7.0.0'
  variations = @(@{
    description = 'Coco 文档智能助手'
    descriptionLocale = @{ zh = 'Coco 文档智能助手' }
    url = 'index.html?v=ms7d07e7'
    icons = @("resources/light/icon.png", "resources/light/icon@2x.png")
    isViewer = $true
    EditorsSupport = @('word', 'cell', 'slide')
    isVisual = $true
    isModal = $false
    isInsideMode = $true
    initDataType = 'none'
    initData = ''
    isUpdateOften = $false
    buttons = @()
    size = @(320, 600)
    events = @()
  })
}

$config | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 (Join-Path $PluginDir 'config.json')
if ($ApiBaseUrl) {
  $runtimeConfig = 'window.__COCO_RUNTIME_CONFIG__ = ' + (@{ apiBaseUrl = $ApiBaseUrl } | ConvertTo-Json -Compress) + ';'
  Set-Content -Encoding UTF8 -LiteralPath (Join-Path $PluginDir 'coco-runtime-config.js') -Value $runtimeConfig
}

function Write-CocoRemoteShim([string]$FileName) {
  $remote = "$BaseUrl/onlyoffice/$($FileName)?v=ms7d07e7"
  $html = (Invoke-WebRequest -UseBasicParsing $remote).Content
  $html = $html -replace '(["''])\./v1/', '$1../v1/'
  $html = $html -replace '(["''])\./assets/', "`$1$BaseUrl/onlyoffice/assets/"
  if ($ApiBaseUrl) {
    $html = $html -replace '</head>', '  <script src="./coco-runtime-config.js"></script></head>'
  }
  Set-Content -Encoding UTF8 -LiteralPath (Join-Path $PluginDir $FileName) -Value $html
}

Write-CocoRemoteShim 'index.html'
Write-CocoRemoteShim 'settings.html'
Write-CocoRemoteShim 'workflow-editor.html'

Write-Host "Coco ONLYOFFICE Desktop local shell installed:" -ForegroundColor Green
Write-Host "  $PluginDir"
Write-Host "Remote UI:"
Write-Host "  $BaseUrl/onlyoffice/?v=ms7d07e7"
if ($ApiBaseUrl) {
  Write-Host "API:"
  Write-Host "  $ApiBaseUrl"
}
Write-Host "Fully quit and restart ONLYOFFICE Desktop Editors."
