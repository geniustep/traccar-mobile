# Phase — Alerts Unread Diagnosis (تشخيص فقط)

**الحالة:** تشخيص — **لا cleanup**، **لا حذف بيانات**، **لا Patch منفّذ**  
**التاريخ:** 2026-05-18  
**الرقم المرجعي في اللوج:** `unread=1938` من `GET /alerts/unread-count`

**نطاق المراجعة:** Flutter (`lib/features/alerts`, FCM bridge, dashboard overlay) + عقود API في `docs/` — **كود Backend/قاعدة البيانات غير موجود في مستودع `elmogps`** (الخادم: `https://api.elmogps.com`، جدول موثّق: `app_alerts`).

---

## 1. الملفات التي تمت مراجعتها

### Flutter — Alerts (مصدر الحقيقة للواجهة)

| الملف | الدور |
|--------|--------|
| `lib/features/alerts/data/datasources/alerts_remote_datasource.dart` | `GET /alerts/`, `GET /alerts/unread-count`, `PATCH …/read`, `PATCH /alerts/read-all` |
| `lib/features/alerts/data/repositories/alerts_repository_impl.dart` | طبقة Repository |
| `lib/features/alerts/presentation/providers/alerts_provider.dart` | `unreadCount`, `load`, mark read, FCM refresh |
| `lib/features/alerts/presentation/screens/alerts_screen.dart` | تبويبات all/unread/read، mark all، pull-to-refresh |
| `lib/features/alerts/presentation/screens/alert_detail_screen.dart` | `GET /alerts/:id` + auto mark-read |
| `lib/features/alerts/data/models/alert_model.dart` | `fromBackendJson` / legacy `fromTraccarEvent` |
| `lib/app/main_shell.dart` | شارة التبويب عبر `unreadAlertsCountProvider` |

### Flutter — إشارات (لا تُنشئ alerts محلياً)

| الملف | الدور |
|--------|--------|
| `lib/features/notifications/services/fcm_sync_provider.dart` | بعد Auth: `alertsProvider.load()` فقط |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | FCM → `refreshFromFcm`؛ dedup على `alertId` للـ **refresh** |
| `lib/features/dashboard/presentation/providers/fleet_live_provider.dart` | `socketAlertsProvider` — عرض لوحة فقط، **لا يغذي العداد** |
| `lib/features/dashboard/data/services/dashboard_alert_filter.dart` | dedup عرض WS vs REST على اللوحة |

### وثائق / اختبارات

| ملف | الدور |
|--------|--------|
| `docs/alerts_api_contract.md` | عقد REST |
| `docs/alerts_state_management.md` | دورة الحياة (ملاحظة: يذكر `refreshUnreadCount` عند Login بينما الكود يستدعي `load()`) |
| `docs/notifications_overview.md` | Backend = `app_alerts` |
| `docs/production_checklist.md` | QA يدوي mark-read |
| `test/features/alerts/alerts_notifier_auth_guard_test.dart` | حماية Auth |

### Backend / DB (خارج المستودع — مطلوب للتحقق من 1938)

- تنفيذ `GET /alerts/unread-count` و `PATCH` و job إنشاء alert من Traccar events  
- جدول `app_alerts` (مذكور في العقد)  
- **لا يمكن تنفيذ queries من هذا المستودع** — انظر §4.

---

## 2. مصدر unread count

| سؤال | جواب من الكود |
|------|----------------|
| أي endpoint؟ | **`GET /alerts/unread-count`** |
| من أين يأتي الرقم في التطبيق؟ | استجابة الخادم فقط → `AlertsNotifier.unreadCount` → `unreadAlertsCountProvider` |
| جدول / query؟ | **غير مرئي هنا** — الوثائق تفترض `app_alerts` حيث `is_read = false` (أو ما يعادله) |
| مستخدم حالي فقط؟ | العقد: «for the **authenticated user**» — التفاصيل (ربط user/device/group) **على Backend** |
| كل المركبات؟ | القائمة تدعم `?deviceId=`؛ العداد **لا يرسل deviceId** من Flutter → غالباً **كل تنبيهات المستخدم** |
| تنبيهات قديمة جداً؟ | **لا يوجد فلتر تاريخ** على `unread-count` في العميل → إن لم يُطبّق Backend cutoff، تُحسب **كل** غير المقروء |

