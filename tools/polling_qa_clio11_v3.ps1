# clio vehicle 11 — coords from map_audit_qa_v3.ps1 (proven MapAudit path).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

function Save-Log([string]$name) {
    $path = Join-Path $logOut $name
    & $adb logcat -d -t 20000 | Select-String "I flutter" | Select-String `
        'Polling|Dispose|VehicleTracking|Track tapped|LivePosition|MarkerUpdate|RoutePolyline|LiveRoute|socket_not|MapAudit' `
        | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
    Write-Host "Saved $path ($((Get-Content $path -EA SilentlyContinue).Count) lines)"
}

& $adb logcat -c | Out-Null
Nav 1
Start-Sleep -Seconds 4
Tap 200 120
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 540 400
Start-Sleep -Seconds 3
Tap 980 180
Start-Sleep -Seconds 6
Save-Log "polling_qa_clio11_v3_open.txt"
Start-Sleep -Seconds 60
Save-Log "polling_qa_clio11_v3_60s.txt"
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Save-Log "polling_qa_clio11_v3_dispose.txt"
