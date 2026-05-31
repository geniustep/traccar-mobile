# Polling fallback manual QA — use with `flutter run -d emulator-5554 --debug` (logged in).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logOut | Out-Null

$NavW = 1440
$NavH = 3120
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-PollingLog {
    param([string]$name)
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 4000 | Select-String "I flutter" | Select-String `
        '\[Polling\]|\[Dispose\]|LiveRouteAppend|RoutePolyline|MarkerUpdate|LivePosition|WebSocket.*position' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    Write-Host "Saved $path ($((Get-Content $path -ErrorAction SilentlyContinue).Count) lines)"
    return $path
}

Write-Host "Waiting 90s for flutter run + login/dashboard..."
Start-Sleep -Seconds 90
& $adb logcat -c | Out-Null

Write-Host "=== Vehicle 11 Live Tracking (60s) ==="
Nav 1
Start-Sleep -Seconds 4
Tap 200 120
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 540 400
Start-Sleep -Seconds 3
Tap 980 180
Start-Sleep -Seconds 3
Save-PollingLog "polling_qa_tracking_open.txt" | Out-Null

Write-Host "Watching 60s for live positions + polling..."
Start-Sleep -Seconds 60
Save-PollingLog "polling_qa_tracking_60s.txt" | Out-Null

Write-Host "=== Optional: airplane mode 25s (silent / disconnect) ==="
& $adb shell cmd connectivity airplane-mode enable 2>$null
Start-Sleep -Seconds 25
Save-PollingLog "polling_qa_airplane_25s.txt" | Out-Null
& $adb shell cmd connectivity airplane-mode disable 2>$null
Start-Sleep -Seconds 5

Write-Host "=== Dispose ==="
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-PollingLog "polling_qa_dispose.txt" | Out-Null
Write-Host "Done."
