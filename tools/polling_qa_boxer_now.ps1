# Assumes: emulator logged in, app on or near Dashboard. No integration_test.
param([switch]$SkipDashboardWait)

$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logOut | Out-Null

$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-PollingLog {
    param([string]$name)
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 8000 | Select-String "I flutter" | Select-String `
        '\[Polling\]|\[Dispose\]|LiveRouteAppend|RoutePolyline|MarkerUpdate|LivePosition|WebSocket.*position|VehicleTracking|MapAudit.*VehicleTracking|Entered: /dashboard|Entered: /vehicles|Track tapped|boxer' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    $n = (Get-Content $path -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Saved $path ($n lines)"
}

if (-not $SkipDashboardWait) {
    $dash = & $adb logcat -d -t 600 | Select-String "Entered: /dashboard"
    if (-not $dash) {
        Write-Host "WARN: /dashboard not in recent logcat; continuing anyway."
    } else {
        Write-Host "Dashboard seen in logcat."
    }
}

& $adb logcat -c | Out-Null
Write-Host "=== Fleet -> boxer -> Live tracking ==="
Nav 1
Start-Sleep -Seconds 4
Tap 200 120
Start-Sleep -Seconds 1
& $adb shell input text "boxer"
Start-Sleep -Seconds 2
Tap 540 400
Start-Sleep -Seconds 3
Tap 980 180
Start-Sleep -Seconds 4
Save-PollingLog "polling_qa_boxer_open.txt"

Write-Host "Watching 60s..."
Start-Sleep -Seconds 60
Save-PollingLog "polling_qa_boxer_60s.txt"

Write-Host "=== Dispose ==="
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-PollingLog "polling_qa_boxer_dispose.txt"
Write-Host "Done."
