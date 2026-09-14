param([string]$BaseUrl = '')

$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) { throw 'Missing -BaseUrl.' }
$BaseUrl = $BaseUrl.TrimEnd('/')
$plugins = @(
  @{ Name = 'coco-wps'; Type = 'wps'; Url = "$BaseUrl/coco-wps/worker/word/" },
  @{ Name = 'coco-wps-et'; Type = 'et'; Url = "$BaseUrl/coco-wps/worker/excel/" }
)
$homeDir = [Environment]::GetFolderPath('UserProfile')
$candidates = @()
if ($env:APPDATA) { $candidates += Join-Path $env:APPDATA 'kingsoft\wps\jsaddons\publish.xml' }
if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA 'Kingsoft\WPS Office\jsaddons\publish.xml' }
$candidates += Join-Path $homeDir '.kingsoft\wps\jsaddons\publish.xml'
$publishXml = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $publishXml) {
  $publishXml = $candidates[0]
  New-Item -ItemType Directory -Force -Path (Split-Path $publishXml) | Out-Null
  '<?xml version="1.0" encoding="utf-8"?>' + [Environment]::NewLine + '<jsplugins>' + [Environment]::NewLine + '</jsplugins>' | Set-Content -Encoding UTF8 $publishXml
}
$xml = Get-Content -Raw -Encoding UTF8 $publishXml
foreach ($plugin in $plugins) {
  $entry = '  <jspluginonline name="' + $plugin.Name + '" type="' + $plugin.Type + '" url="' + $plugin.Url + '" debug="" enable="enable_dev" install="null"/>'
  $pattern = '(?m)^\s*<jspluginonline[^>]*name="' + [Regex]::Escape($plugin.Name) + '"[\s\S]*?/>\s*\r?\n?'
  if ($xml -match $pattern) { $xml = [Regex]::Replace($xml, $pattern, $entry + [Environment]::NewLine) }
  else { $xml = $xml -replace '</jsplugins>', ($entry + [Environment]::NewLine + '</jsplugins>') }
}
Set-Content -Encoding UTF8 -Path $publishXml -Value $xml
Write-Host 'Coco WPS Word + Excel plugins registered.' -ForegroundColor Green
Write-Host "  Word:  $($plugins[0].Url)"
Write-Host "  Excel: $($plugins[1].Url)"
Write-Host 'Fully quit and restart WPS Writer and WPS Spreadsheets.'
