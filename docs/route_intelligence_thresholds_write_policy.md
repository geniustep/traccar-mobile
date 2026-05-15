# Route Intelligence — سياسة الكتابة المركزية (Phase 6I → 6K)

**Phase 6K — واجهة المركبة:** من `VehicleDetailScreen` يُسمح للمستخدمين المخوّلين بتحرير عتبات تحليل المسار **لهذه المركبة فقط** (`RouteIntelligenceVehicleCentralThresholdSection` → `saveVehicleRouteIntelCentral` / `clearVehicleRouteIntelCentral`). إعادة الضبط تزيل **فقط** مفاتيح `elmo.route.*` على الجهاز. لا نصوص UI تذكر اسم مزوّد الخلفية.

**Phase 6J — طبقة البيانات (مركبة فقط):** `saveVehicleThresholds` / `clearVehicleThresholds` عبر `RouteIntelligenceThresholdsWriteRepository`. لا كتابة **مجموعة** ولا **مستخدم**.

**Phase 6I — تصميم:** توحيد قواعد الكتابة، الصلاحيات، وحماية `attributes`.

**قراءة مكمّلة:** `docs/route_intelligence_thresholds_source.md` (مصادر القراءة، ترتيب الدمج، Phase 6F–6H).

**صياغة واجهة المستخدم (ELMOGPS):** أي نص يظهر للمستخدم النهائي يجب ألا يذكر اسم المزوّد التقني الخلفي؛ استعمل مصطلحات مثل *configuration centrale*، *plateforme*، *paramètres centraux*، *configuration de la flotte*، *système*، أو اسم التطبيق **ELMOGPS**.

---

## 1. الوضع الحالي

### 1.1 قراءة

- **مركبة:** `device.attributes` → `group.attributes` → `user.attributes` → تفضيلات محلية → `RouteIntelligenceThresholds.defaults`.
- **عالمي:** `user.attributes` → محلي → افتراضيات التطبيق.
- التفضيلات المحلية: `SharedPreferences` (`RouteIntelligenceLocalPreferenceKeys`) عبر `route_intel_local_prefs_reader.dart` / `route_intel_local_prefs_writer.dart`.
- لا تغيير على ترتيب fallback في هذه المرحلة.

### 1.2 كتابة

- **محلي:** منفّذ — `writeRouteIntelLocalThresholdsToSharedPreferences` و `clearRouteIntelLocalPreferences` (مسح مفاتيح الطبقة المحلية فقط).
- **مركزي — مركبة (Route Intelligence فقط):** منفّذ في **Phase 6J** — `RouteIntelligenceThresholdsWriteRepositoryImpl` يقرأ الجهاز، يدمج أو يزيل مفاتيح `elmo.route.*` فقط، ثم `PUT /devices/{id}` عبر `VehicleDeviceGateway` / `VehicleRemoteDataSource`.
- **مركزي — مجموعة / مستخدم:** غير منفّذ بعد (`saveGroupThresholds` / `saveUserThresholds` ترفض بـ `UnsupportedError` حتى مرحلة لاحقة).
- **نقاط النهاية:** معرفة في `lib/core/api/traccar_endpoints.dart` (`deviceUpdate`, `groupUpdate`, `userUpdate`). عميل HTTP يدعم `put`/`patch` في `TraccarClient`.
- **مستودع المركبات:** `VehicleRepository` يقتصر على القراءة؛ الكتابة المركزية للعتبات تمر عبر مستودع الكتابة أعلاه وليس عبر `VehicleRepository`.

### 1.3 نمط PUT موجود في المشروع

أمثلة ناجزة: `GeofencesRemoteDataSource.updateGeofence` يرسل جسم JSON كاملًا (بما في ذلك الحقول المطلوبة) عبر `TraccarClient.put`. لدمج `attributes` على جهاز/مجموعة/مستخدم يُفترض لاحقًا:

1. `GET` الكيان الحالي (أو الاعتماد على نسخة محدثة في الذاكرة مع مراعاة تعارض الإصدارات إن لزم).
2. دمج مفاتيح `elmo.route.*` فقط في خريطة `attributes`.
3. `PUT` بالجسم الكامل للكيان كما يتوقعه الخادم.

---

## 2. سياسة الكتابة المقترحة (Write Policy)

