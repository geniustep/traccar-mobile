# MapAudit QA orchestration — run while `flutter run -d emulator-5554 --debug` is active.
# 1) Wait for manual login -> /dashboard in qa_logs/map_audit_live.log
# 2) Hot restart via Dart Tooling Daemon (from flutter run terminal output)
# 3) Verify session after restart
# 4) Run map QA taps (v3)
param(
    [string]$FlutterTerminal = "",
    [int]$LoginWaitSec = 900,
    [int]$PostDashboardSec = 5
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$liveLog = Join-Path $root "qa_logs\map_audit_live.log"
$adb = "C:\Users\Zakah\AppData\Local\Android\sdk\platform-tools\adb.exe"
$report = Join-Path $root "qa_logs\QA_MAPAUDIT_SESSION_REPORT.md"

function Get-LatestFlutterTerminal {
    $termRoot = Join-Path $env:USERPROFILE ".cursor\projects\d-flutter-app-traccar-mobile\terminals"
    if (-not (Test-Path $termRoot)) { return $null }
    Get-ChildItem $termRoot -Filter "*.txt" |
        Where-Object { (Get-Content $_.FullName -TotalCount 6 -ErrorAction SilentlyContinue) -match 'flutter run' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-DtdWsUri([string]$terminalPath) {
    if (-not (Test-Path $terminalPath)) { return $null }
    $text = Get-Content $terminalPath -Raw -ErrorAction SilentlyContinue
    if ($text -match 'uri=(ws://127\.0\.0\.1:\d+/[^"\s]+)') { return $matches[1] }
    if ($text -match '(ws://127\.0\.0\.1:\d+/[^"\s]+/ws)') { return $matches[1] }
    return $null
}

function Wait-LogPattern([string]$pattern, [int]$timeoutSec) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $liveLog) {
            $hit = Select-String -Path $liveLog -Pattern $pattern -SimpleMatch:$false -ErrorAction SilentlyContinue | Select-Object -Last 1
            if ($hit) { return $hit.Line }
        }
        Start-Sleep -Seconds 3
    }
    return $null
}

function Invoke-HotRestartViaVm([string]$terminalPath) {
    $vmHttp = $null
    if (Test-Path $terminalPath) {
        $text = Get-Content $terminalPath -Raw -ErrorAction SilentlyContinue
        if ($text -match 'Dart VM Service on .+ available at: (http://127\.0\.0\.1:\d+/[^/\s]+/)') {
            $vmHttp = $matches[1].TrimEnd('/') + '/'
        }
    }
    if (-not $vmHttp) {
        Write-Host "WARN: VM Service URL not found in flutter terminal — press R manually in flutter run."
        return $false
    }
    try {
        $list = Invoke-RestMethod -Uri "$vmHttp`json/list" -Method Get -TimeoutSec 10
        $isolate = ($list | Where-Object { $_.type -eq 'Isolate' } | Select-Object -First 1).id
        if (-not $isolate) { return $false }
        $body = @{
            jsonrpc = '2.0'
            id      = '1'
            method  = 'ext.flutter.restart'
            params  = @{
                isolateId = $isolate
                reason    = 'manual'
                force     = $true
            }
        } | ConvertTo-Json -Depth 5
        $null = Invoke-RestMethod -Uri $vmHttp -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 60
        Write-Host "Hot restart sent via VM Service."
        return $true
    } catch {
        Write-Host "WARN: VM hot restart failed: $_ — press R manually."
        return $false
    }
}

Write-Host "=== MapAudit QA orchestrate ==="
Write-Host "Log in on emulator now. Watching $liveLog for /dashboard ..."

$dashLine = Wait-LogPattern 'Entered: /dashboard' $LoginWaitSec
if (-not $dashLine) {
    $failBody = @(
        '# MapAudit QA Session - FAILED (no dashboard)',
        '',
        "Timeout waiting for Entered: /dashboard in map_audit_live.log (${LoginWaitSec}s).",
        'Action: log in on emulator, re-run orchestrate.'
    ) -join [Environment]::NewLine
    Set-Content -Path $report -Value $failBody -Encoding UTF8
    exit 1
}

Write-Host "Dashboard detected: $dashLine"
Start-Sleep -Seconds $PostDashboardSec

if (-not $FlutterTerminal) {
    $latest = Get-LatestFlutterTerminal
    if ($latest) { $FlutterTerminal = $latest.FullName }
}
Write-Host "Flutter terminal: $FlutterTerminal"

