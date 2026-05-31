# LiveRoute Extension QA Report — 2026-05-31 (FINAL)

## Context

- **MapAudit:** closed — `qa_logs/QA_MAPAUDIT_SESSION_REPORT.md`.
- **LiveRouteExtension:** `lib/features/map/core/live_route_extension.dart` + wiring in Vehicle Tracking / Live Map today overlay.
- **Route Report / Replay:** unchanged (historical-only).

---

## Emulator QA session (closed)

| Item | Result |
|------|--------|
| Method | `flutter test integration_test/map_audit_emulator_qa_test.dart -d emulator-5554` (same nav as manual: Dashboard → Fleet → vehicle 11 → **Live tracking**, ~90s on screen) |
| Build | Fresh debug APK installed on `emulator-5554` |
| Vehicle Tracking | **Confirmed** — `[MapAudit] screen=VehicleTracking opened vehicleId=11` |
| Period | Default today window (`from=2026-05-31T00:00:00.000Z`, `to` ≈ now at open) |

### Console evidence (device 11, moving)

```
[RoutePolyline] screen=VehicleTracking deviceId=11 loaded points=3592 from=2026-05-31T00:00:00.000 to=2026-05-31T12:59:12.743389
[LiveRouteAppend] screen=VehicleTracking deviceId=11 ignored reason=no_historical_loaded   ← race before route API returns (expected once)
[LiveRouteAppend] screen=VehicleTracking deviceId=11 ignored reason=stale_or_duplicate
[LiveRouteAppend] screen=VehicleTracking deviceId=11 lat=35.47410 lon=-6.02625 fixTime=2026-05-31T12:59:15.000Z totalPoints=3593
[LiveRouteAppend] screen=VehicleTracking deviceId=11 lat=35.47897 lon=-6.02542 fixTime=2026-05-31T13:00:11.000Z totalPoints=3594
```

Also observed: `[LivePosition]`, `[MarkerUpdate]`, Follow ON/OFF, **no second** `GET /reports/route` per WebSocket tick (single route load at open).

**Note:** Integration test failed at final `pageBack` (no Cupertino back button) — unrelated to LiveRoute.

**LiveRouteReset on emulator:** not triggered in this run (no Refresh / date picker tap). Covered by unit test + code paths below.

---

## Final answers (acceptance checklist)

| # | Question | Answer |
|---|----------|--------|
| 1 | `[RoutePolyline]` appeared? | **Yes** — 3592 historical points loaded |
| 2 | `[LiveRouteAppend]` appeared? | **Yes** — append to 3593, 3594; `stale_or_duplicate` on repeats |
| 3 | Orange line extends visually? | **Inferred OK** — marker moved in logs; `totalPoints` grew; polyline uses `routePtsForMap` = `combinedPoints`. No screenshot in automation; no visual regression signal |
| 4 | `[LiveRouteReset]` on Refresh / time change? | **Unit test yes** (`reason=manual_refresh`); **emulator not exercised**; **code wired** (`time_range_changed` on From/To, `manual_refresh` on refresh) |
| 5 | Files modified this QA close? | **None in lib/** — only `tools/map_audit_live_route_monitor.ps1` added for logcat |
| 6 | Test results | `live_route_extension_test.dart` **7/7 passed**; integration MapAudit test **LiveRoute logs OK**, exit code 1 only on dispose `pageBack` |
| 7 | Verdict | **LiveRouteExtension CLOSED** — no patch required for append/polyline path |

---

## Acceptance criteria

| Criterion | Status |
|-----------|--------|
| `[RoutePolyline]` on route load | ✅ |
| `[LiveRouteAppend]` on new live position | ✅ |
| No full Route API reload per live tick | ✅ (one route GET at open; WS-only updates after) |
| Follow ON/OFF does not block append | ✅ (append after Follow disabled) |
| `stale_or_duplicate` only on duplicate | ✅ |
| Route Report / Replay historical-only | ✅ (unchanged) |
| `[LiveRouteReset]` | ✅ unit + wiring; emulator refresh/date tap optional follow-up |

---

## Wiring verified (no bug found)

- `liveVehicleProvider` → `ref.listen` → `_liveRouteExt.tryAppendFromVehicle` in `vehicle_tracking_screen.dart`
- `routePtsForMap` = `_liveRouteExt.combinedPoints` → map polylines
- `loadHistorical` when `routeDetailProvider` settles

---

## Follow-up (not blocking LiveRoute closure)

1. **Polling:** `[Polling] tick reason=socket_not_connected` while WebSocket still delivers positions — align fallback with socket health (MapAudit follow-up).
2. **Integration test:** fix `pageBack` on Vehicle Tracking dispose step.
3. **Optional:** one manual tap Refresh to capture `[LiveRouteReset] reason=manual_refresh` in logcat for audit trail only.

---

## Reference

| File | Role |
|------|------|
| `lib/features/map/core/live_route_extension.dart` | Append buffer + rules |
| `lib/features/map/core/live_route_polyline_log.dart` | `[RoutePolyline]` / `[LiveRouteAppend]` / `[LiveRouteReset]` |
| `lib/features/map/presentation/screens/vehicle_tracking_screen.dart` | Primary QA screen |
| `lib/features/map/presentation/screens/live_map_screen.dart` | Today overlay per vehicle |
| `test/features/map/core/live_route_extension_test.dart` | 7 unit tests |
| `integration_test/map_audit_emulator_qa_test.dart` | Emulator nav + 90s tracking |
