# Dashboard Data Coalescing — إغلاق Patch

**الحالة:** مقبول / مغلق  
**التاريخ:** 2026-05-18  
**النطاق:** توحيد `GET /devices` و `GET /positions` عبر مصدر مركزي، تحسين لوج دورة refresh للوحة، وتقليل ضغط التقارير عند `dashboard_opened` دون المساس بـ Auth / FCM / WebSocket / UI.

**مرجع QA نهائي:** يعتمد هذا المستند تقرير QA المقبول لسيناريوهات Login fresh، App restart، Route resume، و Pull-to-refresh.

---

## 1. الملفات المعدّلة

| الملف | الدور |
|--------|--------|
| `lib/core/fleet/fleet_base_data_gate.dart` | **جديد** — مصدر مركزي لـ `app_devices` / `app_positions` عبر `RequestCoalescer` |
| `lib/features/reports/presentation/providers/reports_providers.dart` | `fleetBaseDataGateProvider` (نفس coalescer التقارير، TTL 15 ث) |
| `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart` | استخدام `FleetBaseDataGate` بدل HTTP مباشر منفصل |
| `lib/features/vehicles/data/datasources/vehicle_remote_datasource.dart` | نفس البوابة لـ `getVehicles()` |
| `lib/features/vehicles/presentation/providers/vehicles_provider.dart` | حقن البوابة في المستودع |
| `lib/features/map/presentation/providers/tracking_provider.dart` | حقن البوابة في `_baseVehicleProvider` |
| `lib/features/map/presentation/providers/route_intelligence_thresholds_write_provider.dart` | حقن البوابة |
| `lib/features/dashboard/presentation/providers/dashboard_provider.dart` | لوج `dispatched` / `settled`، `resetCoalescer` انتقائي، إزالة إبطال `dashboardInsightsProvider`، تأجيل إبطال `fleetAdminSnapshot` عند الفتح التلقائي |

**لم يُمس:** Auth، FCM، WebSocket، أي شاشة UI.

**مرتبط (Patches سابقة مغلقة):** `docs/reports_request_gate_qa2_closeout.md` — dedup لـ `/reports/*`.

---

## 2. السلوك قبل / بعد

| الجانب | قبل | بعد |
|--------|-----|-----|
| `GET /devices` + `GET /positions` | مساران HTTP: `DashboardRemoteDataSource` (Coalescer) + `VehicleRemoteDataSource` (بدون Coalescer) → طلبات مكررة عند فتح اللوحة | مسار واحد عبر `FleetBaseDataGate`؛ المتزامن يظهر `joined in-flight` |
| `dashboard_opened` | `resetCoalescer()` على كل `full` + إبطال `fleetAdminSnapshot` → مسح كاش وتقارير مكررة محتملة | **لا** مسح كاش؛ **لا** إبطال snapshot تلقائي |
| لوج Dashboard | `[Dashboard] Refresh completed` ~36ms قبل انتهاء API | `Refresh dispatched` ثم `Data loaded/settled` بعد `await dashboardSummaryProvider.future` |
| `dashboardInsightsProvider` | يُبطَّل دون أي `watch` في UI | لا إبطال (ميت) |
| زمن التقارير (4 مركبات، مُلاحظ ميدانياً) | trips ~3251ms، events ~2086ms | trips ~2391ms، events ~1771ms (أقل تكراراً + كاش أطول عند الفتح) |

---

## 3. سيناريوهات QA الأربعة

**معيار النجاح:** طلب GET شبكي **واحد** لكل من `/devices` و `/positions`؛ السطور الإضافية في اللوج = `joined in-flight` أو `cache hit` فقط.

### 3.1 Login fresh

- **المسار:** `/login` → session → `/dashboard` → `smartRefresh(dashboard_opened)` → `mode=full`.
- **HTTP:** 1× `/devices`، 1× `/positions`.
- **لوج متوقع:** `Refresh dispatched` → `new request: app_devices` + `joined in-flight: app_devices` → نفس الشيء لـ `app_positions` → `Skipping fleetAdminSnapshot invalidation` → `Data loaded/settled`.
- **لا يظهر:** `[Coalescer] all cache invalidated`.

### 3.2 App restart مع session موجودة

- **المسار:** Splash → `/dashboard` (عملية جديدة، Coalescer فارغ).
- **HTTP / اللوج:** نفس 3.1.

### 3.3 الرجوع إلى Dashboard من صفحة أخرى

