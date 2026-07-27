param(
  [string]$ManifestUrl = '',
  [string]$Catalog = "$env:USERPROFILE\Documents\CocoOfficeAddins"
)

$ErrorActionPreference = 'Stop'
if (-not $ManifestUrl) {
  throw 'Missing -ManifestUrl. Run this script from the command shown on install.html.'
}
$manifestUri = [Uri]$ManifestUrl
if ($manifestUri.Scheme -ne 'https') {
  throw "Microsoft Office dialogs require HTTPS. Open the HTTPS install page or pass -ManifestUrl https://... . Current: $ManifestUrl"
}
New-Item -ItemType Directory -Force -Path $Catalog | Out-Null
$dest = Join-Path $Catalog 'coco-microsoft-manifest.xml'
Invoke-WebRequest -Uri $ManifestUrl -OutFile $dest

$releaseBase = $ManifestUrl -replace '/microsoft/manifest\.xml$', ''
$releaseOrigin = ([Uri]$releaseBase).GetLeftPart([System.UriPartial]::Authority)
$manifestText = Get-Content -Raw -Encoding UTF8 $dest
$manifestText = $manifestText -replace 'https?://[^"''<>\s]+/microsoft', "$releaseBase/microsoft"
$manifestText = $manifestText -replace '<AppDomain>https?://[^<]+</AppDomain>', "<AppDomain>$releaseOrigin</AppDomain>"
Set-Content -Encoding UTF8 -Path $dest -Value $manifestText

# Auto sideload via the WEF\Developer registry key (HKCU): points Office at the local
# manifest file. No admin, no network share, no manual Trust Center. A "Trusted Add-in
# Catalog" only accepts a UNC/SharePoint path (a local folder path is silently ignored),
# so the developer key is the reliable per-user way to sideload a self-hosted add-in.
foreach ($ver in @('16.0','15.0')) {
  $devKey = "HKCU:\Software\Microsoft\Office\$ver\WEF\Developer"
  try {
    New-Item -Path $devKey -Force | Out-Null
    New-ItemProperty -Path $devKey -Name $dest -Value $dest -PropertyType String -Force | Out-Null
  } catch { }
}

Write-Host "Coco Microsoft add-in registered:" -ForegroundColor Green
Write-Host "  manifest: $dest"
Write-Host "  sideload: HKCU\...\Office\16.0\WEF\Developer (no admin / no network share)"
Write-Host ""
Write-Host "Finish setup:"
Write-Host "  1. FULLY close Word (all windows), then reopen it."
Write-Host "  2. Home / Insert tab -> the Coco button (from the manifest ribbon),"
Write-Host "     or Insert -> My Add-ins -> Coco is listed."
Write-Host ""
Write-Host "If it still doesn't show: ensure Word was fully closed first, and that the"
Write-Host "release server (the SourceLocation host in the manifest) is reachable."
