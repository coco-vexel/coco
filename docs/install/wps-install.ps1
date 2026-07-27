param(
  [string]$EntryUrl = '',
  [string]$PluginName = 'coco-wps'
)

$ErrorActionPreference = 'Stop'
if (-not $EntryUrl) {
  throw 'Missing -EntryUrl. Run this script from the command shown on install.html.'
}

function Get-PublishXmlCandidates {
  $homeDir = [Environment]::GetFolderPath('UserProfile')
  $paths = @()
  if ($env:APPDATA) {
    $paths += Join-Path $env:APPDATA 'kingsoft\wps\jsaddons\publish.xml'
  }
  if ($env:LOCALAPPDATA) {
    $paths += Join-Path $env:LOCALAPPDATA 'Kingsoft\WPS Office\jsaddons\publish.xml'
  }
  $paths += Join-Path $homeDir '.kingsoft\wps\jsaddons\publish.xml'
  return $paths
}

$candidates = Get-PublishXmlCandidates
$publishXml = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $publishXml) {
  $publishXml = $candidates[0]
  New-Item -ItemType Directory -Force -Path (Split-Path $publishXml) | Out-Null
  '<?xml version="1.0" encoding="utf-8"?>' + [Environment]::NewLine + '<jsplugins>' + [Environment]::NewLine + '</jsplugins>' + [Environment]::NewLine | Set-Content -Encoding UTF8 $publishXml
}

$xml = Get-Content -Raw -Encoding UTF8 $publishXml
$entry = '  <jspluginonline name="' + $PluginName + '" type="wps" url="' + $EntryUrl + '" debug="" enable="enable_dev" install="null"/>'
$pattern = '(?m)^\s*<jspluginonline[^>]*name="' + [Regex]::Escape($PluginName) + '"[\s\S]*?/>\s*\r?\n?'

if ($xml -match $pattern) {
  $xml = [Regex]::Replace($xml, $pattern, $entry + [Environment]::NewLine)
} else {
  $xml = $xml -replace '</jsplugins>', ($entry + [Environment]::NewLine + '</jsplugins>')
}

Set-Content -Encoding UTF8 -Path $publishXml -Value $xml
Write-Host "Coco WPS plugin registered:" -ForegroundColor Green
Write-Host "  $EntryUrl"
Write-Host "publish.xml:"
Write-Host "  $publishXml"
Write-Host "Restart WPS Writer, then open the Coco entry from the ribbon."
