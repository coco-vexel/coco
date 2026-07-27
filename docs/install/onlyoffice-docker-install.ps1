param(
  [string]$Container = 'onlyoffice-documentserver',
  [string]$BaseUrl = '',
  [string]$ApiBaseUrl = '',
  [string]$OutDir = '',
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) {
  throw 'Missing -BaseUrl. Run this script from the command shown on install.html.'
}
if (-not $ApiBaseUrl) {
  $ApiBaseUrl = ([System.Uri]::new([System.Uri]::new($BaseUrl), '/api/v1')).AbsoluteUri.TrimEnd('/')
}
$Guid = '{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'
$AscGuid = 'asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'
$DeployPath = "/var/www/onlyoffice/documentserver/sdkjs-plugins/$AscGuid"
if (-not $OutDir) {
  $downloads = Join-Path $env:USERPROFILE 'Downloads'
  $OutDir = Join-Path $downloads 'coco-onlyoffice-plugin'
}
$PluginDir = Join-Path $OutDir $AscGuid
$DockerCopySource = Join-Path $PluginDir '.'
$PluginRoot = '/var/www/onlyoffice/documentserver/sdkjs-plugins'

if (Test-Path $PluginDir) { Remove-Item -Recurse -Force $PluginDir }
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
    url = 'index.html'
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
$runtimeConfig = 'window.__COCO_RUNTIME_CONFIG__ = ' + (@{ apiBaseUrl = $ApiBaseUrl } | ConvertTo-Json -Compress) + ';'
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $PluginDir 'coco-runtime-config.js') -Value $runtimeConfig

function Write-CocoRemoteShim([string]$FileName) {
  $remote = "$BaseUrl/onlyoffice/$($FileName)?v=ms2mp63y"
  $html = (Invoke-WebRequest -UseBasicParsing $remote).Content
  $html = $html -replace '(["''])\./v1/', '$1../v1/'
  $html = $html -replace '(["''])\./assets/', "`$1$BaseUrl/onlyoffice/assets/"
  $html = $html -replace '</head>', '  <script src="./coco-runtime-config.js"></script></head>'
  Set-Content -Encoding UTF8 -LiteralPath (Join-Path $PluginDir $FileName) -Value $html
}

Write-CocoRemoteShim 'index.html'
Write-CocoRemoteShim 'settings.html'
Write-CocoRemoteShim 'workflow-editor.html'

Write-Host "Coco ONLYOFFICE Docker plugin package generated:" -ForegroundColor Green
Write-Host "  $PluginDir"
Write-Host ""
Write-Host "Deploy this directory to ONLYOFFICE Document Server:"
Write-Host "  $DeployPath"
Write-Host ""
Write-Host "Example:"
Write-Host ('  docker cp "' + $DockerCopySource + '" "' + $Container + ':' + $DeployPath + '"')
Write-Host "  docker restart $Container"
Write-Host ""
Write-Host "Remote UI:"
Write-Host "  $BaseUrl/onlyoffice/?v=ms2mp63y"
Write-Host "API:"
Write-Host "  $ApiBaseUrl"

if ($Apply) {
  docker exec $Container sh -lc "rm -rf '$PluginRoot/$AscGuid' '$PluginRoot/$Guid'"
  docker cp "$DockerCopySource" "$Container`:$DeployPath"
  docker restart $Container | Out-Null

  Write-Host ""
  Write-Host "Applied to container:" -ForegroundColor Green
  Write-Host "  $Container"
}
