# MapAudit QA v2 - after fresh flutter run (debug build with MapAuditLogger)
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logOut | Out-Null

function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int](1080 * ($i + 0.5) / 6)) 2320 }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-MapAuditLog([string]$name) {
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 2000 | Select-String "I flutter" | Select-String `
        'MapAudit|LivePosition|LiveDelay|MarkerUpdate|FollowMode|\[Polling\]|Dispose|WebSocket\] position|screen=LiveMap|screen=VehicleTracking' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    return $path
}

Write-Host "Waiting 30s for app login/dashboard..."
Start-Sleep -Seconds 30
& $adb logcat -c 2>$null | Out-Null

# --- Live Map: vehicle 11 via detail -> view on map ---
Write-Host "Phase A: Open vehicle 11 on Live Map"
Nav 1
Start-Sleep -Seconds 4
# Try several list rows to hit vehicleId=11
foreach ($y in @(520, 680, 840, 1000)) {
    Tap 540 $y
    Start-Sleep -Seconds 2
    $hit = & $adb logcat -d -t 80 | Select-String "vehicleId=11"
    if ($hit) { Write-Host "  Found vehicle 11 at list y=$y"; break }
    Back
    Start-Sleep -Seconds 1
}
# View on map button area on location card (~y=900)
Tap 540 920
Start-Sleep -Seconds 4
# Follow toggle on bottom sheet
Tap 540 1850
Start-Sleep -Seconds 2
Write-Host "Phase A: Live Map follow ON 60s"
Start-Sleep -Seconds 60
$pA1 = Save-MapAuditLog "v2_live_map_follow_on.txt"
Write-Host "  $pA1"

Write-Host "Phase A2: Follow OFF 30s"
Tap 540 1850
Start-Sleep -Seconds 30
$pA2 = Save-MapAuditLog "v2_live_map_follow_off.txt"
Write-Host "  $pA2"

# --- Vehicle Tracking ---
Write-Host "Phase B: Vehicle Tracking vehicle 11"
Tap 980 180
Start-Sleep -Seconds 5
$pB0 = Save-MapAuditLog "v2_tracking_open.txt"
Tap 980 200
Write-Host "Phase B1: Tracking follow ON 60s"
Start-Sleep -Seconds 60
$pB1 = Save-MapAuditLog "v2_tracking_follow_on.txt"
Write-Host "  $pB1"

Write-Host "Phase B2: Tracking follow OFF 30s"
Tap 980 200
Start-Sleep -Seconds 30
$pB2 = Save-MapAuditLog "v2_tracking_follow_off.txt"
Write-Host "  $pB2"

Write-Host "Phase C: Exit and dispose"
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Nav 2
Start-Sleep -Seconds 1
Back
Start-Sleep -Seconds 2
$pC = Save-MapAuditLog "v2_dispose.txt"
Write-Host "  $pC"

# Full audit dump
$full = Join-Path $logOut "v2_full_audit.txt"
& $adb logcat -d -t 3000 | Select-String "I flutter" | Select-String `
    'MapAudit|LivePosition|LiveDelay|MarkerUpdate|FollowMode|\[Polling\]|Dispose|WebSocket\] position' `
    | ForEach-Object { $_.Line } | Set-Content $full -Encoding UTF8
Write-Host "Full audit: $full"
Write-Host "Done"
