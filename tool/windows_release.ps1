[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Bundle,
  [Parameter(Mandatory = $true)] [string] $CertificateThumbprint,
  [Parameter(Mandatory = $true)] [string] $TimestampUrl,
  [string] $OutputDirectory = (Join-Path $PSScriptRoot '..\releases')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Bundle -PathType Container)) {
  throw "Release bundle was not found: $Bundle"
}

$signTool = (Get-Command signtool.exe -ErrorAction Stop).Source
$certificate = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction Stop
if (-not $certificate.HasPrivateKey) {
  throw 'The selected certificate has no private key.'
}

# The app loads plugins and native libraries at runtime. Signing just the EXE
# leaves the trust chain incomplete, so every executable PE file is covered.
$targets = Get-ChildItem $Bundle -Recurse -File |
  Where-Object { $_.Extension -in '.exe', '.dll' }
if ($targets.Count -eq 0) { throw 'No executable files found in release bundle.' }

foreach ($target in $targets) {
  & $signTool sign /sha1 $CertificateThumbprint /fd SHA256 /tr $TimestampUrl /td SHA256 $target.FullName
  if ($LASTEXITCODE -ne 0) { throw "Signing failed: $($target.FullName)" }
  $signature = Get-AuthenticodeSignature $target.FullName
  if ($signature.Status -ne 'Valid') {
    throw "Signature verification failed: $($target.FullName) ($($signature.Status))"
  }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$version = (Get-Item (Join-Path $Bundle 'PreppSuite.exe')).VersionInfo.ProductVersion
$archive = Join-Path $OutputDirectory "PreppSuite-$version-windows-x64.zip"
if (Test-Path $archive) { Remove-Item $archive -Force }
Compress-Archive -Path (Join-Path $Bundle '*') -DestinationPath $archive -Force
(Get-FileHash $archive -Algorithm SHA256).Hash.ToLower() + "  " + (Split-Path $archive -Leaf) |
  Set-Content -NoNewline "$archive.sha256"
Write-Output "Fertig: $archive"