| الطبقة | أين تُكتب | متى تُستخدم |
|--------|-----------|-------------|
| **Vehicle** | `device.attributes` (`elmo.route.*`) | مدير يريد تجاوزًا لمركبة واحدة فوق المجموعة/المستخدم/المحلي. |
| **Group** | `group.attributes` | مدير يريد قاعدة لأسطول/شركة؛ لا تمس المركبات التي لديها override على الجهاز. |
| **User** | `user.attributes` | تفضيل شخصي أو افتراضي للمستخدم على الطبقات الأضعف؛ يطبَّق فقط إذا كان مسموحًا سياسيًا وليس بديلاً عن RBAC الخادم. |
| **Local** | `SharedPreferences` فقط | لا يُرفع للخادم؛ يبقى كما في Phase 6H. |

### 2.1 أولويات الحفظ والدمج (قراءة بعد الكتابة)

- حفظ على **المركبة** يظهر **أقوى** من المجموعة والمستخدم والمحلي (بعد إعادة الجلب، حسب نفس ترتيب القراءة الحالي).
- حفظ على **المجموعة** لا يغيّر جهازًا له بالفعل قيم `elmo.route.*` على **`device.attributes`**.
- **Reset محلي** (`clearRouteIntelLocalPreferences`) لا يمس أي `attributes` مركزية.
- **مسح override المركبة** (`clearVehicleThresholds` مستقبلًا): إزالة مفاتيح `elmo.route.*` من جهاز ذلك المعرّف فقط؛ تعود المركبة إلى سلسلة group → user → local → defaults.

### 2.2 ما لا يجب فعله

- لا إرسال خريطة `attributes` فارغة أو استبدالًا كاملًا يمحو مفاتيح غير `elmo.route.*`.
- لا حذف أو تعديل مفاتيح خارج نطاق Route Intelligence عند «مسح العتبات».
- لا كسر الحفظ المحلي أو المعاينة read-only (Phase 6G).
- لا تغيير `RouteEventAnalyzer` أو القيم الافتراضية في `RouteIntelligenceThresholds.defaults`.
- لا إظهار اسم المزوّد التقني الخلفي في أي `l10n` أو snackbar أو تحذير للمستخدم.

---

## 3. حماية `attributes`

### 3.1 دمج آمن

استعمل الدوال في `lib/features/map/data/route_intelligence_attributes_patch.dart`:

- `routeIntelThresholdsToAttributeMap` — من `RouteIntelligenceThresholds.normalized()` إلى جميع مفاتيح `elmo.route.*`.
- `mergeRouteIntelligenceIntoAttributes` — نسخة من الـ map الحالية ثم كتابة المفاتيح المسموحة فقط؛ تجاهل أي مفتاح غير مدرج في `RouteIntelligenceAttributeKeys.allKeys`.
- `removeRouteIntelligenceKeysFromAttributes` — حذف **`elmo.route.*` فقط**؛ الإبقاء على باقي المفاتيح.

### 3.2 التحقق (Validation) قبل أي PUT مستقبلي

1. إدخال النموذج / الحمولة → نفس مسار التحليل المستخدم في القراءة حيث ينطبق (`parseRouteIntelLocalFormInputs` أو مسار معادل للمدخلات المركزية).
2. **`RouteIntelligenceThresholds.normalized()`** قبل التحويل إلى خريطة السمات.
3. عدم حفظ قيم غير قابلة للقراءة؛ للمستخدم: رسالة خطأ عامة (مثلاً إعداد غير صالح) **بدون** تفاصيل تقنية أو اسم خادم.

---

## 4. الصلاحيات والقرارات

### 4.1 ما هو متوفر في الكود اليوم

- **`UserEntity` / `UserModel`:** `administrator`, `readonly`, `disabled`, `deviceLimit`, `attributes` (يشمل أدوار التطبيق مثل `appRole` إن وُجدت في الخادم).
- **`UserRole`** (`lib/core/models/user_role.dart`): يشتق من `administrator` و `readonly` — أدوار تقريبية على جانب العميل (`admin`, `technician`, …، `viewer` للقراءة فقط).
- **`deviceReadonly`:** غير معرّف في كيان المستخدم الحالي؛ لا يوجد علم خاص للقراءة فقط على مستوى الجهاز في الطبقة المعروضة.

