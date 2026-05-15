# Route Intelligence — Threshold Settings Source (Phase 6B → 6H، كتابة جهاز 6J)

**سياسة الكتابة المركزية:** راجع **`docs/route_intelligence_thresholds_write_policy.md`** (قراءة + تنفيذ **Phase 6J** للجهاز).

وثيقة مصادر القراءة لتخزين وجلب **عتبات تحليل المسار** (`RouteIntelligenceThresholds`). **لا كتابة على المنصة المركزية** في المراحل حتى الـ Phase 6G؛ **Phase 6H**: واجهة تعديل **محلية فقط** (SharedPreferences؛ طبقة `local`) بدون أي POST/PUT لتعديل `attributes` على الخادم. **Phase 6J:** كتابة **عتبات Route Intelligence على الجهاز** عبر **`RouteIntelligenceThresholdsWriteRepository`**. **Phase 6K:** واجهة تعديل/إعادة ضبط **للمركبة فقط** في **`VehicleDetailScreen`** (`RouteIntelligenceVehicleCentralThresholdSection`).

**نطاق:** تحليل الرحلة فقط (توقف، تجاوز سرعة، إشعال).  
**خارج النطاق:** `MapZoomPolicy`، ميزانيات الماركر، وضبط العرض على الخريطة.

---

## Global vs Vehicle Threshold Context

| السياق | المزوّد الأساسي | مصادر الخريطة بالترتيب (أقوى → أضعف) | ملاحظات |
|--------|------------------|----------------------------------------|----------|
| **Vehicle** | **`routeIntelligenceThresholdsForVehicleProvider(vehicleId)`** | `device` → `group` → `user` → `local` → `defaults` | يفضّل مركبة **حية** ثم **أسطول**؛ يحمّل **`GET /groups`** فقط عند **`groupId`** صالح. |
| **Vehicle + trace** | **`routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId)`** | (نفس الدمج) + **`RouteIntelligenceThresholdSources`** لكل حقل | Phase 6F؛ نفس **`thresholds`**؛ واجهة **Phase 6G** (`RouteIntelligenceVehicleThresholdPreview` في **`VehicleDetailScreen`**). |
| **Global** | **`routeIntelligenceGlobalThresholdsProvider`** | `user` → `local` → `defaults` | بدون جهاز ولا مجموعة؛ لإعدادات / معاينة / تقارير بلا `vehicleId`. |
| **Global + trace** | **`routeIntelligenceGlobalThresholdsResolutionProvider`** | (نفس الدمج) + مصادر لكل حقل | Phase 6F؛ نفس **`thresholds`**؛ معاينة read-only في **`SettingsScreen`** (**Phase 6G**). |
| **ثوابت التطبيق فقط** | **`routeIntelligenceThresholdsProvider`** | — (قيمة ثابتة **`RouteIntelligenceThresholds.defaults`**) | للتوافق مع كود قديم يتوقع «الافتراضي الصِرف» دون دمج مستخدم/محلي. |

**تنفيذ الدمج الداخلي:**  
- كامل الطبقات: **`mergeLayeredAttributes`** — يبنى من **`defaults.normalized()`** ثم **`fromAttributes`** بالترتيب: **محلي ← مستخدم ← مجموعة ← جهاز**.  
- كامل الطبقات + **تتبع مصدر**: **`RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources`** (نفس نتيجة **`thresholds`**، مع **`sources`** لكل حقل).  
- عالمي فقط: **`mergeGlobalContextAttributes`** — نفس القاعدة مع إسقاط مجموعة وجهاز.  
- عالمي + مصادر: **`mergeGlobalContextAttributesWithSources`**.

**لماذا `vehicleId.isEmpty` يعيد `defaults` صِرفة في المزوّد الخاص بالمركبة؟**  
للحفاظ على سلوك Phase 6B (اختبارات وشاشات قد تمرّر `''`). عند الحاجة لدمج **user/local** بدون مركبة، استخدم **`routeIntelligenceGlobalThresholdsProvider`**.

