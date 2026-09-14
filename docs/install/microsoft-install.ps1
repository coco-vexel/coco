param(
  [string]$BaseUrl = '',
  [string]$Catalog = "$env:USERPROFILE\Documents\CocoOfficeAddins"
)
$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) { throw 'Missing -BaseUrl.' }
$BaseUrl = $BaseUrl.TrimEnd('/')
if (([Uri]$BaseUrl).Scheme -ne 'https') { throw 'Microsoft Office add-ins require an HTTPS release BaseUrl.' }
New-Item -ItemType Directory -Force -Path $Catalog | Out-Null
$items = @(
  @{ Name = 'Word'; Url = "$BaseUrl/microsoft/manifest.xml"; File = 'coco-microsoft-word.xml' },
  @{ Name = 'Excel'; Url = "$BaseUrl/microsoft/manifest-excel.xml"; File = 'coco-microsoft-excel.xml' }
)
foreach ($item in $items) {
  $dest = Join-Path $Catalog $item.File
  Invoke-WebRequest -UseBasicParsing $item.Url -OutFile $dest
  $releaseBase = $item.Url -replace '/microsoft/manifest(?:-excel)?.xml$', ''
  $releaseOrigin = ([Uri]$releaseBase).GetLeftPart([System.UriPartial]::Authority)
  $manifestText = Get-Content -Raw -Encoding UTF8 $dest
  $manifestText = $manifestText -replace 'https?://[^"''<>\s]+/microsoft', "$releaseBase/microsoft"
  $manifestText = $manifestText -replace '<AppDomain>https?://[^<]+</AppDomain>', "<AppDomain>$releaseOrigin</AppDomain>"
  Set-Content -Encoding UTF8 -LiteralPath $dest -Value $manifestText
  foreach ($ver in @('16.0','15.0')) {
    $devKey = "HKCU:\Software\Microsoft\Office\$ver\WEF\Developer"
    New-Item -Path $devKey -Force | Out-Null
    New-ItemProperty -Path $devKey -Name $dest -Value $dest -PropertyType String -Force | Out-Null
  }
  Write-Host "  $($item.Name): $dest"
}
Write-Host 'Coco Microsoft Word + Excel add-ins registered.' -ForegroundColor Green
Write-Host 'Fully quit and restart both Word and Excel.'
