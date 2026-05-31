# MapAudit QA v3 - wait for dashboard, then map + tracking with log capture from flutter run stdout
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logOut | Out-Null

# Emulator physical size is often 1440x3120 (not 1080x2400).
$NavW = 1440
$NavH = 3120
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-FlutterLog {
    param([string]$name)
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 3000 | Select-String "I flutter" | Select-String `
        'MapAudit|LivePosition|LiveDelay|MarkerUpdate|FollowMode|\[Polling\]|Dispose|screen=LiveMap|screen=VehicleTracking|Entered: /map|VehicleTrackingScreen|Track tapped|vehicleId=11' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    return $path
}

Write-Host "Wait 75s for dashboard + socket..."
Start-Sleep -Seconds 75
& $adb logcat -c | Out-Null

Write-Host "=== Live Map ==="
Nav 2
Start-Sleep -Seconds 5
Save-FlutterLog "v3_map_open.txt" | Out-Null
Tap 540 1100
Start-Sleep -Seconds 2
Tap 540 1850
Start-Sleep -Seconds 2
Write-Host "Follow ON 60s..."
Start-Sleep -Seconds 60
Save-FlutterLog "v3_live_map_follow_on.txt" | Out-Null
Tap 540 1850
Write-Host "Follow OFF 30s..."
Start-Sleep -Seconds 30
Save-FlutterLog "v3_live_map_follow_off.txt" | Out-Null

Write-Host "=== Vehicle 11 Tracking ==="
Nav 1
Start-Sleep -Seconds 4
Tap 200 120
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 540 400
Start-Sleep -Seconds 3
Tap 980 180
Start-Sleep -Seconds 5
Save-FlutterLog "v3_tracking_open.txt" | Out-Null
Tap 900 120
Start-Sleep -Seconds 60
Save-FlutterLog "v3_tracking_follow_on.txt" | Out-Null
Tap 900 120
Start-Sleep -Seconds 30
Save-FlutterLog "v3_tracking_follow_off.txt" | Out-Null

Write-Host "=== Dispose ==="
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Nav 2
Start-Sleep -Seconds 1
Back
Start-Sleep -Seconds 2
Save-FlutterLog "v3_dispose.txt" | Out-Null
Write-Host "Done - check qa_logs/v3_*.txt"