```54:67:lib/features/alerts/data/datasources/alerts_remote_datasource.dart
  /// [GET /alerts/unread-count] — returns the server-side unread count.
  Future<int> getUnreadCount() async {
    final result = await _client.get<int>(
      '/alerts/unread-count',
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return (json['count'] as num?)?.toInt() ??
              (json['unreadCount'] as num?)?.toInt() ??
              0;
        }
        return (json as num?)?.toInt() ?? 0;
      },
    );
```

**متى يُستدعى:** `load()`, بعد mark read / mark all، `refreshFromFcm`, `refreshUnreadCount` (إن وُصلت إشارة)، وضمنياً عند `fcm_sync` → `load()` بعد Login، و`dashboardNotifier` → `load()` عند refresh اللوحة.

---

## 3. دورة القراءة (mark-read)

| خطوة | السلوك |
|------|--------|
| `PATCH /alerts/:id/read` | `markAlertRead` → `AlertsRemoteDataSource.markAlertRead` |
| `PATCH /alerts/read-all` | `markAllAlertsRead`؛ body اختياري `{ "before": ISO }` — **Flutter لا يمرّر `before` اليوم** (يُعلّم الكل) |
| `readAt` | من `GET /alerts/:id` وقائمة `GET /alerts/` — حقول `isRead` / `readAt` في JSON |
| بعد mark واحد | تحديث **متفائل** محلي + `_decrementUnread` ثم **`GET /alerts/unread-count`** للتأكيد |
| فشل PATCH | التعليق في الكود: **لا revert** للمتفائل (قد يظهر فرق مؤقت حتى refresh) |
| بعد restart | **لا SharedPreferences** لحالة القراءة — `load()` + unread-count من Backend |
| مصدر الحقيقة | **Backend** — Flutter لا يحسب unread من طول القائمة المحلية |

```243:274:lib/features/alerts/presentation/providers/alerts_provider.dart
  Future<void> markAsRead(String id, {bool fromAlertDetail = false}) async {
    ...
    _updateAlertLocally(id, isRead: true, readAt: DateTime.now());
    _decrementUnread();
    try {
      await _repository.markAlertRead(numId);
      final count = await _repository.getUnreadCount();
      if (mounted) {
        state = state.copyWith(unreadCount: count);
```

**الحكم المبدئي:** منطق mark-read في Flutter **سليم** إن كان Backend يطبّق PATCH فعلياً. **لم يُتحقق على بيئة 1938** في هذا المستودع — يتطلب QA يدوي (§8).

---

## 4. التكرار (duplicates)

| مصدر | هل يُنشئ صف alert؟ |
|------|---------------------|
| **FCM** | **لا** — يمرّر `alertId` ويستدعي `refreshFromFcm` → `load` + unread-count |
| **WebSocket (تطبيق)** | **لا** — `socketAlertsProvider` لعرض اللوحة؛ `addLiveEventSignal` **موثّق** لكن **غير موصول** من `socket_provider` في الكود الحالي |
| **Backend** | **المفترض** أنه الوحيد الذي يكتب `app_alerts` — dedup عند الإدراج **غير موثّق** في Flutter |

dedup في التطبيق = **منع تكرار طلبات refresh** لنفس `alertId` (جلسة واحدة)، وليس منع صفوف مكررة في DB:

```101:107:lib/features/notifications/presentation/providers/notifications_provider.dart
    if (alertId != null) {
      if (_seenAlertIds.contains(alertId)) {
        AppLogger.fcm('[FCM] Refresh skipped: duplicate alertId=$alertId');
        return;
      }
      _seenAlertIds.add(alertId);
```

**لإثبات تكرار 1938 — queries مقترحة على Backend** (تنفيذ من فريق الخادم):

