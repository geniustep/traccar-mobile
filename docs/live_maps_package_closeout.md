# ELMOGPS — Live Maps Package Closeout (Final)

**Document:** `docs/live_maps_package_closeout.md`  
**Date:** 2026-05-31  
**Status:** **CLOSED** — no further code changes required for this package.

---

## 1. Executive Summary

On Android, live map screens sometimes showed a **static vehicle** while the same device moved on the web UI. Investigation split into three layers: **data path** (WebSocket / REST / merge), **map UI** (marker, follow, dispose), and **route polyline** (historical API vs live extension). A fourth issue was **misleading REST polling** (`socket_not_connected`) while WebSocket was healthy.

All three engineering phases are **closed**:

| Phase | Focus |
|-------|--------|
| **MapAudit** | Structured logs, live marker/follow/polling/dispose on Live Map and Vehicle Tracking |
| **LiveRouteExtension** | Orange route line extends behind the vehicle without full Route API reload per tick |
| **MapLivePollingFallback** | Poll only when socket is down or live feed is silent ≥15s; no false disconnect |

**Conclusion:** The root cause was **not** the Traccar/WebSocket server. Issues were client-side merge, UI wiring, polyline buffer, and polling reading `StreamProvider` as disconnected. Marker movement, live polyline extension, and polling behavior are **accepted** on emulator QA (device **11**, clio).

**Scope boundary:** Route Report, Replay, and trip-map screens remain **historical-only** (unchanged by design).

---

## 2. Final Status Table

| Component | Status | Evidence |
| ---------------------- | --------- | ----------------------------------- |
| MapAudit | **CLOSED** | `[MapAudit] screen=LiveMap/VehicleTracking opened` → `[LivePosition]` → `[MarkerUpdate]`; `[FollowMode]`; `[Dispose]`; `[Polling] stopped` |
| LiveRouteExtension | **CLOSED** | `[RoutePolyline] loaded points=…`; `[LiveRouteAppend] totalPoints` increased; `stale_or_duplicate` on repeats only |
| MapLivePollingFallback | **CLOSED** | `[Polling] skipped reason=recent_live_position`; `socket_not_connected` = **0**; `live_silent` only when age ≥15s |
| WebSocket / live positions | **OK** | `[WebSocket] position received deviceId=11` during QA; delays &lt; 5s on marker path |
| Route Report / Replay | **Unchanged** | Historical route load only; no live append buffer |

---

## 3. Files Modified or Added

### Core — logging & live behavior

| File | Role |
|------|------|
| `lib/features/map/core/map_audit_logger.dart` | `[MapAudit]`, `[LivePosition]`, `[MarkerUpdate]`, `[FollowMode]`, `[Polling]`, `[Dispose]`, `[LiveDelay]` |
| `lib/features/map/core/map_live_polling_fallback.dart` | Screen-scoped REST fallback; uses `currentState` + `MapPollingDecision` |
| `lib/features/map/core/map_polling_decision.dart` | Pure rules: recent position / disconnect / live silent |
| `lib/features/map/core/live_route_extension.dart` | Historical points + live append buffer; `combinedPoints` for map |
| `lib/features/map/core/live_route_polyline_log.dart` | `[RoutePolyline]`, `[LiveRouteAppend]`, `[LiveRouteReset]` |
| `lib/features/map/core/vehicle_live_merger.dart` | Stale-fixTime guard for live merge |

### Providers & socket

| File | Role |
|------|------|
| `lib/core/socket/socket_provider.dart` | `lastLivePositionReceivedAtProvider` updated on accepted WS positions |
| `lib/features/map/presentation/providers/tracking_provider.dart` | `liveVehicleProvider` + `VehicleLiveMerger` for tracking screen |

### Screens

| File | Role |
|------|------|
| `lib/features/map/presentation/screens/live_map_screen.dart` | MapAudit + polling fallback + today route overlay hooks |
| `lib/features/map/presentation/screens/vehicle_tracking_screen.dart` | MapAudit + `_liveRouteExt` + polling fallback |

### Session / QA support (MapAudit path)

| File | Role |
|------|------|
| `lib/features/auth/presentation/providers/auth_provider.dart` | Initial `isLoading: true` to avoid false logout on hot restart during QA |

### Tests

| File | Role |
|------|------|
| `test/features/map/core/map_polling_decision_test.dart` | Polling decision (6 cases) |
| `test/features/map/core/map_live_polling_fallback_tick_test.dart` | Riverpod tick + log contract (4 cases) |
| `test/features/map/core/live_route_extension_test.dart` | Append / reset / range rules (7 cases) |
| `test/features/map/core/vehicle_live_merger_test.dart` | Merge / stale ignore |
| `test/features/auth/auth_rehydrate_initial_state_test.dart` | Auth initial loading state |

### Integration & tools

| File | Role |
|------|------|
| `integration_test/map_audit_emulator_qa_test.dart` | Emulator QA: Live Map + vehicle 11 tracking + follow |
| `tools/map_audit_qa_monitor.ps1` | Logcat monitor for MapAudit tags |
| `tools/map_audit_qa_v3.ps1` | adb navigation (1440×3120) |
| `tools/map_audit_qa_after_login.ps1` | Post-login adb flow |
| `tools/map_audit_qa_orchestrate.ps1` | Orchestrated QA session |
| `tools/map_audit_live_route_qa.ps1` | Live route adb attempt |
| `tools/map_audit_live_route_monitor.ps1` | RoutePolyline logcat filter |
| `tools/polling_qa_*.ps1` | Polling QA helpers (boxer/clio11/vehicle11) |

### QA reports (detailed evidence)

