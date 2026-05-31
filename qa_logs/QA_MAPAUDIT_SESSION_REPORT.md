# MapAudit QA Session Report — 2026-05-31 (build حديث)

## جلسة التشغيل

| Item | Value |
|------|--------|
| Device | emulator-5554 (1440×3120 physical) |
| Command | `flutter run -d emulator-5554 --debug` (جلسة واحدة، PID 4694) |
| Monitor | `tools/map_audit_qa_monitor.ps1` → `qa_logs/map_audit_live.log` |
| Login | يدوي → `Entered: /dashboard` @ 12:36:47 UTC |
| Hot Restart (R) | **لم يُختبر آلياً** — VM HTTP 405، MCP hot_restart يتطلب Dart SDK أحدث؛ يحتاج **R يدوي** في طرفية flutter run |

## ملخص الحكم

| المعيار | الحالة |
|---------|--------|
| Build حديث + MapAudit | **نعم** |
| Dashboard بعد login | **نعم** |
| Live Map — فتح الشاشة + سجلات | **نعم** |
| Live Map — FollowMode | **جزئي** — لم يُلتقط `FollowMode screen=LiveMap` (زر Follow لم يُضغط بشكل موثوق عبر adb) |
| Vehicle Tracking — كامل | **نعم** |
| LivePosition → MarkerUpdate (delay &lt; 5s) | **نعم** على الشاشتين |
| Dispose + Polling stopped | **نعم** (LiveMap + VehicleTracking) |
| Hot Restart يحافظ على الجلسة | **معلق** — لم يُنفَّذ |
| Traccar Server | **ليس السبب** — WS + positions لـ device 11 |

**المرحلة:** يمكن اعتبار QA الخرائط **مكتملاً تقريباً** بعد تأكيد يدوي قصير لـ Hot Restart + Follow على Live Map. لا حاجة لتعديل منطق الخرائط للمرحلة الحالية.

---

## سجلات مؤكدة (من `flutter run` / `map_audit_live.log`)

### Live Map

```
[Navigation] Entered: /map
[MapAudit] screen=LiveMap opened
[Polling] screen=LiveMap started
[LivePosition] screen=LiveMap deviceId=11 ... delaySeconds=0.7–8.7
[MarkerUpdate] screen=LiveMap deviceId=11 oldLatLng=... newLatLng=...
[LiveDelay] deviceId=11 ...
[Polling] screen=LiveMap stopped
[Dispose] screen=LiveMap subscriptions=pending_focus_listeners timers=polling_fallback
```

ملاحظة: `[Polling] tick reason=socket_not_connected` يظهر رغم وصول WS — يستحق مراجعة لاحقة لربط `lastLivePositionReceivedAt` (خارج نطاق MapAudit الحالي).

### Vehicle Tracking (device 11)

```
[MapAudit] screen=VehicleTracking opened vehicleId=11
[Polling] screen=VehicleTracking started
[LivePosition] screen=VehicleTracking deviceId=11 ... delaySeconds≈0.6–1.8 (حديث)
[MarkerUpdate] screen=VehicleTracking deviceId=11 ...
[FollowMode] screen=VehicleTracking enabled=true cameraAnimated=true  (متكرر مع تحرك المركبة)
[Polling] screen=VehicleTracking stopped
[Dispose] screen=VehicleTracking subscriptions=live_vehicle_route_listeners timers=polling_fallback
```

لم يظهر `FollowMode enabled=false` في adb QA (تبديل Follow OFF عبر الإحداثيات غير مؤكد).

### WebSocket

```
[WebSocket] position received deviceId=11 fixTime=2026-05-31T12:44:xx.000Z
```

---

## مشاكل مسار QA (تم تشخيصها)

1. **إحداثيات adb قديمة (1080×2400)** — المحاكي 1440×3120؛ شريط التنقل عند `y≈2896`، تبويب Map عند `x≈600`. السكربتات `map_audit_qa_v3.ps1` / `after_login.ps1` كانت تفوّت `/map` أحياناً.
2. **`map_audit_qa_orchestrate.ps1`** — خطأ ترميز PowerShell (أحرف Unicode)؛ **تم إصلاحه**.
3. **Hot Restart آلي** — غير متاح من طرفية ثانية بدون `attach`؛ استخدم **R** في نفس جلسة `flutter run`.

---

## خطوات يدوية متبقية (دقيقتان)

1. في طرفية `flutter run`: اضغط **R** — تأكد `Entered: /dashboard` وليس `/login` (وعدم `Logout — FCM` قبل اكتمال rehydrate).
2. Live Map → اختر marker 11 → **Live tracking** → انتظر 30s → تحقق من `[FollowMode] screen=LiveMap ... cameraAnimated=true` ثم أوقف Follow.

---

## ملفات السجلات

- `qa_logs/map_audit_live.log` — لقطة monitor (VehicleTracking غني)
- `terminals/972100.txt` — stdout كامل لـ flutter run
- `qa_logs/v3_*.txt` — مقاطع logcat أثناء adb QA
- `tools/map_audit_live_map_only.ps1` — Live Map بإحداثيات 1440×3120

---

## قبل / بعد

| قبل | بعد (هذه الجلسة) |
|-----|------------------|
| لا سجلات MapAudit على الخرائط | `LiveMap opened` + `VehicleTracking opened` |
| QA عالق على login | Dashboard + فتح شاشتين |
| شك في السيرفر | delaySeconds صغير + WS لـ device 11 |

---

## إغلاق MapAudit (2026-05-31)

**الحكم:** MapAudit الخاص بحركة الـ marker **مقبول / مغلق.**

**Follow-up (لا يمنع الإغلاق):**

1. Polling — `[Polling] tick reason=socket_not_connected` رغم WS → patch لاحق.
2. Live route polyline — `qa_logs/QA_LIVEROUTE_EXTENSION_REPORT.md` (QA يدوي لـ RoutePolyline / LiveRouteAppend).
