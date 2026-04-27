# ELMO GPS — منصة إدارة الأسطول الذكية

تطبيق Flutter احترافي لتتبع الأسطول في الوقت الفعلي، مبني على خادم [Traccar](https://www.traccar.org/) مفتوح المصدر.

---

## الميزات الرئيسية

| الميزة | الوصف |
|--------|--------|
| **خريطة مباشرة** | تتبع جميع المركبات على الخريطة بتحديثات فورية عبر WebSocket |
| **لوحة التحكم** | ملخص يومي للأسطول: المركبات النشطة، المسافة، الرحلات، التنبيهات |
| **إدارة المركبات** | بيانات كاملة لكل مركبة مع الحالة، السرعة، والموقع |
| **التنبيهات** | سجل كامل للأحداث مع إشعارات فورية عبر WebSocket |
| **تقارير الرحلات** | تحليل مفصل للمسارات والرحلات |
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
│   ├── config/             # AppConfig (shim → ApiEnvironment)
│   ├── error/              # AppException ونوع كامل من الأخطاء
│   ├── models/             # TraccarDevice، TraccarPosition، TraccarEvent
│   ├── network/            # TraccarClient (Dio + Result<T>)، DioClient (legacy)
│   ├── response/           # Result<S,F> — نمط الإرجاع الموحد
│   ├── socket/             # TraccarSocketService، SocketEventParser
│   └── storage/            # SecureStorageService
├── features/               # Clean Architecture بالميزة
│   ├── auth/               # تسجيل الدخول، جلسة Traccar
│   ├── dashboard/          # ملخص + رؤى
│   ├── vehicles/           # قائمة + تفاصيل المركبات
│   ├── map/                # خريطة مباشرة + تتبع المركبة
│   ├── alerts/             # سجل التنبيهات
│   ├── trips/              # تقارير الرحلات
│   ├── analytics/          # التحليلات الأسبوعية
│   └── notifications/      # تغذية الإشعارات
└── shared/
    └── providers/          # core_providers، traccar_providers
```

---

## API vs WebSocket — متى يُستخدم كل منهما؟

| النوع | متى | أمثلة |
|-------|-----|--------|
| **REST API** | بيانات تاريخية، تحميل أولي، عمليات CRUD | تسجيل الدخول، تقارير الرحلات، التحليلات |
| **WebSocket** | بيانات الوقت الفعلي، التحديثات المستمرة | مواضع المركبات على الخريطة، التنبيهات الفورية، حالة الأجهزة |

### تدفق البيانات

```
المستخدم يفتح الخريطة
    ↓
REST: GET /devices + /positions  →  تحميل كامل مع البيانات الوصفية
    ↓
WebSocket: positions updates      →  تحديث فوري للإحداثيات (بدون REST)
    ↓
mapVehiclesProvider               →  يدمج الاثنين تلقائياً في Riverpod
```

---

## متطلبات التشغيل

- **Flutter** ≥ 3.22 (Dart ≥ 3.3)
- **خادم Traccar** (v5.x / v6.x) — يمكن تشغيله محلياً أو عبر السحابة
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

يتم التحكم في جميع الإعدادات عبر `ApiEnvironment` (`lib/core/api/api_environment.dart`):

| البيئة | baseUrl | socketUrl |
|--------|---------|-----------|
| `development` | `http://10.0.2.2:8082/api` | `ws://10.0.2.2:8082/api/socket` |
| `staging` | `https://api.elmogps.com` | `wss://api.elmogps.com/socket` |
| `production` | `https://api.elmogps.com` | `wss://api.elmogps.com/socket` |

> **ملاحظة للمحاكي Android**: `10.0.2.2` يُمثل `localhost` على الكمبيوتر المضيف.  
> للجهاز الحقيقي: استخدم عنوان IP الشبكة المحلية لكمبيوترك.

### 3. تشغيل التطبيق

```bash
# بيئة التطوير (افتراضي)
flutter run

# بيئة الإنتاج
flutter run --dart-define=ENV=production

# بيئة الاختبار
flutter run --dart-define=ENV=staging
```

### 4. مفتاح Google Maps

أضف المفتاح في `android/app/src/main/AndroidManifest.xml`:

```xml
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
| `connectivity_plus` | ^5.0.2 | مراقبة الاتصال |
| `google_fonts` | ^6.2.1 | الخطوط |

---

## هيكل الكود الشبكي

### `TraccarClient` — العميل الرئيسي

```dart
// كل الطلبات تُرجع Result<T, AppException>
final result = await traccarClient.get<List<TraccarDevice>>(
  TraccarEndpoints.devices,
  fromJson: (data) => (data as List).map(TraccarDevice.fromJson).toList(),
);

result.when(
  success: (devices) { /* استخدم البيانات */ },
  failure: (ex)     { /* عرض الخطأ */ },
);
```

### `TraccarSocketService` — الوقت الفعلي

```dart
// تتصل تلقائياً عند تسجيل الدخول
// وتنقطع عند تسجيل الخروج
// إعادة الاتصال التلقائي مع Exponential Backoff

socketService.messageStream.listen((msg) {
  // msg.positions → List<TraccarPosition>
  // msg.devices   → List<TraccarDevice>
  // msg.events    → List<TraccarEvent>
});
```

---

## المساهمة

1. افتح `feature/your-feature` من `main`
2. تأكد من عدم وجود أخطاء: `flutter analyze`
3. أرسل Pull Request مع وصف واضح للتغييرات

---

## الترخيص

حقوق محفوظة © 2024 ELMO GPS. جميع الحقوق محفوظة.
