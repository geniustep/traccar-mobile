# ELMO GPS — منصة إدارة الأسطول الذكية

تطبيق Flutter احترافي لتتبع الأسطول في الوقت الفعلي، مبني على خادم [Traccar](https://www.traccar.org/) مفتوح المصدر.

---

## الميزات الرئيسية

| الميزة | الوصف |
|--------|--------|
| **خريطة مباشرة** | تتبع جميع المركبات على الخريطة بتحديثات فورية عبر WebSocket |
| **لوحة التحكم** | ملخص يومي للأسطول: المركبات النشطة، المسافة، الرحلات، التنبيهات |
| **إدارة المركبات** | بيانات كاملة لكل مركبة مع الحالة، السرعة، والموقع |
| **أوامر الأجهزة** | إرسال أوامر تحكم واستعلام للأجهزة مع شروط أمان وسجل كامل |
| **التنبيهات** | سجل كامل للأحداث مع إشعارات فورية عبر WebSocket |
| **تقارير متكاملة** | Résumé، Route، Trajets، Arrêts، Événements، خريطة المسار، **إعادة تشغيل المسار (Replay)**، **رسم السرعة**، PDF ومشاركة |
| **التحليلات** | إحصائيات أسبوعية للأسطول: المسافة، الكفاءة، تجاوزات السرعة |
| **الإشعارات** | تغذية مباشرة بالأحداث (تجاوز سرعة، مغادرة منطقة، إنذارات) |
| **متعدد البيئات** | Dev / Staging / Production عبر `--dart-define` |

---

## البنية التقنية

```
lib/
├── app/                    # التطبيق الجذري، التوجيه (go_router)
├── core/
│   ├── api/                # ApiConfig، ApiEnvironment، TraccarEndpoints
│   ├── error/              # AppException ونوع كامل من الأخطاء
│   ├── maps/               # MapHelper (polyline coloring، decimation)
│   ├── network/            # TraccarClient (Dio + Result<T>)
│   ├── response/           # Result<S,F> — نمط الإرجاع الموحد
│   ├── socket/             # TraccarSocketService، SocketEventParser
│   ├── storage/            # SecureStorageService
│   ├── theme/              # AppColors، AppTextStyles، AppSpacing
│   └── utils/              # DateFormatter، FormatUtils، route_decimator (decimation للخرائط والـ Replay)
├── features/               # Clean Architecture بالميزة
│   ├── auth/               # تسجيل الدخول، جلسة Traccar
│   ├── commands/           # نظام أوامر الأجهزة
│   ├── dashboard/          # ملخص + رؤى
│   ├── vehicles/           # قائمة + تفاصيل المركبات
│   ├── map/                # خريطة مباشرة + تتبع المركبة
│   ├── alerts/             # سجل التنبيهات
│   ├── reports/            # ★ قسم التقارير الكامل (جديد)
│   ├── trips/              # رحلات المركبات
│   ├── analytics/          # التحليلات الأسبوعية
│   └── notifications/      # تغذية الإشعارات
└── shared/
    └── providers/          # core_providers، traccar_providers
```

---

## قسم التقارير (Reports)

### نظرة عامة

قسم متكامل يتيح للمدير استخراج تقارير يومية وأسبوعية وشهرية لكل مركبة من Traccar API، مع إمكانية التصدير إلى PDF والمشاركة عبر WhatsApp أو البريد الإلكتروني.

### بنية الـ Feature

```
lib/features/reports/
├── data/
│   ├── models/
│   │   ├── summary_report_model.dart    ← Traccar /reports/summary JSON
│   │   ├── stop_report_model.dart       ← Traccar /reports/stops JSON
│   │   └── event_report_model.dart      ← Traccar /reports/events JSON
│   ├── datasources/
│   │   └── reports_remote_datasource.dart  ← 5 endpoints + device enrichment
│   ├── repositories/
│   │   └── reports_repository_impl.dart
│   └── services/
│       ├── report_pdf_service.dart      ← بناء PDF احترافي (pdf ^3.x)
│       └── report_share_service.dart    ← مشاركة PDF أو نص (share_plus)
├── domain/
│   ├── entities/
│   │   ├── summary_report.dart          ← distance, speed, engineHours, fuel
│   │   ├── stop_report.dart             ← location, start/end, duration
│   │   └── event_report.dart            ← type, labelFr, severity, color
│   └── repositories/
│       └── reports_repository.dart
└── presentation/
    ├── providers/
    │   ├── reports_providers.dart       ← ReportFilterState + FutureProviders + pdfGenerationProvider
    │   └── replay_controller.dart        ← تشغيل Replay: Timer، سرعات x1…x8، seek
    ├── screens/
    │   ├── reports_screen.dart          ← شاشة رئيسية بـ 5 Tabs + أزرار Route (خريطة / replay / رسم السرعة)
    │   ├── route_report_map_screen.dart ← خريطة المسار مع Polyline ملوّنة
    │   ├── replay_report_screen.dart    ← Replay: خريطة، تحكم، Follow، ميني-Chart
    │   ├── charts_report_screen.dart    ← رسم السرعة كامل الصفحة (fl_chart)
    │   └── pdf_preview_screen.dart      ← معاينة PDF داخل التطبيق
    └── widgets/
        └── speed_chart.dart             ← خط السرعة عبر الزمن + إحصائيات + تظليل وقت (Replay)
```

### التقارير المدعومة

| التقرير | Endpoint | المحتوى |
|---------|---------|---------|
| **Résumé** | `GET /reports/summary` | Distance, Temps moteur, Vitesse max/moy, Carburant |
| **Route** | `GET /reports/route` | نقاط GPS + خريطة تفاعلية + Polyline ملوّنة؛ من نفس البيانات: **Replay** و**رسم السرعة** (أزرار داخل تبويب Route) |
| **Trajets** | `GET /reports/trips` | قائمة رحلات مع العناوين (Reverse Geocoding) |
| **Arrêts** | `GET /reports/stops` | التوقفات مع المدة والإحداثيات |
| **Événements** | `GET /reports/events` | Timeline أحداث بأسماء فرنسية وألوان حسب الخطورة |

### الفلتر الموحّد

```dart
// الفترات الجاهزة
ReportPeriod.today        // Aujourd'hui
ReportPeriod.yesterday    // Hier
ReportPeriod.thisWeek     // Cette semaine
ReportPeriod.thisMonth    // Ce mois
ReportPeriod.custom       // Personnalisé (date picker)

// التواريخ تُحوَّل تلقائياً إلى UTC عند إرسالها لـ Traccar
// وتُعرض للمستخدم بالتوقيت المحلي
```

### أحداث Traccar المدعومة

| النوع | التسمية الفرنسية | الخطورة |
|-------|-----------------|---------|
| `deviceOverspeed` | Excès de vitesse | 🔴 critical |
| `alarm` | Alarme | 🔴 critical |
| `geofenceEnter/Exit` | Entrée/Sortie zone | 🟠 warning |
| `ignitionOn` | Démarrage moteur | 🟢 success |
| `deviceOnline` | Appareil en ligne | 🔵 info |
| `deviceMoving` | En mouvement | 🔵 info |
| `ignitionOff` | Arrêt moteur | ⚫ neutral |
| `deviceOffline` | Appareil hors ligne | ⚫ neutral |
| `queuedCommandSent` | Commande envoyée | 🔵 info |
| `sos` | Appel SOS | 🔴 critical |
| أي نوع آخر | Inconnu | ⚫ neutral |

### Route Map

- **Polyline ملوّنة** حسب السرعة: < 5 (رمادي) / 5-40 (أخضر) / 40-80 (برتقالي) / 80+ (أحمر)
- **Markers** للبداية (أخضر) والنهاية (أحمر) وأعلى سرعة
- **Auto-fit** تلقائي على كامل المسار
- **Decimation** تلقائي: max 800 نقطة (يحافظ على أول وآخر نقطة)
- **InfoWindow** بالضغط على أي نقطة: الوقت، السرعة، الإحداثيات

### Replay (إعادة تشغيل المسار) — Phase 3

- **المصدر**: نفس طلب `GET /reports/route` (ترتيب زمني، نقاط غير صالحة مُرشّحة، أخذ عيّنة حتى ~1200 نقطة للتشغيل)
- **التحكم**: تشغيل / إيقاف / إعادة، منزلق للانتقال، سرعات **x1، x2، x4، x8**
- **الخريطة**: marker مركبة مخصّص (اتجاه + لون حسب نطاق السرعة)، بداية/نهاية، polyline مُقَلّل عبر `RoutePointDecimator` لتفادي آلاف الـ polylines على Android
- **تتبع الكاميرا**: تبديل *Follow vehicle* مع `moveCamera` لتقليل التقطّع
- **ميني رسم سرعة**: اختياري؛ خط عمودي يوافق `fixTime` الحالي أثناء التشغيل
- **دورة الحياة**: إيقاف التايمر عند المغادرة أو `pause`؛ `StateNotifier` مع `autoDispose`

### رسم السرعة (Speed Chart) — Phase 3

- **المكتبة**: `fl_chart`
- **المحاور**: الوقت (دقائق من أول نقطة) مقابل السرعة (كم/س كما في المشروع بعد تحويل عقد Traccar)
- **الإحصائيات**: أقصى سرعة، متوسط، عدد نقاط GPS (محسوبة من البيانات الكاملة؛ أخذ عيّنة للرسم حتى ~400 نقطة)
- **الحالات الخاصة**: أقل من نقطتين أو بيانات غير كافية → حالة فارغة؛ محور آمن عند السرعة صفرية أو مدة زمنية ضئيلة (مقاومة Infinity/NaN في تدرج الشبكة)

### Export PDF

يُولَّد PDF احترافي يحتوي على:

```
Header:  ELMOGPS — Rapport de Flotte
         Véhicule: [Nom]  |  Période: [Du] → [Au]
         Généré le: [date/heure locale]

Sections:
  ■ Résumé     — KPIs: Distance, Temps moteur, Vitesses, Carburant
  ■ Trajets    — جدول: N°, Début, Fin, Durée, Distance, Vit. max
  ■ Arrêts     — جدول: N°, Début, Fin, Durée, Lieu
  ■ Événements — قائمة: Heure, Type, Détails

Footer:  Page X / Y  |  elmogps.com
```

### Share

يظهر Bottom Sheet عند الضغط على زر المشاركة 📤:

- **📄 Partager en PDF** — يولّد PDF ويفتح System Share Sheet
- **💬 Partager résumé texte** — نص مختصر مناسب لـ WhatsApp/SMS
- **🖨️ Imprimer** — معاينة + طباعة مباشرة

### المسارات

| المسار | الشاشة |
|--------|--------|
| `/reports` | شاشة التقارير الرئيسية (5 Tabs) |
| `/reports/route-map` | خريطة المسار التفصيلية |
| `/reports/replay` | Replay (يتطلب `extra`: `params`، `vehicleName`) |
| `/reports/charts` | رسم السرعة كامل الصفحة (نفس الـ `extra`) |
| `/reports/pdf-preview` | معاينة PDF داخل التطبيق |

---

## نظام أوامر الأجهزة (Device Commands)

### نظرة عامة

نظام متكامل لإرسال أوامر التحكم والاستعلام إلى أجهزة GPS عبر Traccar API، مع شروط أمان صارمة وسجل كامل لكل عملية.

### بنية الـ Feature

```
lib/features/commands/
├── domain/
│   ├── entities/
│   │   ├── device_command.dart        ← تعريف الأمر: النوع، الخطورة، الأيقونة
│   │   └── command_log_entry.dart     ← سجل الأمر: الحالة، الوقت، النتيجة
│   ├── catalog/
│   │   └── command_catalog.dart       ← كتالوج مركزي + خريطة دعم أجهزة Teltonika
│   ├── repositories/
│   │   └── commands_repository.dart   ← واجهة مجردة للبيانات
│   └── services/
│       └── device_command_service.dart ← منطق الأعمال + التحقق الأمني
├── data/
│   ├── datasources/
│   │   └── commands_remote_datasource.dart  ← REST: /commands/send + /commands/types
│   └── repositories/
│       └── commands_repository_impl.dart    ← API + SharedPreferences للسجلات
└── presentation/
    ├── providers/
    │   └── commands_provider.dart     ← Riverpod providers + dispatchCommand()
    ├── screens/
    │   ├── device_commands_screen.dart ← تبويبان: Control / Info
    │   └── command_logs_screen.dart    ← سجل الأوامر مع إمكانية المسح
    └── widgets/
        ├── command_card.dart           ← بطاقة الأمر مع مؤشر الدعم والخطر
        ├── command_confirmation_dialog.dart ← حوار تأكيد للأوامر الخطيرة
        └── command_result_banner.dart  ← SnackBar نتيجة التنفيذ
```

### مستويات الخطورة

| المستوى | اللون | السلوك |
|---------|-------|--------|
| `safe` | أزرق | تنفيذ فوري بدون تأكيد |
| `warning` | برتقالي | يظهر حوار تأكيد قبل التنفيذ |
| `critical` | أحمر | حوار تأكيد + تحقق من السرعة + رسالة تحذير للسلامة |

### قواعد الأمان المُدمجة

- **قطع المحرك (`engineStop`)**: محظور إذا كانت السرعة > 5 كم/ساعة
- **جميع الأوامر الخطيرة**: تتطلب تأكيداً صريحاً من المستخدم
- **تسجيل تلقائي**: كل أمر يُسجَّل بحالته (`pending → success / failed`)

### أوامر التحكم

| الأمر | Traccar Type | الخطورة |
|-------|-------------|---------|
| قطع المحرك | `engineStop` | 🔴 CRITIQUE |
| تشغيل المحرك | `engineResume` | 🟡 ATTENTION |
| تفعيل الإنذار | `alarmArm` | ✅ SAFE |
| تعطيل الإنذار | `alarmDisarm` | ✅ SAFE |
| إعادة تشغيل GPS | `rebootDevice` | 🔴 CRITIQUE |
| تشغيل المخرج 1 | `outputControl` | 🟡 ATTENTION |
| أمر مخصص | `custom` | 🟡 ATTENTION |

### المسارات

| المسار | الشاشة |
|--------|--------|
| `/vehicles/:id/commands` | شاشة أوامر الجهاز (تبويبان) |
| `/vehicles/:id/commands/logs` | سجل الأوامر التاريخي |

---

## API vs WebSocket — متى يُستخدم كل منهما؟

| النوع | متى | أمثلة |
|-------|-----|--------|
| **REST API** | بيانات تاريخية، تحميل أولي، عمليات CRUD | تسجيل الدخول، التقارير، التحليلات |
| **WebSocket** | بيانات الوقت الفعلي، التحديثات المستمرة | مواضع المركبات، التنبيهات الفورية |

```
المستخدم يفتح الخريطة
    ↓
REST: GET /devices + /positions  →  تحميل كامل مع البيانات الوصفية
    ↓
WebSocket: positions updates      →  تحديث فوري للإحداثيات
    ↓
mapVehiclesProvider               →  يدمج الاثنين تلقائياً في Riverpod
```

---

## متطلبات التشغيل

- **Flutter** ≥ 3.22 (Dart ≥ 3.3)
- **خادم Traccar** (v5.x / v6.x)
- **مفتاح Google Maps API** مع Maps SDK for Android / iOS مفعّل

---

## الإعداد السريع

### 1. استنسخ المشروع

```bash
git clone https://github.com/your-org/elmogps.git
cd elmogps
flutter pub get
```

### 2. إعداد البيئات

| البيئة | baseUrl | socketUrl |
|--------|---------|-----------|
| `development` | `http://10.0.2.2:8082/api` | `ws://10.0.2.2:8082/api/socket` |
| `staging` | `https://api.elmogps.com` | `wss://api.elmogps.com/socket` |
| `production` | `https://api.elmogps.com` | `wss://api.elmogps.com/socket` |

> **ملاحظة**: `10.0.2.2` يُمثل `localhost` على المحاكي Android.

### 3. تشغيل التطبيق

```bash
# بيئة التطوير
flutter run

# بيئة الإنتاج
flutter run --dart-define=ENV=production
```

### 4. مفتاح Google Maps

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

---

## بناء نسخة الإنتاج

```bash
# Android APK
flutter build apk --release --dart-define=ENV=production

# Android App Bundle (Google Play)
flutter build appbundle --release --dart-define=ENV=production
```

---

## الاعتماديات الرئيسية

| المكتبة | الإصدار | الاستخدام |
|---------|---------|-----------|
| `flutter_riverpod` | ^2.5.1 | إدارة الحالة |
| `go_router` | ^13.2.0 | التنقل |
| `dio` | ^5.4.3 | HTTP client |
| `web_socket_channel` | ^3.0.3 | WebSocket |
| `google_maps_flutter` | ^2.6.1 | الخرائط |
| `flutter_secure_storage` | ^9.0.0 | تخزين آمن للجلسة |
| `shared_preferences` | ^2.2.3 | تخزين محلي |
| `connectivity_plus` | ^5.0.2 | مراقبة الاتصال |
| `google_fonts` | ^6.2.1 | الخطوط |
| `fl_chart` | ^0.68.0 | الرسوم البيانية |
| `pdf` | ^3.11.0 | توليد PDF |
| `printing` | ^5.13.1 | طباعة ومعاينة وتصدير |
| `share_plus` | ^10.0.0 | مشاركة الملفات |
| `path_provider` | ^2.1.0 | مسارات الملفات |
| `intl` | ^0.20.2 | تنسيق التواريخ والأرقام |
| `uuid` | ^4.5.3 | معرّفات فريدة |

---

## سجل التغييرات

### v1.4.0 — Phase 3: Replay + Speed Chart (+ تحسينات UX)

- **Replay**: شاشة `ReplayReportScreen`، `ReplayController` (Riverpod)، تحكم كامل بالتشغيل والسرعة والمنزلق
- **Speed Chart**: `SpeedChartWidget` + `ChartsReportScreen`، تكامل مع Replay (تظليل زمني، ميني-Chart اختياري)
- **Route tab**: أزرار «الخريطة»، «Replay»، «رسم السرعة» بدون إضافة تبويبات جديدة
- **أداء**: polyline replay مُقَلّل؛ فصل إعادة بناء عناصر التحكم عن خريطة Google لتقليل الـ lag؛ إصلاح حساب فواصل المحاور في `speed_chart` (تجنّب crash عند maxY أو maxX شبه صفري)
- **ترجمة**: مفاتيح Replay و Speed Chart في `AppLocalizations` (4 لغات)

### v1.3.0 — Export PDF + Share Report

- `ReportPdfService`: يبني PDF متعدد الصفحات بـ Header/Footer/Sections
- `ReportShareService`: مشاركة PDF عبر أي تطبيق أو إرسال نص لـ WhatsApp
- `PdfPreviewScreen`: معاينة PDF داخل التطبيق قبل الطباعة أو المشاركة
- `pdfGenerationProvider`: state machine (idle → loading → success/error)
- زرا PDF و Share في AppBar يتفعّلان فقط بعد توليد التقرير
- `_ShareBottomSheet`: اختيار بين PDF / Texte / Imprimer
- إضافة packages: `pdf`, `printing`, `share_plus`, `path_provider`

### v1.2.0 — قسم التقارير المتكامل

- قسم `features/reports` بـ Clean Architecture كامل
- 5 تقارير من Traccar: Résumé، Route، Trajets، Arrêts، Événements
- `ReportFilterState` مع 5 فترات جاهزة + Personnalisé
- `RouteReportMapScreen`: خريطة GPS بـ Polyline ملوّنة + Auto-fit + Legend
- `RoutePointDecimator`: تحسين الأداء (max 800 نقطة)
- ترجمة 30+ نوع حدث Traccar إلى الفرنسية مع severity + ألوان
- دعم كامل للـ loading / empty / error states
- تحويل تلقائي للتواريخ: local ↔ UTC

### v1.1.0 — نظام أوامر الأجهزة

- إضافة `features/commands` بهيكل Clean Architecture كامل
- كتالوج مركزي لـ 15 أمراً (8 تحكم + 7 استعلام)
- دعم أجهزة Teltonika: FMC130، FMC150، FMB140، FMC920
- نظام أمان: فحص السرعة + حوار تأكيد + تسجيل كامل
- شاشتان: `DeviceCommandsScreen` و`CommandLogsScreen`

### v1.0.0 — الإصدار الأول

- خريطة مباشرة بتحديثات WebSocket
- لوحة التحكم والتحليلات
- إدارة المركبات والرحلات
- نظام التنبيهات والإشعارات
- دعم بيئات متعددة (Dev / Staging / Production)

---

## المرحلة القادمة (اختياري)

| الميزة | الوضع |
|--------|-------|
| **تحسينات Replay** | استيفاء بين النقاط، مزيد ضبط الأداء على مسارات ضخمة جداً |
| **Fuel Chart** | يحتاج أجهزة مع attribute وقود موثوق |
| **Geofences** | endpoints معرّفة في TraccarEndpoints |

---

## المساهمة

1. افتح `feature/your-feature` من `main`
2. تأكد من عدم وجود أخطاء: `flutter analyze`
3. أرسل Pull Request مع وصف واضح

---

## الترخيص

حقوق محفوظة © 2025–2026 ELMO GPS. جميع الحقوق محفوظة.
