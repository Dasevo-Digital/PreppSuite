# Runs on the host. Waits only for the sandbox *server* to be gone -- an
# orphaned vmmem process clears itself a minute later and does not block a
# new instance, so aborting on it was wrong.
$ErrorActionPreference = 'SilentlyContinue'
Get-Process | Where-Object { $_.Name -like 'WindowsSandboxServer' -or $_.Name -like 'WindowsSandboxRemoteSession' } | Stop-Process -Force
for ($i = 0; $i -lt 20; $i++) {
  if (-not (Get-Process | Where-Object { $_.Name -like 'WindowsSandbox*' })) { break }
  Start-Sleep -Seconds 3
}
Remove-Item C:\sbtest\start-result.txt, C:\sbtest\marker.txt, C:\sbtest\powershell.log -Force
schtasks /run /tn sbstart | Out-Null
Write-Output 'gestartet'

for ($i = 0; $i -lt 170; $i++) {
  Start-Sleep -Seconds 5
  if (Test-Path C:\sbtest\start-result.txt) {
    $c = Get-Content C:\sbtest\start-result.txt -Raw
    if ($c -match 'FERTIG') {
      Write-Output ("--- Ergebnis nach {0} s ---" -f (($i + 1) * 5))
      Write-Output $c
      exit 0
    }
  }
}
Write-Output '--- TIMEOUT ---'
Write-Output ('marker: ' + ((Get-Content C:\sbtest\marker.txt) -join ' | '))
Write-Output '--- powershell.log ---'
Get-Content C:\sbtest\powershell.log
Write-Output '--- teilergebnis ---'
Get-Content C:\sbtest\start-result.txt
