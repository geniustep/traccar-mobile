# Short QA for LiveRouteExtension on Vehicle Tracking (device 11).
# Prerequisite: debug build with live_route_extension (flutter run active).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logDir = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$capture = Join-Path $logDir "live_route_qa_capture.txt"

$patterns = 'RoutePolyline|LiveRouteAppend|LiveRouteReset|MapAudit.*VehicleTracking|Entered: /vehicles/11/track|Route loaded for vehicleId=11'

function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int](1440 * ($i + 0.5) / 6)) 2896 }
function Back { & $adb shell input keyevent 4 | Out-Null }

Write-Host "LiveRoute QA -> $capture"
& $adb logcat -c 2>$null | Out-Null
Start-Sleep -Seconds 2

Write-Host "[1] Fleet tab"
Nav 1
Start-Sleep -Seconds 5

Write-Host "[2] Open vehicle 11 (search + first card area)"
Tap 200 180
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 720 550
Start-Sleep -Seconds 4

Write-Host "[3] Track button (lower-right action)"
Tap 1100 400
Start-Sleep -Seconds 3
Tap 720 2200
Start-Sleep -Seconds 60

Write-Host "[4] Back"
Back
Start-Sleep -Seconds 2

& $adb logcat -d -t 8000 | Select-String "I flutter" | Select-String $patterns |
    ForEach-Object { $_.Line } | Set-Content $capture -Encoding UTF8

$lines = @(Get-Content $capture -ErrorAction SilentlyContinue)
Write-Host "Captured $($lines.Count) matching lines"
$lines | Select-Object -First 25 | ForEach-Object { Write-Host $_ }