```sql
-- يجب أن يساوي تقريباً استجابة unread-count
SELECT COUNT(*) AS unread FROM app_alerts WHERE is_read = FALSE;

SELECT COUNT(*) AS total FROM app_alerts;

SELECT MIN(event_time) AS oldest_unread, MAX(event_time) AS newest_unread
FROM app_alerts WHERE is_read = FALSE;

SELECT type, COUNT(*) AS n FROM app_alerts WHERE is_read = FALSE
GROUP BY type ORDER BY n DESC LIMIT 20;

SELECT device_id, COUNT(*) AS n FROM app_alerts WHERE is_read = FALSE
GROUP BY device_id ORDER BY n DESC;

-- تكرار منطقي (اضبط الأعمدة حسب schema الفعلي)
SELECT device_id, type, event_time, COUNT(*) AS c
FROM app_alerts
GROUP BY device_id, type, event_time
HAVING COUNT(*) > 1
ORDER BY c DESC
LIMIT 50;

-- معدل إنشاء يومي (آخر 30 يوماً)
SELECT DATE(event_time) AS d, COUNT(*) AS created
FROM app_alerts
WHERE event_time >= NOW() - INTERVAL 30 DAY
GROUP BY d ORDER BY d;
```

**لوج يثبت 1938 في Flutter:**

```
[Alerts] Fetch success: total=50 unread=1938 …
```

أو سطر Debug Console / `DebugLogStore.alertsUnreadCount` بعد `load()`.

---

## 5. الحجم والتراكم

| مقياس | Flutter | Backend |
|--------|---------|---------|
| unread | يعرض **كامل** العدد من API | مصدر الحقيقة |
| قائمة الشاشة | **صفحة 50** (`_pageSize = 50`) — تبويب unread يعرض أول 50 فقط | `GET /alerts/?status=unread&limit=50` |
| أقدم/أحدث unread | غير محسوب في العميل | queries §4 |
| توزيع نوع/مركبة | غير محسوب | queries §4 |
| يومياً | غير محسوب | queries §4 |

**ملاحظة UX:** شارة `1938` مع قائمة ~50 عنصراً **متسقة** مع pagination — ليست بالضرورة خطأ عدّاد.

---

## 6. تجربة التطبيق (تزامن العداد)

| حدث | السلوك المتوقع |
|-----|----------------|
| فتح Alerts | يعتمد على `load()` سابق (Login FCM / Dashboard refresh)؛ التبويب الأول **لا يستدعي** `load` تلقائياً حتى تغيير تبويب أو pull-to-refresh |
| تفاصيل alert | `GET /alerts/:id` + `PATCH …/read` + unread-count |
| Mark all | optimistic `unreadCount=0` ثم `read-all` ثم unread-count |
| Pull-to-refresh | `load(resetOffset: true)` + unread-count |
| FCM | `refreshFromFcm` → unread-count (+ list إن لم يكن filter=read) |
| WebSocket | **لا مسار فعّال حالياً** لتحديث العداد من WS في الكود |

---

## 7. السبب الجذري — تصنيف A–F

| رمز | الفرضية | احتمال | دليل من الكود / اللوج |
|-----|---------|--------|------------------------|
| **A** | تراكم طبيعي قديم (آلاف events → alerts غير مقروءة) | **عالٍ** | لا archive/cleanup في العميل؛ unread-count بلا حد زمني |
| **B** | mark-read لا يعمل | **منخفض** (Flutter) | PATCH + إعادة unread-count؛ يحتاج تأكيد على API 200 عند الحجم الكبير |
| **C** | duplicate generation في Backend | **غير مؤكد** | يتطلب query `HAVING COUNT(*) > 1` |
| **D** | unread-count query خاطئة | **منخفض** | العميل يعرض القيمة كما هي؛ خطأ محتمل فقط على الخادم (فلتر user/tenant) |
| **E** | FCM/التطبيق يعيد إنشاء alerts | **مستبعد** | لا إنشاء محلي؛ فقط refresh |
| **F** | لا cleanup/archive policy | **عالٍ** | لا وثيقة retention؛ `read-all` بدون `before` لا يحذف القديم من DB |

### هل unread=1938 صحيح أم خطأ؟

- **من منظور Flutter:** الرقم **صحيح كعرض** إذا كان `GET /alerts/unread-count` يعيد 1938.
- **من منظور منتج:** غالباً **تراكم حقيقي** وليس خلل عدّ في التطبيق — ما لم تثبت queries Backend خلاف ذلك (C أو D).

