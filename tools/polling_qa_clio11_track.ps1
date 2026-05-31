# clio 11: fleet search + detail + app-bar Track icon (top-right).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$logOut = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs"
$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

& $adb shell am start -n com.example.elmogps/com.example.elmogps.MainActivity | Out-Null
Start-Sleep -Seconds 2
& $adb logcat -c | Out-Null

Nav 1
Start-Sleep -Seconds 4
Tap 200 120
Start-Sleep -Seconds 1
& $adb shell input text "11"
Start-Sleep -Seconds 2
Tap 540 400
Start-Sleep -Seconds 4
Write-Host "Track button (app bar, right)..."
Tap 1350 200
Start-Sleep -Seconds 8

Write-Host "60s..."
Start-Sleep -Seconds 60
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2

$path = Join-Path $logOut "polling_qa_clio11_final.txt"
& $adb logcat -d | Select-String "I flutter" | Select-String "Polling|VehicleTracking|Track tapped|Dispose|LivePosition|MarkerUpdate|RoutePolyline|LiveRoute|socket_not|MapAudit.*VehicleTracking" | ForEach-Object { $_.Line } | Set-Content $path -Encoding UTF8
Write-Host "Saved $path ($((Get-Content $path -EA SilentlyContinue).Count) lines)"