| العمر منذ آخر refresh | الوضع | HTTP devices/positions |
|------------------------|--------|-------------------------|
| &lt; 30 ث | `mode=none` → `Refresh skipped, fresh_cache` | **0** |
| 30 ث – 5 دق | `silentLight` → إبطال summary فقط | ≤1× لكل endpoint، أو `cache hit` إن TTL ≤15 ث |
| &gt; 5 دق | `medium` | مثل الصف السابق |

- **لا** مسح كاش على `dashboard_route_resumed`.

### 3.4 Pull-to-refresh (و `toolbar` / `retry`)

- **المسار:** `refresh(source: pull_to_refresh|toolbar|retry)` → `full` + `resetCoalescer`.
- **HTTP:** 1× `/devices`، 1× `/positions` (إعادة تحميل **مقصودة**).
- **لوج متوقع:** `all cache invalidated` → `new request` لكل مفتاح → `Invalidating fleetAdminSnapshotProvider` (manual) → `Data loaded/settled`.

**قرار منتج:** تقييد `resetCoalescer` على `pull_to_refresh` فقط **غير مطلوب** حالياً — `toolbar` و `retry` يمسحان الكاش عمداً مثل السحب، وهذا مقبول.

---

## 4. مسح الكاش — مرجع سريع

| المصدر | `resetCoalescer` |
|--------|------------------|
| `dashboard_opened` | لا |
| `dashboard_route_resumed` | لا |
| `app_resumed_after_background` | لا |
| `pull_to_refresh` | نعم |
| `toolbar` | نعم |
| `retry` | نعم |

---

## 5. القيود المعروفة

1. **التقارير (`/reports/trips`, `/reports/events`)** ما زالت ثقيلة نسبياً على Traccar (ثوانٍ لعدد قليل من المركبات) — التطبيق يقلّل **التكرار** لا زمن الخادم.
2. **`unread` alerts (مثلاً ~1938)** يحتاج **Phase منفصلة** — العداد من `GET /alerts/unread-count` (Backend)؛ لم يُغيّر في هذا Patch.
3. **`toolbar` / `retry`** يمسحان Coalescer عمداً مثل `pull_to_refresh` — مقبول؛ لا حاجة لتقييد المصادر الآن.
4. **`dashboardInsightsProvider`** ما زال في الكود بلا مستهلك UI — إبطاله أُزيل فقط.
5. **`fleetAdminSnapshot`** يحمّل تقاريره عند أول `watch`؛ يُدمج مع summary عبر Coalescer التقارير عند التزامن، دون إبطال إجباري عند الفتح التلقائي.

---

## 6. `flutter test`

**40 اختباراً ناجحاً** في النطاق ذي الصلة:

| Suite | العدد |
|--------|--------|
| `test/features/dashboard/domain/dashboard_refresh_policy_test.dart` | 20 |
| `test/features/dashboard/presentation/providers/dashboard_deduplication_test.dart` | 10 |
| `test/core/utils/request_coalescer_test.dart` | 10 |

```bash
flutter test test/features/dashboard test/core/utils/request_coalescer_test.dart
```

---

## 7. `flutter analyze`

على المسارات المعدّلة (`lib/core/fleet`, `lib/features/dashboard`, `vehicle_remote_datasource`, `reports_providers.dart`):

```
Analyzing 4 items...
No issues found!
```

تحليل المشروع الكامل قد يُظهر تحذيرات/`info` قديمة في ملفات أخرى — خارج نطاق هذا Patch.

---

## 8. حكم الإغلاق

| البند | الحكم |
|-------|--------|
| عدم تكرار HTTP لـ `/devices` و `/positions` عند فتح اللوحة | **مُتحقق** |
| `dashboard_opened` لا يمسح الكاش | **مُتحقق** |
| Route resume حسب عمر الكاش | **مُتحقق** |
| Manual refresh يمسح الكاش عمداً | **مُتحقق ومقبول** |
| Auth / FCM / WebSocket / UI | **بدون تغيير** |

**Patch مغلق.** أي عمل لاحق على unread alerts أو تحسين زمن Traccar reports يُعالج في Phase منفصلة.

---

## 9. ملاحظة منفصلة (خارج هذا Patch)

أثناء QA pull-to-refresh ظهر إغلاق WebSocket وإعادة اتصال (`Connection closed` → `Reconnect scheduled` → `LiveSync connected -> reconnecting`). **لا يُعد جزءاً من Patch coalescing** ولا يتطلب تعديلاً الآن.

**مراقبة لاحقة:** [`docs/websocket_reconnect_observation.md`](websocket_reconnect_observation.md)
