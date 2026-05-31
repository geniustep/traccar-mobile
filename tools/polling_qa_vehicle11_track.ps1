# clio / vehicle 11 — Live Tracking polling QA (logged-in session).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-Log([string]$name) {
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 15000 | Select-String "I flutter" | Select-String `
        'Polling|Dispose|VehicleTracking|Track tapped|LivePosition|MarkerUpdate|RoutePolyline|LiveRoute|socket_not|MapAudit|Entered: /vehicles|vehicleId=11|clio' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    $n = (Get-Content $path -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Saved $path ($n lines)"
}

& $adb logcat -c | Out-Null
Write-Host "Fleet -> clio (11) -> Live tracking"
Nav 1
Start-Sleep -Seconds 3
Tap 1320 180
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 720 520
Start-Sleep -Seconds 3
Tap 1200 200
Start-Sleep -Seconds 6
Save-Log "polling_qa_clio11_open.txt"

Write-Host "60s watch..."
Start-Sleep -Seconds 60
Save-Log "polling_qa_clio11_60s.txt"

Write-Host "Dispose..."
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-Log "polling_qa_clio11_dispose.txt"
Write-Host "Done."