---

## مواقع الكود

| العنصر | الموقع |
|--------|--------|
| مفاتيح `elmo.route.*` | **`RouteIntelligenceAttributeKeys`** |
| مفاتيح محلية `elmo.local.route.*` | **`RouteIntelligenceLocalPreferenceKeys`** |
| الدمج من سمات | **`fromAttributes`** + **`normalized()`** |
| دمج كامل | **`mergeLayeredAttributes`** |
| دمج كامل + مصادر (Phase 6F) | **`RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources`** |
| دمج عالمي | **`mergeGlobalContextAttributes`** |
| دمج عالمي + مصادر (Phase 6F) | **`RouteIntelligenceThresholdResolution.mergeGlobalContextAttributesWithSources`** |
| توافق 6C | **`mergeFromGroupThenDevice`** |
| قراءة محلية | **`routeIntelLocalAttributesFromSharedPreferences`** |
| حل مركبة | **`resolveRouteIntelligenceThresholdsForVehicle`** |
| حل مركبة + مصادر | **`resolveRouteIntelligenceThresholdsForVehicleWithSources`** |
| خريطة مجموعات | **`routeIntelGroupAttributesMapProvider`** (`GET /groups`) |
| دمج user + local في المزوّدات | **`_readRouteIntelUserAndLocalLayers`** (ملف المزوّد) |
| معاينة read-only للعتبات + المصادر (Phase 6G) | **`RouteIntelligenceThresholdsPreview`**، **`RouteIntelligenceVehicleThresholdPreview`**، **`RouteIntelligenceGlobalThresholdPreview`** (`route_intelligence_thresholds_preview.dart`) |
| تحرير العتبات المحلية فقط بدون منصة مركزية (Phase 6H) | **`RouteIntelligenceLocalThresholdsEditor`** (`route_intelligence_thresholds_editor.dart`) في **`SettingsScreen`**؛ **`writeRouteIntelLocalThresholdsToSharedPreferences`** / **`clearRouteIntelLocalPreferences`** (`route_intel_local_prefs_writer.dart`) |
| دمج / مسح مفاتيح `elmo.route.*` على `attributes` (تجهيز Phase 6J) | **`route_intelligence_attributes_patch.dart`**؛ قائمة المفاتيح **`RouteIntelligenceAttributeKeys.allKeys`** |
| كتابة مركزية على الجهاز (Phase 6J) | **`RouteIntelligenceThresholdsWriteRepository`** + **`RouteIntelligenceThresholdsWriteRepositoryImpl`**؛ **`routeIntelligenceThresholdsWriteRepositoryProvider`**؛ **`invalidateAfterVehicleRouteIntelCentralWrite`** |
| واجهة مركبة Phase 6K | **`RouteIntelligenceVehicleCentralThresholdSection`** (`route_intelligence_vehicle_central_threshold_editor.dart`)؛ **`route_intel_vehicle_central_edit_permission.dart`** |
| تنسيق عرض المعاينة (قيم / مصادر) | **`route_intelligence_threshold_preview_formatting.dart`** |

---

## ترتيب Fallback — سياق المركبة (كل حقل)

```text
device.attributes
→ group.attributes
→ user.attributes
→ local preferences
→ RouteIntelligenceThresholds.defaults
```

## ترتيب Fallback — السياق العام (كل حقل)

```text
user.attributes
→ local preferences
→ RouteIntelligenceThresholds.defaults
```

---

## `vehicleId` فارغ أو مركبة غير موجودة

- **`routeIntelligenceThresholdsForVehicleProvider('')`** → **`RouteIntelligenceThresholds.defaults`** دون user/local/device/group.  
- **`resolveRouteIntelligenceThresholdsForVehicle`** بدون مركبة محلولة → **`defaults`**.

---

## مفاتيح `attributes` المشتركة (`elmo.route.*`)