### 4.2 سياسة مقترحة قبل إظهار أي زر حفظ مركزي

| الحالة | مقترح |
|--------|--------|
| `readonly == true` | منع أي كتابة مركزية؛ المحلي قد يبقى حسب سياسة المنتج (اليوم: مسموح في الإعدادات). |
| مستخدم عادي غير مدير | لا كتابة على `device` أو `group`؛ يُسمح مستقبلًا فقط بـ `user.attributes` لذات المستخدم إذا رضخ الخادم لـ `PUT /users/{self}`. |
| مدير (`administrator` أو دور تقني مفعّل للأسطول) | مسموح بتوجيه كتابة المركبة/المجموعة بعد تأكيد الخادم (قد تختلف صلاحيات الـ API الفعلية عن أعلام JSON — معالجة الأخطاء من الاستجابة إلزامية). |

إذا لم تكن صلاحيات الخادم واضحة من الجلسة، **لا تُضاف أزرار كتابة مركزية** حتى يتوفر تحقق صريح (Phase 6J).

---

## 5. واجهة المستخدم المستقبلية (اقتراح — غير منفّذ في 6I)

- **`VehicleDetailScreen`:** زر «تعديل إعدادات هذه المركبة» للمدير فقط → مسار حفظ على `device.attributes`.
- **`SettingsScreen`:** الإبقاء على التحرير **المحلي فقط** كما هو.
- **شاشة شركة/مجموعة لاحقًا:** تعديل **paramètres de la flotte** → `group.attributes`.

جميع النصوص للمستخدم وفق مصطلحات ELMOGPS أعلاه.

---

## 6. عقد المستودع

`RouteIntelligenceThresholdsWriteRepository` (`lib/features/map/domain/repositories/route_intelligence_thresholds_write_repository.dart`):

| الطريقة | الحالة |
|--------|--------|
| `saveVehicleThresholds` / `clearVehicleThresholds` | **منفّذ (Phase 6J)** |
| `saveGroupThresholds` / `clearGroupThresholds` | غير منفّذ |
| `saveUserThresholds` / `clearUserThresholds` | غير منفّذ |

الطبقة المحلية تبقى خارج هذا العقد (دوال prefs الحالية).

---

## 7. إبطال المزوّدات بعد حفظ مركزي ناجح (مركبة)

بعد **`saveVehicleThresholds` / `clearVehicleThresholds`** بدون خطأ، يُستدعى من مسار التطبيق (مثلاً وحدة تحكم أو Phase 6K):

- `vehiclesListProvider`
- `invalidateVehicleLiveMetadata(ref, vehicleId)` — في `tracking_provider.dart` (يحدّث `_baseVehicleProvider` + `liveVehicleProvider`)
- `routeIntelligenceThresholdsForVehicleProvider(vehicleId)`
- `routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId)`

أو دفعة واحدة: **`invalidateAfterVehicleRouteIntelCentralWrite(ref, vehicleId)`** في `route_intelligence_thresholds_write_provider.dart`.

---

## 8. ما يبقى (Phase 6L وأبعد)

1. **كتابة مجموعة / مستخدم:** تنفيذ دوال العقد المتبقية عند الحاجة، وربما شاشات مسؤول.
2. **مراقبة الأخطاء:** تعارض، `403` — إعادة جلب القائمة دون فقدان سمات أخرى.

---

## 9. صلاحيات واجهة المركبة (Phase 6K)

| شرط | سلوك الواجهة |
|-----|----------------|
| `user == null` أو `readonly == true` أو `UserRole.viewer` | أزرار التعديل مخفية؛ نص `routeIntelVehicleNoPermissionHint`. |
| مستخدم غير viewer وغير readonly (عادة operator / technician / admin) | يظهر «تعديل» و«إعادة ضبط» عند وجود override على الجهاز. |

التحقق في `route_intel_vehicle_central_edit_permission.dart` — قد يُضبط لاحقًا حسب سياسة المنتج.

---

*آخر تحديث: Phase 6K — UI تعديل عتبات المسار للمركبة في التكوين المركزي؛ صلاحيات؛ نصوص بدون مزوّد خلفي؛ إبطال المزوّدات في §7.*
