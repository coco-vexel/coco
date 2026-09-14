param(
  [string]$Container = 'onlyoffice-documentserver',
  [string]$BaseUrl = '',
  [string]$ApiBaseUrl = '',
  [string]$OutDir = '',
  [switch]$Apply
)
$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) { throw 'Missing -BaseUrl.' }
$BaseUrl = $BaseUrl.TrimEnd('/')
function Test-CocoUrl([string]$Value) {
  try {
    $uri = [Uri]::new($Value)
    return $uri.Scheme -eq 'https' -or ($uri.Scheme -eq 'http' -and $uri.Host -in @('localhost','127.0.0.1','::1'))
  } catch { return $false }
}
if (-not (Test-CocoUrl $BaseUrl)) { throw 'ONLYOFFICE Docker requires HTTPS, except localhost development URLs.' }
if (-not $ApiBaseUrl) {
  $releaseRoot = $BaseUrl -replace '/coco$', ''
  $ApiBaseUrl = "$releaseRoot/api/v1"
}
$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')
if (-not (Test-CocoUrl $ApiBaseUrl)) { throw 'ApiBaseUrl must use HTTPS, except localhost.' }
if (-not $OutDir) { $OutDir = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'coco-onlyoffice-plugins' }
$root = '/var/www/onlyoffice/documentserver/sdkjs-plugins'
$plugins = @(
  @{ Label='Word'; Raw='{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'; Asc='asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}'; Config='config.json' },
  @{ Label='Excel'; Raw='{A9551FA7-1158-4A6E-9DE0-9A36684B7934}'; Asc='asc.{A9551FA7-1158-4A6E-9DE0-9A36684B7934}'; Config='config.excel.json' }
)
$pages = @('index.html','excel.html','settings.html','workflow-editor.html')
if (Test-Path $OutDir) { Remove-Item -LiteralPath $OutDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

foreach ($plugin in $plugins) {
  $dir = Join-Path $OutDir $plugin.Asc
  New-Item -ItemType Directory -Force -Path (Join-Path $dir 'resources\light') | Out-Null
  Invoke-WebRequest -UseBasicParsing "$BaseUrl/onlyoffice/$($plugin.Config)" -OutFile (Join-Path $dir 'config.json')
  foreach ($icon in @('icon.png','icon@2x.png')) {
    Invoke-WebRequest -UseBasicParsing "$BaseUrl/onlyoffice/resources/light/$icon" -OutFile (Join-Path $dir "resources\light\$icon")
  }
  $runtime = 'window.__COCO_RUNTIME_CONFIG__ = ' + (@{ apiBaseUrl=$ApiBaseUrl } | ConvertTo-Json -Compress) + ';'
  Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dir 'coco-runtime-config.js') -Value $runtime
  foreach ($page in $pages) {
    $html = (Invoke-WebRequest -UseBasicParsing "$BaseUrl/onlyoffice/$page?v=mszojqzi").Content
    $html = $html -replace '(["''])\./v1/', '$1../v1/'
    $html = $html -replace '(["''])\./assets/', "`$1$BaseUrl/onlyoffice/assets/"
    $html = $html -replace '(src=["''].*?/onlyoffice/assets/.*?\.js)(["''])', '$1?v=mszojqzi$2'
    $html = $html -replace '(href=["''].*?/onlyoffice/assets/.*?\.css)(["''])', '$1?v=mszojqzi$2'
    $html = $html -replace '</head>', '  <script src="./coco-runtime-config.js"></script></head>'
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dir $page) -Value $html
  }
  Write-Host "  $($plugin.Label): $dir"
}
Write-Host 'Coco ONLYOFFICE Word + Excel Docker packages generated.' -ForegroundColor Green
if ($Apply) {
  foreach ($plugin in $plugins) {
    docker exec $Container sh -lc "rm -rf '$root/$($plugin.Raw)' '$root/$($plugin.Asc)'"
    $source = Join-Path (Join-Path $OutDir $plugin.Asc) '.'
    docker cp "$source" "$Container`:$root/$($plugin.Asc)"
  }
  docker restart $Container | Out-Null
  Write-Host "Applied both plugins to $Container." -ForegroundColor Green
}