| المفتاح | معنى مختصر |
|---------|------------|
| `elmo.route.stopSpeedEnterKmh` | دخول توقف (كم/س) |
| `elmo.route.stopSpeedExitKmh` | خروج توقف |
| `elmo.route.minStopDurationMinutes` | حد أدنى مدة توقف (دقائق) |
| `elmo.route.overspeedThresholdKmh` | عتبة تجاوز السرعة |
| `elmo.route.detectStops` / `detectOverspeed` / `detectIgnition` | تفعيل أنواع الأحداث |

---

## `SharedPreferences` — توحيد Phase 6E

- **تعريف واحد:** **`sharedPreferencesProvider`** يُعرَّف فقط في **`lib/shared/providers/core_providers.dart`**.  
- **`auth_provider`** يستورد نفس المزوّد لـ **`authRepositoryProvider`** (أُزيل التعريف المكرر السابق).  
- **`main.dart`** تستورد **`sharedPreferencesProvider`** من **`core_providers`** لـ pre-warm قبل **`runApp`**.

---

## متى نستخدم أي مزوّد؟

- **تتبع / تقرير مسار / Replay** (مع `vehicleId` معروف): **`routeIntelligenceThresholdsForVehicleProvider(vehicleId)`**.  
- **إعدادات / معاينة / تقرير بلا مركبة**: **`routeIntelligenceGlobalThresholdsProvider`**.  
- **تتبع مصدر العتبات / Debug / معاينة مستقبلية (نفس أرقام [`thresholds`]):**  
  **`routeIntelligenceThresholdsResolutionForVehicleProvider`** أو **`routeIntelligenceGlobalThresholdsResolutionProvider`**.  
- **قيمة ثابتة `defaults` فقط**: **`routeIntelligenceThresholdsProvider`**.

---

## Threshold Source Trace (Phase 6F)

**لماذا؟** لفهم *لماذا* انتهت عتبة معيّنة لهذه القيمة (مثلاً واجهة «معاينة الإعدادات»، شاشة مسؤول، أو سطر debug يوضّح أن تجاوز السرعة جاء من مجموعة وليس من الجهاز).

**كيف يعمل؟**  
- **`RouteIntelligenceThresholdSource`**: `device` | `group` | `user` | `local` | `defaults`.  
- **`RouteIntelligenceThresholdSources`**: مصدر **لكل** حقل (`stopSpeedEnterKmh` … `detectIgnition`).  
- **`RouteIntelligenceThresholdResolution`**: يجمع **`thresholds`** النهائية مع **`sources`**.

**قاعدة المصدر لكل حقل:** **أقوى** طبقة (ضمن سلسلة الدمج) **توفر ذلك الحقل بقيمة خام قابلة للتحويل** وفق نفس قواعد **`fromAttributes`** (عبر دوال التحليل في **`route_intelligence_threshold_parsing.dart`**). القيم الخام التي **لا تُفسَّر** عدديًا/booleanًا وفق هذه القواعد لا «تُسجَّل» من تلك الطبقة؛ يُعاد اعتبار الحقل كما لو أن الطبقة لم تمرّره، فيفوز مصدر الطبقة التالية التي تقدّم تحويلًا صالحًا — حتى لو كانت الطبقة الأقوى فارغة لذلك الحقل أساسًا. إذا لم تتوفر أي قيمة قابلة للتحويل في أي طبقة، المصدر **`defaults`**.

**تطبيع (`normalized`)**  
- لا يُرمى استثناء؛ التصحيح يبقى ضمن **`normalized()`** كالسابق.  
- إذا parsing نجح ثم **`normalized()`** عدّل القيمة (مثلاً `stopExit` أقل من `stopEnter` فصُعِد `exit`)، يبقى **`source`** على الطبقة التي قدمت القيم الخام المقروءة — هذا يقرّ أن «المستخدم ضبط هذه الطبقة» حتى لو أصلح التطبيق العلاقة المنطقية بين الحقلين.

