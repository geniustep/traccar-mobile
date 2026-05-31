# Watches flutter logcat for MapAudit QA milestones. Run while flutter run is active.
# Usage: powershell -File tools\map_audit_qa_monitor.ps1
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$out = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs\map_audit_live.log"
New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
"" | Set-Content $out -Encoding UTF8

$patterns = @(
  'Entered: /dashboard',
  'Entered: /login',
  'MapAudit',
  'LivePosition',
  'LiveDelay',
  'MarkerUpdate',
  'FollowMode',
  '\[Polling\]',
  'Dispose',
  'screen=LiveMap',
  'screen=VehicleTracking'
)

Write-Host "MapAudit log monitor -> $out"
Write-Host "Log in on emulator, press R in flutter run, then run map QA."
Write-Host "Ctrl+C to stop."

& $adb logcat -c 2>$null | Out-Null
& $adb logcat -v time flutter:I *:S 2>&1 | ForEach-Object {
    $line = $_
    foreach ($p in $patterns) {
        if ($line -match $p) {
            $ts = Get-Date -Format "HH:mm:ss"
            $entry = "$ts $line"
            Add-Content -Path $out -Value $entry -Encoding UTF8
            Write-Host $entry
            break
        }
    }
}
