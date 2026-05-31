# QA Emulator Session — 2026-05-31 (deviceId=11)

**Note:** Logcat captured while app PID 10683 was running a build **before** `[MapAudit]` tags (pre–hot-restart). Legacy tags `[Map]`, `[LiveSync]`, `[WebSocket]` only.

## Live Map (`/map` 11:42:06 UTC)

```
[Navigation] Entered: /map
[Map] Markers updated: count=4
```

No `[LivePosition]` / `[MarkerUpdate]` / `[FollowMode]` / `[Polling]` in this window (60s adb automation).

## WebSocket (session start)

```
[WebSocket] Connected
[WebSocket] State: Instance of 'SocketConnected'
[LiveSync] LiveSyncStatus changed: idle -> connected, reason: socket_connected
```

## Vehicle Tracking (vehicleId=11)

```
[Navigation] VehicleDetail: Track tapped vehicleId=11
[Map] VehicleTrackingScreen opened: vehicleId=11
[LiveSync] Ignored stale position for live merge: vehicleId=11 fixTime=2026-05-31T11:43:53.000Z lastFixTime=2026-05-31T11:43:54.000Z
[Map] Live status changed to live for vehicleId=11
[Map] First live position for vehicleId=11: 35.18014,-6.09799 speed=70.00002548
```

## Full log files

- `qa_logs/session_capture.log`
- `qa_logs/session_dump.txt`
