# Runs on the Windows build machine (#125). Called by tool/release.sh after
# the source archive was unpacked into $Work and the Xapian DLL from the
# Linux machine was put into native\zim_xapian\build.
#
# Builds the app and packs the release folder into one zip. Unsigned: the
# signed distribution road is tool/windows_release.ps1, which needs an
# Authenticode certificate this project does not have yet.
param(
  [Parameter(Mandatory = $true)] [string] $Work,
  [Parameter(Mandatory = $true)] [string] $Version,
  [Parameter(Mandatory = $true)] [string] $BuildNumber,
  [string] $ToolPath = 'C:\src\tools;C:\src\flutter\bin'
)

$ErrorActionPreference = 'Stop'
$env:PATH = "$ToolPath;" + $env:PATH
Set-Location (Join-Path $Work 'src\preppsuite_flutter')
if (-not (Test-Path native\zim_xapian\build\zim_xapian.dll)) { throw 'zim_xapian.dll fehlt' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'pub get fehlgeschlagen' }
flutter build windows --release --build-name $Version --build-number $BuildNumber
if ($LASTEXITCODE -ne 0) { throw 'build fehlgeschlagen' }

$release = 'build\windows\x64\runner\Release'
Write-Output "== Dateien: $((Get-ChildItem $release -Recurse -File).Count) =="
if (-not (Test-Path (Join-Path $release 'zim_xapian.dll'))) { throw 'zim_xapian.dll nicht im Paket' }

# The start test (#142): the package's native libraries, loaded for real
# in a running app. Works over ssh without a signed-in desktop.
flutter test integration_test/app_start_test.dart -d windows
if ($LASTEXITCODE -ne 0) { throw 'Starttest fehlgeschlagen' }
Write-Output '== STARTTEST: BESTANDEN =='

$zip = Join-Path $Work "PreppSuite-$Version-windows-x64-unsigned-test.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $release '*') -DestinationPath $zip -Force
Write-Output "== Version: $((Get-Item (Join-Path $release 'PreppSuite.exe')).VersionInfo.ProductVersion) =="
Write-Output '== FERTIG =='