**هل يغيّر السلوك الحالي؟** لا. دوال ومزوّدات **`RouteIntelligenceThresholds`** القديمة لم تُغيَّر من حيث القيم؛ مسار **`thresholds`** في **`mergeLayeredAttributesWithSources`** مطابق لـ **`mergeLayeredAttributes`**.

---

## معاينة مصادر العتبات + التحرير المحلي (Phase 6G / 6H)

**Phase 6G — بطاقة المعاينة read-only**

**الهدف:** عرض **القيم الفعلية** لتحليل المسار **ومصدر كل حقل** (Device / Group / User / Local / Default). لا تعديل داخل هذه البطاقة.

| الموضع | الملفات | السياق |
|--------|---------|--------|
| **تفاصيل المركبة** | **`VehicleDetailScreen`** | **`RouteIntelligenceVehicleThresholdPreview`** → **`routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId)`**. |
| **الإعدادات** | **`SettingsScreen`** قسم التفضيلات | **`RouteIntelligenceGlobalThresholdPreview`** → **`routeIntelligenceGlobalThresholdsResolutionProvider`**. أسفلها (Phase 6H) **`RouteIntelligenceLocalThresholdsEditor`**. |

**التحميل والأخطاء:** أثناء تحميل **`SharedPreferences`** أو خريطة المجموعات (عند وجود **`groupId`**) تُعرض أشرطة تحميل/تحذير خفيف كما في Phase 6G.

**Phase 6H — `RouteIntelligenceLocalThresholdsEditor` (محلي فقط)**

- لا مزامنة مع الإعدادات المركزية على الخادم؛ الحفظ عبر **`writeRouteIntelLocalThresholdsToSharedPreferences`** إلى **`SharedPreferences`**.
- طبقة **`local`** **لا تغلب** **`user` / `group` / `device`**؛ ترتيب الدمج بدون تغيير (انظر الجداول أعلاه).
- **`clearRouteIntelLocalPreferences`** تمسح **فقط** مفاتيح **`RouteIntelligenceLocalPreferenceKeys.allPreferenceKeys`**.
- **`parseRouteIntelLocalFormInputs`** يمنع القيم العددية السيئة؛ **`normalized()`** يضبط العلاقات (مثل **`stopExit ≥ stopEnter`**).

---

## ما يبقى لمراحل لاحقة (بعد Phase 6K)

**Phase 6I — سياسة كتابة مركزية** موثَّقة في **`docs/route_intelligence_thresholds_write_policy.md`**.

**Phase 6J — كتابة جهاز:** مُنفَّذ — **`saveVehicleThresholds` / `clearVehicleThresholds`**.

**Phase 6K — واجهة المركبة:** مُنفَّذ — **`RouteIntelligenceVehicleCentralThresholdSection`** في **`VehicleDetailScreen`**.

| الخيار | الحالة |
|--------|--------|
| **`GET /server`** كمصدر عتبات | غير مستخدم |
| كتابة **`attributes` على الجهاز** — Route Intelligence | **Phase 6J — منفّذ** |
| كتابة **`attributes` على المجموعة / المستخدم** | غير منفّذ بعد |
| تحرير طبقة محلية ضمن كل مركبة (UI مخفِّف لمستخدم ميداني، إن لزم) | اختياري لاحقاً |
| واجهة تحرير **group** + مسارات أخرى | Phase 6L+ |

---

## المخاطر والتخفيف

| المخاطرة | التخفيف |
|----------|---------|
| بيانات سيئة | `fromAttributes` لا يرمي؛ **`normalized()`**. |
| طلبات زائدة | **`/groups`** فقط عند **`groupId`** صالح في سياق المركبة. |

---

*آخر تحديث: Phase 6K — واجهة عتبات المسار للمركبة في التكوين المركزي؛ كتابة الجهاز من 6J؛ التحرير المحلي من الإعدادات؛ المعاينة read-only؛ مجموعة/مستخدم لاحقاً.*