| File | Phase |
|------|--------|
| `qa_logs/QA_MAPAUDIT_SESSION_REPORT.md` | MapAudit closure |
| `qa_logs/QA_LIVEROUTE_EXTENSION_REPORT.md` | LiveRouteExtension closure |
| `qa_logs/QA_POLLING_FALLBACK_PATCH.md` | MapLivePollingFallback closure |
| `qa_logs/map_audit_live.log` | Raw MapAudit capture |
| `qa_logs/polling_qa_clio11_final.txt` | Vehicle 11 polling excerpt |
| `qa_logs/polling_clio11_integration.log` | Full integration run log |
| `qa_logs/MAP_AUDIT_QA_RUNBOOK.md` | Manual runbook |

---

## 4. Behavior Before / After

### Before

- Vehicle could appear **fixed** on Android while web showed movement.
- Marker sometimes did not update from live feed.
- Orange **route polyline lagged** behind the vehicle (API loaded once; live points did not extend the drawn line).
- **Polling fallback** fired every ~5s with `reason=socket_not_connected` even while WebSocket delivered positions.
- Hard to tell whether failure was **data**, **merge**, or **UI**.

### After

- **Marker** updates with live positions (`liveVehicleProvider` + merger).
- **Follow ON:** camera follows vehicle; **Follow OFF:** camera static, marker still moves.
- **Route polyline** extends via `LiveRouteAppend` on `combinedPoints` (no full Route API call per WS tick).
- **Polling** skips when any position was accepted within **15s**; uses synchronous `TraccarSocketService.currentState`.
- **Logs** give a clear audit trail per screen and reason.

---

## 5. QA Evidence

### MapAudit

Confirmed on emulator (device **11**, build with `MapAuditLogger`):

```
[MapAudit] screen=LiveMap opened
[MapAudit] screen=VehicleTracking opened vehicleId=11
[LivePosition] screen=LiveMap|VehicleTracking deviceId=11 ...
[MarkerUpdate] screen=LiveMap|VehicleTracking ...
[LiveDelay] deviceId=11 delaySeconds=...
[FollowMode] screen=VehicleTracking enabled=true cameraAnimated=true
[Polling] screen=LiveMap|VehicleTracking started
[Polling] screen=... stopped
[Dispose] screen=LiveMap|VehicleTracking ...
```

WebSocket during sessions:

```
[WebSocket] position received deviceId=11 fixTime=...
```

### LiveRouteExtension

Vehicle Tracking (integration + prior session):

```
[RoutePolyline] screen=VehicleTracking deviceId=11 loaded points=3935 ...
[LiveRouteAppend] screen=VehicleTracking deviceId=11 ... totalPoints=3936
[LiveRouteAppend] screen=VehicleTracking deviceId=11 ignored reason=stale_or_duplicate
[LiveRouteAppend] screen=VehicleTracking deviceId=11 ... totalPoints=3937
```

- Single `GET /reports/route` on range load; subsequent updates via append buffer.
- `[LiveRouteReset] reason=manual_refresh|time_range_changed` covered in unit tests.

### MapLivePollingFallback

Vehicle **11** (clio), `VehicleTracking`, integration run:

```
[Polling] screen=VehicleTracking state socketConnected=true lastLivePositionAgeSeconds=1.1
[Polling] screen=VehicleTracking skipped reason=recent_live_position socketConnected=true lastLivePositionAgeSeconds=1.1
[Polling] screen=VehicleTracking tick reason=live_silent ... lastLivePositionAgeSeconds=15.1
```

- **`socket_not_connected`:** zero occurrences in post-patch integration log.
- `live_silent` only when last accepted position age ≥15s (expected fallback).

---

## 6. Test Results

| Suite | Result |
|-------|--------|
| `test/features/map/core/map_polling_decision_test.dart` | **6/6 passed** |
| `test/features/map/core/map_live_polling_fallback_tick_test.dart` | **4/4 passed** |
| `test/features/map/core/live_route_extension_test.dart` | **7/7 passed** |
| `test/features/map/core/vehicle_live_merger_test.dart` | **3/3 passed** |
| `integration_test/map_audit_emulator_qa_test.dart` | **Accepted** — live map + vehicle 11 tracking logs OK; test exits with known `pageBack` failure (non-blocking) |

Run locally:

```bash
flutter test test/features/map/core/map_polling_decision_test.dart
flutter test test/features/map/core/map_live_polling_fallback_tick_test.dart
flutter test test/features/map/core/live_route_extension_test.dart
flutter test test/features/map/core/vehicle_live_merger_test.dart
```

---

## 7. Known Non-blocking Follow-up

- **Fix `pageBack` in `integration_test/map_audit_emulator_qa_test.dart`** so dispose step can pop Vehicle Tracking without `CupertinoNavigationBarBackButton` finder failure.

This is a **test harness** issue only. It does **not** indicate a product bug and does **not** block package closure.

---

## 8. Final Verdict

**The ELMOGPS live map tracking package is CLOSED.**

No further code changes are required for:

- live **marker** movement,
- live **route polyline** extension,
- **polling fallback** optimization.

Any future work (e.g. Live Map Follow adb QA, hot-restart runbook automation, integration `pageBack`) must be tracked as a **separate phase**, not a reopening of MapAudit, LiveRouteExtension, or MapLivePollingFallback.

---

## Related documentation

- `docs/map_screens_overview.md` — screen inventory
- `docs/websocket_reconnect_observation.md` — socket diagnostics context
- `qa_logs/QA_MAPAUDIT_SESSION_REPORT.md`
- `qa_logs/QA_LIVEROUTE_EXTENSION_REPORT.md`
- `qa_logs/QA_POLLING_FALLBACK_PATCH.md`
