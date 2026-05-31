# Live Map QA only (post-login, flutter run active).
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"

function Tap([int]$x, [int]$y) { & $adb shell input tap $x $y | Out-Null }
function Nav([int]$i) { Tap ([int](1080 * ($i + 0.5) / 6)) 2320 }

Write-Host "Live Map QA - ensure dashboard visible"
Start-Sleep -Seconds 3
& $adb logcat -c | Out-Null

Write-Host "[1] Open Map tab (nav index 2)"
Nav 2
Start-Sleep -Seconds 8

Write-Host "[2] Tap vehicle marker area + follow"
Tap 540 900
Start-Sleep -Seconds 2
Tap 540 1850
Write-Host "Follow ON 60s"
Start-Sleep -Seconds 60
Tap 540 1850
Write-Host "Follow OFF 30s"
Start-Sleep -Seconds 30

Write-Host "[3] Back to dashboard"
& $adb shell input keyevent 4 | Out-Null
Start-Sleep -Seconds 2
Write-Host "Done - check map_audit_live.log for screen=LiveMap"
