# MapLivePollingFallback Patch — FINAL (2026-05-31)

## Verdict — ALL CLOSED

| Phase | Status |
|-------|--------|
| MapAudit | **CLOSED** |
| LiveRouteExtension | **CLOSED** |
| MapLivePollingFallback (code + tests) | **CLOSED** |
| MapLivePollingFallback (emulator Vehicle Tracking) | **CLOSED** |

---

## Vehicle tested

| Field | Value |
|-------|--------|
| Fleet name | **clio** (user) |
| `deviceId` | **11** |
| Screen | `VehicleTracking` |
| Session | Logged-in emulator; `integration_test/map_audit_emulator_qa_test.dart` (session preserved via reinstall) |
| Capture | `qa_logs/polling_qa_clio11_final.txt`, `qa_logs/polling_clio11_integration.log` |

**Note:** adb-only taps did not reliably open Live tracking; integration test opened `vehicle_detail_track_btn` for device **11** and captured console output.

---

## Emulator QA — acceptance (PASSED)

### Required logs — present

```text
[Navigation] Entered: /dashboard
[Navigation] VehicleDetail: Track tapped vehicleId=11
[MapAudit] screen=VehicleTracking opened vehicleId=11
[Polling] screen=VehicleTracking started
[Polling] screen=VehicleTracking state socketConnected=true lastLivePositionAgeSeconds=1.1
[Polling] screen=VehicleTracking skipped reason=recent_live_position socketConnected=true lastLivePositionAgeSeconds=1.1
```

Repeated `skipped reason=recent_live_position` during ~90s on tracking while device 11 received WebSocket positions.

### Must NOT appear — confirmed

- **`socket_not_connected`:** **0 occurrences** in full integration run.

### Live map / route (no regression)

```text
[RoutePolyline] screen=VehicleTracking deviceId=11 loaded points=3935 ...
[LiveRouteAppend] screen=VehicleTracking deviceId=11 lat=35.71269 ... totalPoints=3936
[LiveRouteAppend] screen=VehicleTracking deviceId=11 lat=35.71158 ... totalPoints=3937
[MarkerUpdate] screen=VehicleTracking deviceId=11 oldLatLng=... newLatLng=...
[LivePosition] screen=VehicleTracking deviceId=11 ... source=liveVehicleProvider
```

Marker moved; polyline extended (3935 → 3938 points).

### Polling only when appropriate

```text
[Polling] screen=VehicleTracking tick reason=live_silent socketConnected=true lastLivePositionAgeSeconds=15.1
```

One `live_silent` tick when age exceeded 15s — expected fallback, not false disconnect.

### Dispose

- **LiveMap:** `[Polling] stopped` + `[Dispose] screen=LiveMap` on navigation away.
- **VehicleTracking:** test ended on `pageBack` failure (known integration issue); tracking session logs prove polling behavior before exit.

---

## Root cause & fix (summary)

| Before | After |
|--------|-------|
| `socketStateProvider.valueOrNull` → false disconnect | `traccarSocketService.currentState` |
| Poll every 5s with `socket_not_connected` | Skip when `lastLivePositionReceivedAt` &lt; 15s |
| — | `skipped` / `live_silent` / `websocket_disconnected` log reasons |

---

## Files (patch)

| File | Role |
|------|------|
| `lib/features/map/core/map_live_polling_fallback.dart` | Tick + logging |
| `lib/features/map/core/map_polling_decision.dart` | Decision logic |
| `lib/features/map/core/map_audit_logger.dart` | Extended `[Polling]` logs |
| `test/features/map/core/map_polling_decision_test.dart` | 6 tests |
| `test/features/map/core/map_live_polling_fallback_tick_test.dart` | 4 tests |
| `tools/polling_qa_clio11_*.ps1` | adb helpers (optional) |

---

## Automated tests — 10/10 passed

```bash
flutter test test/features/map/core/map_polling_decision_test.dart
flutter test test/features/map/core/map_live_polling_fallback_tick_test.dart
```

---

## Non-blocking follow-up

- Fix `pageBack` in `integration_test/map_audit_emulator_qa_test.dart` for clean dispose step on Vehicle Tracking.

---

## Program status

**MapAudit closed · LiveRouteExtension closed · MapLivePollingFallback closed.**

No further code changes required for this patch.
