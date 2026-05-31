$out = Join-Path (Split-Path $PSScriptRoot -Parent) "qa_logs\polling_manual_qa.log"
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
"" | Set-Content $out -Encoding UTF8
$patterns = 'Polling|Dispose|LiveRouteAppend|RoutePolyline|MarkerUpdate|LivePosition|WebSocket.*position'
Write-Host "Polling QA monitor -> $out"
& $adb logcat -c 2>$null | Out-Null
& $adb logcat -v time flutter:I *:S 2>&1 | ForEach-Object {
    $line = $_
    foreach ($p in @($patterns -split '\|')) {
        if ($line -match $p) {
            $entry = "$(Get-Date -Format 'HH:mm:ss') $line"
            Add-Content -Path $out -Value $entry -Encoding UTF8
            Write-Host $entry
            break
        }
    }
}
