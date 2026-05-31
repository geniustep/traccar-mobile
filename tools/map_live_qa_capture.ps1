# Map live QA - adb navigation + logcat capture
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logOut | Out-Null

function Tap([int]$x, [int]$y) {
    & $adb shell input tap $x $y | Out-Null
}

function NavIndex([int]$i) {
    $x = [int](1080 * ($i + 0.5) / 6)
    Tap $x 2320
}

function Save-Logcat([string]$name) {
    $path = Join-Path $logOut $name
    $lines = & $adb logcat -d -s flutter:I 2>$null | Select-String -Pattern `
        '\[Map\]|\[WebSocket\]|\[LiveSync\]|MapAudit|LivePosition|LiveDelay|MarkerUpdate|FollowMode|Polling|Dispose'
    if ($lines) {
        $lines | ForEach-Object { $_.Line } | Set-Content -Path $path -Encoding UTF8
    } else {
        "no matching flutter logs" | Set-Content -Path $path -Encoding UTF8
    }
    return $path
}

Write-Host "Map Live QA capture starting"
& $adb logcat -c 2>$null | Out-Null

Write-Host "Step 1: Live Map follow ON 60 sec"
NavIndex 2
Start-Sleep -Seconds 3
Tap 540 1100
Start-Sleep -Seconds 2
Tap 540 1850
Start-Sleep -Seconds 2
Start-Sleep -Seconds 60
$p1 = Save-Logcat "live_map_follow_on.txt"
Write-Host "Saved $p1"

Write-Host "Step 2: Live Map follow OFF 30 sec"
Tap 540 1850
Start-Sleep -Seconds 30
$p2 = Save-Logcat "live_map_follow_off.txt"
Write-Host "Saved $p2"

Write-Host "Step 3: Open Vehicle Tracking"
NavIndex 1
Start-Sleep -Seconds 3
Tap 540 700
Start-Sleep -Seconds 2
Tap 980 180
Start-Sleep -Seconds 4
Save-Logcat "vehicle_tracking_open.txt" | Out-Null

Write-Host "Step 4: Vehicle Tracking follow ON 45 sec"
Tap 980 200
Start-Sleep -Seconds 45
$p4 = Save-Logcat "vehicle_tracking_follow_on.txt"
Write-Host "Saved $p4"

Write-Host "Step 5: Vehicle Tracking follow OFF 30 sec"
Tap 980 200
Start-Sleep -Seconds 30
$p5 = Save-Logcat "vehicle_tracking_follow_off.txt"
Write-Host "Saved $p5"

Write-Host "Step 6: Back navigation dispose check"
& $adb shell input keyevent 4 | Out-Null
Start-Sleep -Seconds 2
& $adb shell input keyevent 4 | Out-Null
Start-Sleep -Seconds 2
$p6 = Save-Logcat "after_dispose.txt"
Write-Host "Saved $p6"
Write-Host "Done"
