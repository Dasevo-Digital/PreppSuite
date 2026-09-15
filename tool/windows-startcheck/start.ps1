# The launch check, in a Windows that has never seen this app: no Visual
# Studio, no Flutter, and deliberately no Visual C++ Redistributable.
# That is the machine a user has.
#
# Nothing is installed here. If the package needs something the machine
# does not have, that is the package's problem to fix, not the tester's.
$ErrorActionPreference = 'Continue'
$out = 'C:\shared\start-result.txt'
'' | Set-Content $out
function Report($m) { Add-Content $out $m }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
function Shot($name) {
  try {
    $r = [Windows.Forms.Screen]::PrimaryScreen.Bounds
    $b = New-Object Drawing.Bitmap $r.Width, $r.Height
    $g = [Drawing.Graphics]::FromImage($b)
    $g.CopyFromScreen($r.X, $r.Y, 0, 0, $b.Size)
    $b.Save("C:\shared\$name.png"); $g.Dispose(); $b.Dispose()
  } catch { Report "Bildschirmfoto fehlgeschlagen: $_" }
}

# Proof that nothing was installed to help it along.
$vc = Get-ChildItem 'C:\Windows\System32\msvcp140.dll','C:\Windows\System32\vcruntime140.dll' -ErrorAction SilentlyContinue
Report ("Visual-C++-Laufzeit im System: " + $(if ($vc) { ($vc | ForEach-Object Name) -join ', ' } else { 'nein' }))

foreach ($zip in (Get-ChildItem 'C:\shared\*.zip' | Sort-Object Name)) {
  $dir = "C:\probe\$($zip.BaseName)"
  Report ''
  Report "=== $($zip.Name) ==="
  try { Expand-Archive -LiteralPath $zip.FullName -DestinationPath $dir -Force }
  catch { Report "ENTPACKEN FEHLGESCHLAGEN: $_"; continue }

  $exe = Get-ChildItem -Path $dir -Filter 'PreppSuite.exe' -Recurse | Select-Object -First 1
  if (-not $exe) { Report 'KEINE PreppSuite.exe GEFUNDEN'; continue }
  $crt = Get-ChildItem $exe.DirectoryName -Filter '*140*.dll' -ErrorAction SilentlyContinue
  Report ("Laufzeit im Paket: " + $(if ($crt) { ($crt | ForEach-Object Name) -join ', ' } else { 'keine' }))

  # Roaming as well as Local: path_provider puts an app's support folder
  # under %APPDATA%, and looking only in %LOCALAPPDATA% reported a
  # perfectly good start as "no database".
  $roots = @($env:APPDATA, $env:LOCALAPPDATA)
  $before = @(Get-ChildItem -Path $roots -Recurse -Filter 'preppsuite*' -ErrorAction SilentlyContinue)
  $p = Start-Process -FilePath $exe.FullName -WorkingDirectory $exe.DirectoryName -PassThru

  $db = $null
  for ($i = 0; $i -lt 25; $i++) {
    Start-Sleep -Seconds 2
    if ($p.HasExited) { break }
    $db = Get-ChildItem -Path $roots -Recurse -Filter 'preppsuite*.sqlite*' -ErrorAction SilentlyContinue |
          Where-Object { $before.FullName -notcontains $_.FullName } | Select-Object -First 1
    $p.Refresh()
    if ($db -and $p.MainWindowHandle -ne 0) { break }
  }
  Start-Sleep -Seconds 3
  Shot ($zip.BaseName)

  $p.Refresh()
  if ($p.HasExited) {
    Report ("BEENDET, Code {0} (0x{1:X8})" -f $p.ExitCode, $p.ExitCode)
    continue
  }
  $live = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
  Report ("laeuft: {0} Threads, {1} MB, CPU {2:N1} s" -f $live.Threads.Count, [int]($live.WorkingSet64/1MB), $live.TotalProcessorTime.TotalSeconds)
  Report ("Fenster: Handle {0}, Titel '{1}'" -f $live.MainWindowHandle, $live.MainWindowTitle)
  $mods = @($live.Modules | ForEach-Object { $_.ModuleName })
  foreach ($w in 'flutter_windows.dll','VCRUNTIME140.dll','MSVCP140.dll') {
    Report ("  {0}: {1}" -f $w, $(if ($mods -contains $w) { 'geladen' } else { 'NICHT geladen' }))
  }
  if ($db) { Report ("DATENBANK: {0} ({1} Bytes)" -f $db.FullName, $db.Length) } else { Report 'KEINE DATENBANK' }
  try { $live.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 3 } catch {}
  $live.Refresh(); if (-not $live.HasExited) { $live.Kill() }
}
Report 'FERTIG'
Start-Sleep -Seconds 2
shutdown /s /t 0
