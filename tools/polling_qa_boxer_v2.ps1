# boxer QA v2: open search icon, filter boxer, open detail + track.
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-Log([string]$name) {
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 10000 | Select-String "I flutter" | Select-String `
        'Polling|Dispose|LiveRoute|RoutePolyline|MarkerUpdate|LivePosition|VehicleTracking|Track tapped|Entered: /vehicles|vehicleId=|boxer|MapAudit' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    Write-Host "Saved $path"
}

& $adb logcat -c | Out-Null
Write-Host "Fleet tab..."
Nav 1
Start-Sleep -Seconds 3
Write-Host "Search icon (top-right)..."
Tap 1320 180
Start-Sleep -Seconds 1
& $adb shell input text "boxer"
Start-Sleep -Seconds 2
Write-Host "First vehicle card..."
Tap 720 520
Start-Sleep -Seconds 3
Write-Host "Live tracking button..."
Tap 1200 200
Start-Sleep -Seconds 5
Save-Log "polling_qa_boxer_v2_open.txt"

Write-Host "60s watch..."
Start-Sleep -Seconds 60
Save-Log "polling_qa_boxer_v2_60s.txt"

Write-Host "Dispose..."
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-Log "polling_qa_boxer_v2_dispose.txt"
