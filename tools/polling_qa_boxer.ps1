# MapLivePollingFallback final QA — vehicle "boxer" on active flutter run session.
# Prerequisite: flutter run -d emulator-5554 --debug AND manual login to Dashboard.
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
    & $adb logcat -d -t 5000 | Select-String "I flutter" | Select-String `
        '\[Polling\]|\[Dispose\]|LiveRouteAppend|RoutePolyline|MarkerUpdate|LivePosition|WebSocket.*position|VehicleTracking|boxer|Track tapped' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    $n = (Get-Content $path -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Saved $path ($n lines)"
    return $path
}

function Wait-ForDashboard {
    param([int]$maxSeconds = 300)
    Write-Host "Waiting for Dashboard in logcat (login manually on emulator)..."
    for ($i = 0; $i -lt $maxSeconds; $i += 5) {
        $hit = & $adb logcat -d -t 400 | Select-String "Entered: /dashboard"
        if ($hit) {
            Write-Host "Dashboard detected after ${i}s"
            return $true
        }
        Start-Sleep -Seconds 5
    }
    Write-Host "Dashboard NOT detected within ${maxSeconds}s"
    return $false
}

if (-not (Wait-ForDashboard)) {
    Save-PollingLog "polling_qa_boxer_no_dashboard.txt" | Out-Null
    exit 1
}

& $adb logcat -c | Out-Null

Write-Host "=== Fleet -> boxer -> Live tracking (60s) ==="
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
Save-PollingLog "polling_qa_boxer_open.txt" | Out-Null

Write-Host "Watching 60s..."
Start-Sleep -Seconds 60
Save-PollingLog "polling_qa_boxer_60s.txt" | Out-Null

Write-Host "=== Dispose ==="
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-PollingLog "polling_qa_boxer_dispose.txt" | Out-Null
Write-Host "Done."