$hrOk = Invoke-HotRestartViaVm $FlutterTerminal
Start-Sleep -Seconds 12

$loginAfter = $null
$dashAfter = $null
if (Test-Path $liveLog) {
    $lines = Get-Content $liveLog -Tail 30
    $loginAfter = $lines | Where-Object { $_ -match 'Entered: /login' } | Select-Object -Last 1
    $dashAfter = $lines | Where-Object { $_ -match 'Entered: /dashboard' } | Select-Object -Last 1
}

Write-Host "=== Map QA automation (v3) ==="
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "map_audit_qa_v3.ps1")

Start-Sleep -Seconds 3
$snippet = @()
if (Test-Path $liveLog) {
    $snippet = Get-Content $liveLog | Where-Object {
        $_ -match 'MapAudit|LivePosition|LiveDelay|MarkerUpdate|FollowMode|\[Polling\]|Dispose|screen=LiveMap|screen=VehicleTracking'
    }
}

$mapAuditCount = ($snippet | Where-Object { $_ -match 'MapAudit' }).Count
$livePosCount = ($snippet | Where-Object { $_ -match 'LivePosition' }).Count
$markerCount = ($snippet | Where-Object { $_ -match 'MarkerUpdate' }).Count
$followCount = ($snippet | Where-Object { $_ -match 'FollowMode' }).Count
$disposeCount = ($snippet | Where-Object { $_ -match 'Dispose' }).Count
$pollingCount = ($snippet | Where-Object { $_ -match '\[Polling\]' }).Count

$phaseClosed = ($mapAuditCount -ge 2) -and ($livePosCount -ge 1) -and ($markerCount -ge 1)

$sessionNote = if ($loginAfter -and -not $dashAfter) {
    'FAIL: returned to /login after hot restart (auth rehydration).'
} elseif ($dashAfter) {
    'PASS: /dashboard seen after hot restart.'
} elseif ($hrOk) {
    'Hot restart sent; no new navigation lines captured.'
} else {
    'Hot restart not confirmed (manual R may be required).'
}

$phaseStatus = if ($phaseClosed) {
    'READY FOR REVIEW - map screen logs captured.'
} else {
    'NOT CLOSED - missing MapAudit / LivePosition / MarkerUpdate on map screens.'
}

$authStatus = if ($loginAfter -and -not $dashAfter) { 'FAIL' } else { 'PASS or not tested' }
$liveMapStatus = if ($snippet -match 'screen=LiveMap opened') { 'PASS' } else { 'FAIL' }
$trackStatus = if ($snippet -match 'screen=VehicleTracking opened') { 'PASS' } else { 'FAIL' }
$posMarkerStatus = if ($livePosCount -ge 1 -and $markerCount -ge 1) { 'PASS' } else { 'FAIL' }
$followStatus = if ($snippet -match 'cameraAnimated=true') { 'PASS' } else { 'FAIL' }
$disposeStatus = if ($disposeCount -ge 1) { 'partial' } else { 'FAIL' }

$reportBody = @(
    "# MapAudit QA Session Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    '',
    '## Session',
    "- Dashboard first seen: $dashLine",
    "- Hot restart via VM: $hrOk",
    "- Post-restart session: $sessionNote",
    '',
    '## Log counts (map_audit_live.log)',
    '| Tag | Count |',
    '|-----|-------|',
    "| MapAudit | $mapAuditCount |",
    "| LivePosition | $livePosCount |",
    "| MarkerUpdate | $markerCount |",
    "| FollowMode | $followCount |",
    "| Polling | $pollingCount |",
    "| Dispose | $disposeCount |",
    '',
    "## Phase status",
    $phaseStatus,
    '',
    '## Captured lines',
    '```',
    ($snippet -join [Environment]::NewLine),
    '```',
    '',
    '## v3 snapshots',
    'See qa_logs/v3_*.txt',
    '',
    '## Acceptance checklist',
    '| Criterion | Status |',
    '|-----------|--------|',
    "| Stay logged in after Hot Restart | $authStatus |",
    "| Live Map MapAudit | $liveMapStatus |",
    "| VehicleTracking MapAudit | $trackStatus |",
    "| LivePosition + MarkerUpdate | $posMarkerStatus |",
    "| FollowMode cameraAnimated | $followStatus |",
    "| Dispose + Polling stopped | $disposeStatus |"
) -join [Environment]::NewLine

Set-Content -Path $report -Value $reportBody -Encoding UTF8

Write-Host "Report -> $report"
if (-not $phaseClosed) { exit 2 }
exit 0
