# Run AFTER login + Hot Restart (R) while flutter run is active.
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"

$NavW = 1440
$NavY = 2896
function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int]($NavW * ($i + 0.5) / 6)) $NavY }
function Back { & $adb shell input keyevent 4 | Out-Null }

Write-Host "MapAudit QA (post-login) starting in 5s..."
Start-Sleep -Seconds 5

Write-Host "[1] Live Map"
Nav 2
Start-Sleep -Seconds 5
Tap 540 1100
Start-Sleep -Seconds 2
Tap 540 1850
Write-Host "    Follow ON 60s"
Start-Sleep -Seconds 60
Tap 540 1850
Write-Host "    Follow OFF 30s"
Start-Sleep -Seconds 30

Write-Host "[2] Vehicle 11 via fleet"
Nav 1
Start-Sleep -Seconds 4
Tap 540 650
Start-Sleep -Seconds 3
Tap 540 920
Start-Sleep -Seconds 4
Nav 2
Start-Sleep -Seconds 3
Tap 540 1850
Start-Sleep -Seconds 5

Write-Host "[3] Vehicle Tracking"
Nav 1
Start-Sleep -Seconds 3
Tap 540 650
Start-Sleep -Seconds 2
Tap 980 180
Start-Sleep -Seconds 5
Tap 900 200
Start-Sleep -Seconds 60
Tap 900 200
Start-Sleep -Seconds 30

Write-Host "[4] Exit"
Back
Start-Sleep -Seconds 2
Back
Start-Sleep -Seconds 2
Write-Host "Done. Check qa_logs/map_audit_live.log or flutter run console."
