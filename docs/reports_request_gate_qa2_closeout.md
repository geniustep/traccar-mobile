# Reports Request Gate QA-2 — إغلاق Patch

**الحالة:** مقبول / مغلق  
**التاريخ:** 2026-05-16  
**النطاق:** توحيد مفاتيح dedup لطلبات Traccar `/reports/*` وإيقاف عاصفة التقارير عند فتح Dashboard.

---

## 1. الملفات المعدّلة

| الملف | الدور |
|--------|--------|
| `lib/core/utils/report_request_key.dart` | بناء `normalizedKey` وتوحيد `from`/`to` (دقيقة UTC) |
| `lib/core/utils/request_coalescer.dart` | dedup + logs `skipped duplicate` / `joined in-flight` / `cache hit` |
| `lib/features/reports/data/fleet_reports_request_gate.dart` | بوابة مشتركة multi-device (Dashboard + Fleet) |
| `lib/features/reports/data/reports_request_gate.dart` | بوابة single-device (شاشة التقارير) |
| `lib/features/reports/data/datasources/reports_remote_datasource.dart` | HTTP بـ `from`/`to` مطابقين للمفتاح |
| `lib/features/reports/presentation/providers/reports_providers.dart` | `sharedReportsCoalescerProvider` |
| `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart` | تقارير اليوم عبر البوابة المشتركة |
| `lib/features/fleet_intelligence/data/datasources/fleet_intelligence_remote_datasource.dart` | نفس البوابة + `trigger` |
| `lib/features/dashboard/presentation/providers/dashboard_provider.dart` | حقن `fleetReportsRequestGateProvider` |
| `lib/features/fleet_intelligence/presentation/providers/fleet_intelligence_providers.dart` | `refreshNow` موحّد + triggers |
| `lib/features/notifications/services/fcm_sync_provider.dart` | إزالة تحميل 7 أيام events عند login |
| `lib/features/fleet_intelligence/presentation/screens/admin_dashboard_screen.dart` | شارة غير المقروء من Backend alerts |
| `test/core/utils/report_request_key_test.dart` | اختبارات المفتاح |
| `test/core/utils/request_coalescer_test.dart` | dedup sub-second |

**مرتبط (QA سابق، بدون تغيير في QA-2):** إصلاح WebSocket raw `ping` في `traccar_socket_service.dart`.

---

## 2. شكل `normalizedKey` النهائي

```
reports_{reportType}|{sortedDeviceIds}|{fromMinuteUtc}|{toMinuteUtc}
```

**مثال:**

```
reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z
```

- `trigger` **خارج** المفتاح — لا يكسر dedup.
- `from` و `to` في **المفتاح و query HTTP** كلاهما مقربان لحد **الدقيقة UTC**.
- `deviceIds` مرتبة تصاعدياً.

---

## 3. قبل / بعد — طلبات Reports عند فتح Dashboard (فترة today)

| السيناريو | قبل QA-2 (تقريبي) | بعد QA-2 (مُتحقق) |
|-----------|-------------------|-------------------|
| `/reports/events` اليوم | 2–4 (summary + fleet + insights + انجراف ms) | **1** لكل `normalizedKey` |
| `/reports/trips` اليوم | 2–3 | **1** |
| `/reports/events` آخر 7 أيام | 1 عند login (`notifications.load`) | **0** حتى فتح `/notifications` |
| طلب أسبوع fleet | عند period=week فقط | بدون تغيير السلوك |

**عند فتح Dashboard (اليوم):** خرج فقط طلبان HTTP للتقارير — `events` + `trips` لليوم.

---

## 4. مقتطف logs — `joined in-flight`

```
[Reports] scheduled type=events deviceIds=[1, 9, 11] from=2026-05-16T00:00:00.000Z to=2026-05-16T12:35:00.000Z trigger=dashboard_summary normalizedKey=reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z
[Reports] new request normalizedKey=reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z
[Reports] scheduled type=events deviceIds=[1, 9, 11] ... trigger=fleet_snapshot_today normalizedKey=reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z
[Reports] skipped duplicate joined in-flight normalizedKey=reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z
```

نفس المفتاح لـ `dashboard_summary` و `fleet_snapshot_today` → طلب HTTP واحد.

---

## 5. `dart analyze`

على الملفات المعدّلة: **بدون أخطاء** (تحذيرات غير مرتبطة في ملفات replay قديمة).

---

## 6. نتائج `flutter test`

**27 اختباراً ناجحاً** في النطاق ذي الصلة:

| Suite | العدد |
|--------|--------|
| `test/core/utils/report_request_key_test.dart` | 3 |
| `test/core/utils/request_coalescer_test.dart` | 10 |
| `test/core/socket/live_position_update_gate_test.dart` | 4 |
| `test/features/dashboard/presentation/providers/dashboard_deduplication_test.dart` | 10 |

---

## 7. Geocoder 429 المتبقي

بعد QA-2 ظهر **429 مرة واحدة** رغم تقليل الطلبات — **لم يعد بسبب report storm من التطبيق**.

السبب المحتمل: **إعداد Traccar Geocoder** أو **حد المزود** (Nominatim/Google، إلخ) على السيرفر.

**مسار لاحق (منفصل):** geocoder provider / caching / rate limits على مستوى `tracker-server` — خارج نطاق هذا الـ patch.

---

## معايير القبول (محققة)

- [x] `normalizedKey` صحيح (type + sorted ids + from/to بالدقيقة)
- [x] `trigger` لا يكسر dedup
- [x] HTTP `from`/`to` مطابقان للمفتاح
- [x] Dashboard + Fleet يستعملان بوابة مشتركة
- [x] فتح Dashboard: طلب واحد events + واحد trips لليوم
- [x] لا طلب events لـ 7 أيام عند فتح Dashboard
- [x] لا عودة لـ `Unrecognized token 'ping'`