### هل يوجد تكرار alerts؟

- **في التطبيق:** لا تكرار إدراج.
- **في DB:** **غير معروف** — يحتاج queries §4.

### هل mark read يعمل؟

- **التصميم:** نعم (Backend + تأكيد unread-count).
- **التحقق عند 1938:** **QA يدوي مطلوب** (§8).

### هل نحتاج cleanup/archive policy؟

- **نعم، على الأرجح** — على Backend (retention، أرشفة، dedup عند الإنشاء، أو `read-all` بسياسة `before`). خارج نطاق Flutter الحالي.

---

## 8. اقتراح Patch لاحق (صغير وآمن — **غير منفّذ**)

| الأولوية | الجهة | اقتراح |
|----------|--------|--------|
| 1 | **Backend** | queries §4 + فهرس `(user_id, is_read, event_time)` + dedup unique `(user_id, device_id, type, event_time)` أو `source_event_id` |
| 2 | **Backend** | سياسة retention (مثلاً أرشفة > 90 يوم) أو unread-count يقتصر على آخر N يوم |
| 3 | **Flutter** (اختياري) | `AlertsScreen.initState` → `load()` إذا `alertsAsync` فارغ (سد فجوة فتح التبويب قبل FCM) |
| 4 | **Flutter** (debug) | تسجيل جسم استجابة unread-count في Debug Console فقط |
| 5 | **Docs** | مواءمة `alerts_state_management.md`: Login يستدعي `load()` وليس `refreshUnreadCount` فقط |

**لا يُقترح الآن:** حذف جماعي، تغيير FCM/WebSocket، أو UI جديد إلا عرض نص «يعرض 50 من 1938».

---

## 9. الاختبارات

### آلية (منفّذة في المستودع)

```bash
flutter test test/features/alerts
# 2 passed (auth guard)
```

### يدوية مطلوبة (بيئة حقيقية + Backend)

| # | خطوة | نجاح متوقع |
|---|------|------------|
| 1 | فتح `/alerts` — راقب `unread-count` في Network | يطابق الشارة |
| 2 | فتح تفصيل alert غير مقروء | `PATCH …/read` 200؛ `readAt` في `GET /alerts/:id` |
| 3 | Mark all read | `PATCH /alerts/read-all` 200؛ unread-count → 0 |
| 4 | Restart التطبيق | unread يبقى 0؛ عناصر `status=read` |
| 5 | قبل/بعد mark all | مقارنة Network unread-count و SQL `COUNT(*) WHERE NOT is_read` |

**حالة هذا التقرير:** لم تُنفَّذ الاختبارات اليدوية على 1938 داخل CI — التشخيص مبني على مراجعة الكود والعقد واللوج المشار إليه.

---

## 10. القيود المعروفة

1. **لا وصول لكود Backend/DB** من مستودع `elmogps` — لا يمكن إثبات 1938 بـ SQL هنا.
2. **القائمة ≠ العداد** — pagination 50 مقابل unread إجمالي.
3. **`addLiveEventSignal`** غير موصول — وثائق WS قد تكون متقدمة على الكود.
4. **mark-read المتفائل** دون revert عند فشل PATCH.
5. **Dashboard `alertsToday`** من Traccar reports/events — **رقم مختلف** عن badge Backend unread.
6. **لا cleanup** في هذه Phase — أي حذف يحتاج موافقة منفصلة.

---

## 11. خلاصة تنفيذية

| سؤال | جواب مختصر |
|------|------------|
| سبب 1938؟ | غالباً **تراكم Backend** (A + F)؛ Flutter يعكس API بصدق |
| الرقم صحيح؟ | **نعم كقيمة API**؛ مراجعة Backend للمعنى التشغيلي |
| تكرار؟ | **تحقق على DB** |
| mark read؟ | **مصمم بشكل صحيح** — تحقق يدوي |
| cleanup؟ | **مطلوب على الأرجح على الخادم** |
| Patch الآن؟ | **لا** — Backend diagnosis أولاً |

**مرتبط:** [dashboard_data_coalescing_closeout.md](dashboard_data_coalescing_closeout.md) (أشار إلى unread كـ Phase لاحقة).
