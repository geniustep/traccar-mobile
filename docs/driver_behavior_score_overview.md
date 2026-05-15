# نقاط سلوك القيادة على مستوى الرحلة — Phase 9A (Core)

المسار في المستودع: `docs/driver_behavior_score_overview.md`.

---

## 1. الهدف

حساب **`DriverBehaviorScore`** لكل **`TripSegment`** ليعكس — بشكل تقريبي ومبدئي — جودة السلوك خلال **نافذة رحلة واحدة** (مسافة، مدة، أحداث تجاوز سرعة، توقف، إشعال عند توفره)، دون الاعتماد على واجهات إعدادات أو `l10n` داخل الطبقة الأساسية (`lib/features/map/core/`).

النتيجة تشمل:

- درجة رقمية بين **0 و 100** (عند **`isScorable == true`**)،  
- **`riskLevel`** والتصنيف **`classificationCode`** (رموز آلة لربطها بالترجمة لاحقًا)،  
- **`breakdown`** لعقوبات كل فئة بعد السقوف،  
- **`factors`** قائمة عوامل ذات **`code`** ثابت (`overspeed`, `heavyOverspeed`, `longStops`, …).

لم تُضف واجهات كبيرة في Phase 9A — فقط النواة، الاختبارات، والوثائق.

(لاحقًا أُضيفت **9B** و**9C** لعرض ورقة تفاصيل من شاشة التتبع؛ انظر أسفل الوثيقة.)

---

## 2. لماذا trip-level أولًا وليس driver-level؟

- **الرحلة** هي وحدة بيانات مستقرة: لها بداية، نهاية، ملخص مسافة/مدة، وتكديس أحداث مسار من **`RouteEventAnalyzer`** عبر **`TripSegment`**.
- تجميع **اليوم / الفترة** للمركبة موجود كنواة (**§12 Phase 9D**)؛ عرض ملخّص خفيف على شاشة التتبّع في **§13 (Phase 9E)**.
- عدم خلط «تقييم سائق» مع «تقييم رحلة» يقلل الظلم عندما تكون عيّنة واحدة قصيرة أو ناقصة.

---

## 3. المكوّنات (الملفات)

| الملف | الدور |
|--------|--------|
| `lib/features/map/core/driver_behavior_score_models.dart` | `DriverBehaviorScore`, `DriverBehaviorScoreBreakdown`, `DriverBehaviorScoreFactor`, `DriverRiskLevel` |
| `lib/features/map/core/driver_behavior_score_config.dart` | `DriverBehaviorScoreConfig` + **`defaults`** + **`copyWith`** + **`normalized()`** + **`cacheKey`** + مساواة (**`==`/`hashCode`**) |
| `lib/features/map/presentation/providers/driver_behavior_score_config_provider.dart` | **`driverBehaviorScoreConfigProvider`** — يعيد **`defaults` فقط** (Phase **9G**) |
| `lib/features/map/core/driver_behavior_score_calculator.dart` | `DriverBehaviorScoreCalculator.calculateTripScore` + **`TripSegmentBehaviorScoreExtension`** (`behaviorScore`) |

---

## 4. المنطق المبدئي (ملخّص)

1. **قابلية التقييم (`isScorable`)**  
   تتطلب رحلة **صالحة عدديًا** ومدة لا تقل عن **`minScorableDuration`** (افتراضي **3 دقائق**) ومسافة لا تقل عن **`minScorableDistanceKm`** (افتراضي **0.5 km**).  
   هذه العتبات **أعلى** من حد القبول الفيزيائي لـ **`TripSegmenter`** فقط؛ لذلك قد توجد **`TripSegment`** في القائمة لكن **`isScorable == false`** (الثقة منخفضة).

   عند **`!isScorable`**: **`score = 0`**, **`riskLevel = unknown`**, **`classificationCode = unknown`**, وعامل **`shortTrip`** (رمز الثقة؛ بدون خصم رقمي مقصود على الدرجة لأن الدرجة غير معتمدة للعرض كنقاط سلوك حقيقية).

2. **تجاوز السرعة**  
   العامل الأقوى: حصة قبل السقف **`maxSpeedPenalty`**. مع **`RouteEventAnalysisResult`** يُفرّق بين تجاوز «عادي» وتجاوز **شديد** عند **`speed >= severeOverspeedKmh`**. بدون تحليل: إذا كان **`maxSpeedKmh`** فوق نفس العتبة ووُجدت تجاوزات، تُعامل كلها كشديدة بتقريب محافِظ.

3. **التوقفات**  
   عقوبة **محافظة** ومحدودة بـ **`maxStopPenalty`**:  
   - نصيب زمني طويل من التوقّف ضمن مدة الرحلة (`longStops`)؛  
   - كثافة توقّف زائدة نسبة للمسافة (`excessiveStops`) دون اعتبار كل توقف مخالفة.

4. **الإشعال**  
   إذا **`hasIgnitionData == false`** لا تُطبَّق أي عقوبة. عند وجود بيانات وعدد انتقالات يفوق **`ignitionTransitionsSoftMax`**، يُطبَّق جزء ثانوي ومحدود بـ **`maxIgnitionPenalty`**.

5. **الكفاءة / التباطؤ داخل الرحلة**  
   جزء **`efficiency` / `lowFlow`** صغير جدًا: متوسط سرعة منخفض مع عدد توقفات لا يقل عن **`efficiencyStopCountFloor`**؛ سقف **`maxEfficiencyPenalty`** منخفض حتى لا «يعاقب وسط المدينة».

6. **رحلة «نظيفة»**  
   لا تجاوزات، وزمن توقّف غير مسيطر، ولا جزء الكفاءة: يُضاف عامل **`cleanTrip`** (نقاط 0؛ إعلامي).

7. **السقف الكلي للعقوبات**  
   **`totalPenalty ≤ maxTotalPenalty`** ثم **`score = round(clamp(baseScore - totalPenalty, 0, 100))`**.

---

## 5. مستويات المخاطر (`DriverRiskLevel`)

بعد حساب **`score`** (للقابلة للتقييم فقط):

| إذا `score ≥ excellentMin (90)` | `excellent` |
| بين `goodMin (75)` و `89` | `good` |
| بين `moderateMin (55)` و `74` | `moderate` |
| أقل من `55` | `highRisk` |

عند **`!isScorable`**: **`unknown`**.

---

## 6. القيم الافتراضية (`DriverBehaviorScoreConfig.defaults`)

- **`baseScore`**: 100  
- **عتبات الشريط**: `excellentMin=90`, `goodMin=75`, `moderateMin=55`  
- **تجاوز السرعة**: `overspeedEventPenalty=5`, `severeOverspeedEventPenalty=10`, `severeOverspeedKmh=120`, `maxSpeedPenalty=40`  
- **توقف**: `longStopPenalty=3`, عتبة نصيب المدة `longStopShareThreshold≈0.45`, مرجع كثافة `referenceStopsPerKm=2.5`, `maxStopPenalty=20` …  
- **إشعال**: `ignitionTransitionPenalty=2`, `ignitionTransitionsSoftMax=4`, `maxIgnitionPenalty=10`  
- **كفاءة**: `efficiencyPenalty=3`, `maxEfficiencyPenalty=6` مع عتبات متوسطة المنخفضة للسرعة وعدد التوقفات  
- **سقف إجمالي**: `maxTotalPenalty=80`  
- **قابلية تقييم**: `minScorableDistanceKm=0.5`, `minScorableDuration=3 minutes`

التهيئة **لا تُقرأ من الإعدادات** في Phase 9A؛ يمكن تمرير **`DriverBehaviorScoreConfig`** مخصصًا من الاختبارات أو من طبقة تجميع مستقبلية.

---

## 7. ما لا يُحسب بعد (مجال Phase 10+ تقريبًا)

لا تدخل المرحلة 9A:

- فرملة عنيفة أو تسارع عنيف؛  
- المنعطف الحاد؛  
- استهلاك الوقود؛  
- تصنيف نوع الطريق أو السرعة اللحظية على خلفية المنطقة.

---

## 8. المراحل المقترحة التالية

- **ما بعد 9F:** تعميق التفاعل (الضغط على أفضل رحلة، تقارير، لوحة أسطول) أو تصدير — دون تعديل **`DailyVehicleBehaviorScoreCalculator`**.

(تم تنفيذ **9D** نواة تجميع يومية/فترة — انظر §12؛ **9E** بطاقة ملخص — §13؛ **9F** ورقة تفاصيل الفترة — §14.)

---

## 9. العلاقة مع Phase 8

- **`TripSegment`** لا يُخزَّن بداخله نقاط خام؛ **`DriverBehaviorScoreCalculator`** يقرأ مجاميع **`TripSegment`** ويستخدم **`RouteEventAnalysisResult`** اختياريًا إن كان لديك نفس شريحة التحليل المستخدمة أثناء التقطيع. انظر أيضًا **`docs/trip_segmentation_overview.md`** و**`docs/map_screens_overview.md`**.

---

## 10. Phase 9B — عرض خفيف في قائمة الرحلات (UI)

- **المكان:** لوحة **`VehicleTrackingScreen`** → بطاقات **`TripsListSection`** أسفل **`RouteEventTimeline`** عند توفر نقاط مسار في النافذة؛ **وفوقها مباشرة** بطاقة **`DailyVehicleBehaviorScoreCard`** (**§13 Phase 9E**) لتلخيص تقييم **الفترة**؛ الضغط عليها يفتح ورقة **`DailyBehaviorScoreDetailsSheet`** (**§14 Phase 9F**).
- **البيانات:** يُحسب **`DriverBehaviorScore`** مرة واحدة مع كل تحديث لذاكرة **`TripSegmenter`** (نفس مفتاح الذاكرة لـ **`_tripSegments`**)، ويُمرَّر كخريطة **`scoresByTripKey`** إلى **`TripsListSection`** (`selectionKey` → نقاط).
- **العرض:** **`TripBehaviorScoreBadge`** يعرض سطرًا واحدًا تقريبًا ويستدعي ورقة **§11** عند الضغط؛ إذا **`isScorable`**: `{driverScoreLabel} {score} · {étiquette de risque}`؛ إذا **غير قابلة للتقييم**: **`driverScoreNotScorable`** مع **`driverScoreTripTooShort`** (ما عدا حالة **`invalidTrip`** حيث يُعرض «غير مقيّم» فقط). **لا** يُعرض **`Score 0`** كدرجة حقيقية للرحلات غير القابلة للتقييم.
- **`l10n`:** مفاتيح **`driverScore*`** في **`AppLocalizations`** (EN / AR / FR / ES).
---

## 11. Phase 9C — تفاصيل التقييم (Bottom Sheet)

- **المكان:** **`VehicleTrackingScreen`** → **`TripsListSection`**؛ الضغط على **`TripBehaviorScoreBadge`** (سطر التقييم تحت ملخص المسافة/المدة) يفتح **`TripBehaviorScoreDetailsSheet`** عبر **`showModalBottomSheet`**.
- **المحتوى:** يعرض حالة «مقيّم / غير مقيّم»، الدرجة النهائية و**شريط المخاطر** عند **`isScorable`**، وشرح موثوقية بسيط؛ **تفصيل العقوبات** من **`DriverBehaviorScore.breakdown`** (إخفاء البنود ذات القيمة الصفرية)؛ قائمة **العوامل** من **`factors`** بعد ترجمة **`code`** إلى نصوص **`driverScoreReason*`** عبر **`DriverBehaviorScoreUi`** — **دون** إظهار رموز خام للمستخدم.
- **الرحلات غير القابلة للتقييم:** لا تُعرض **breakdown مضلّل**؛ نص **`driverScoreTripScoredNo`** و**`driverScoreReasonShortTrip`** أو **`driverScoreNotReliableEnough`** (حسب عامل **`invalidTrip`**). **لا تُعرض «Score 0»** كنتيجة حقيقية.
- **السلوك المحسوب:** الورقة **لا تغيّر** الحساب؛ تعتمد فقط على **`DriverBehaviorScore`** المُمرَّر من الخريطة المعاد احتسابها مع الرحلات (نفس منطق 9A).
- **رحلة «هادئة»:** عند **`totalPenalty ≈ 0`** تُعرض **`driverScoreSteadyDriving`** ويُخفى قسم العوامل الزائد لتفادي التكرار مع **`cleanTrip`**.

---

## 12. Phase 9D — Daily Vehicle Behavior Score (Core فقط)

- **الملفات:** **`lib/features/map/core/daily_behavior_score_models.dart`** (`DailyVehicleBehaviorScore`, **`TripBehaviorScoreEntry`**) و**`lib/features/map/core/daily_behavior_score_calculator.dart`** (`DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore`). **لا تعدّل هذه الملفات** لعرض المرحلة 9E؛ العرض يبقى في الطبقة `presentation/` و**§13**.
- **المدخلات:** قائمة **`TripSegment`** لفترة واحدة (يوم، نافذة تتبع، إلخ).
- **خطوات مستوى الرحلة:** لكل رحلة يُستدعى **`DriverBehaviorScoreCalculator.calculateTripScore`** بنفس **`DriverBehaviorScoreConfig`** المرّر.
- **الدرجة المركّبة:** متوسط **وزني** على الرحلات **`isScorable` فقط**: الوزن **`max(distanceKm, 1.0)`** (كم رحلة أطول تُمثّل نصيبًا أكبر). تُدوّر وتُحصر **`[0، 100]`**.
- **استبعاد غير القابلة للتقييم:** لا تُدخل في وزن أو وسيط الدرجة؛ **`unscorableTrips`** يحصيها فقط. إن **كل** الرحلات غير قابلة: **`isScorable = false`**, **`riskLevel = unknown`**, **`score = 0`**.
- **Risk للفترة:** نفس حدود **`DriverBehaviorScoreConfig`** (**`excellentMin` / good / moderate**) كما في حساب الرحلة (`DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore`).
- **أفضل / أسوأ رحلة:** من الرحلات القابلة للتقييم فقط؛ عند تعادل الدرجة يُحتفَظ بـ **أول رحلة** في ترتيب القائمة (**`>`** لتحسين الأفضل و**`<`** لتحسين الأسوأ دون تجاوز عند التساوي).
- **التجميعات:** **`totalDistanceKm`**, **`totalDuration`**, **`totalStops`**, **`totalOverspeedEvents`**, **`totalStopDuration`** تجمع على **جميع** الرحلات مهما كان **`isScorable`**.

---

## 13. Phase 9E — Daily Vehicle Behavior Score (عرض في التتبّع)

- **الملفات:** **`lib/features/map/presentation/widgets/daily_vehicle_behavior_score_card.dart`**؛ **`lib/features/map/presentation/utils/daily_behavior_score_formatters.dart`** (`DailyBehaviorScoreUi`)؛ مفاتيح **`dailyScore*`** في **`AppLocalizations`** (EN / AR / FR / ES).
- **المكان:** **`VehicleTrackingScreen`** → لوحة الأسفل → **`_RouteStatsSection`**: بعد **`RouteEventTimeline`** (إن وُجد)، **قبل** عنوان وقائمة **`TripsListSection`**.
- **الحساب:** عند تحديث ذاكرة **`TripSegmenter`** يُحسب **`DailyVehicleBehaviorScore`** مرة واحدة عبر **`DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(trips: _tripSegments)`** بجانب خريطة **`_tripBehaviorScores`** (لا إعادة حساب داخل **`build`** المتكرر بلا تغيّر مفتاح الذاكرة).
- **إن `isScorable`:** سطر **`{driverScoreLabel} {score} · {مستوى الخطر}`** (نفس **`driverScore*`** للتسميات) + إجماليات (عدد الرحلات، المسافة، تجاوزات السرعة، التوقفات) + نسبة قابلة للتقييم + **أفضل / أضعف رحلة** (عنوان **`tripTitle`** فقط).
- **إن لم تُقيَّم الفترة (`!isScorable`):** **لا** يُعرض **`Score 0`**؛ يُعرض **`dailyScoreNotScorable`** و**`dailyScoreInsufficientData`** عند وجود رحلات لكن لا شيء قابلًا للتقييم؛ مع بقاء عدّاد الرحلات وإجماليات المسافة/الأحداث حيث ينطبق. **لا توجد رحلات:** **`dailyScoreNoTrips`**.
- **الطبقة الأساسية:** **لا تُعدَّل** **`DailyVehicleBehaviorScoreCalculator`**؛ البطاقة **للعرض** فقط.
- **Phase 9F:** الضغط على **`DailyVehicleBehaviorScoreCard`** يفتح **`DailyBehaviorScoreDetailsSheet`** — انظر §14.

---

## 14. Phase 9F — Daily Score Details Sheet

- **الملف:** **`lib/features/map/presentation/widgets/daily_behavior_score_details_sheet.dart`** (`DailyBehaviorScoreDetailsSheet.show`)؛ مفاتيح **`dailyScoreDetailsTitle`**, **`dailyScoreEvaluatedTrips`**, **`dailyScoreUnscoredTrips`**, **`dailyScoreTotalDuration`**, **`dailyScoreTotalStopDuration`**, **`dailyScoreUnscoredExcludedHint`**, **`dailyScoreNoEvaluatedTrips`**, **`dailyScoreTapForDetails`**, **`dailyScoreBestTripLabel`** / **`dailyScoreWorstTripLabel`** في **`AppLocalizations`**.
- **الربط:** **`VehicleTrackingScreen`** يمرّر **`onDailyScoreDetails`** إلى **`DailyVehicleBehaviorScoreCard`** (معامل **`onTap`** على البطاقة).
- **المحتوى:** عند **`isScorable`**: الدرجة + مستوى الخطر؛ صفوف **رحلات / مقيّمة / غير مقيّمة**؛ مسافة؛ مدة إجمالية؛ تجاوزات؛ توقفات؛ مدة توقفات؛ أفضل وأسوأ رحلة عند وجودهما؛ و**`dailyScoreUnscoredExcludedHint`** إذا **`unscorableTrips > 0`**. عند **`!isScorable`**: **بدون Score 0**؛ **`dailyScoreNotScorable`** و**`dailyScoreInsufficientData`** وعدّاد الرحلات عند وجودها؛ **`dailyScoreNoEvaluatedTrips`** عند عدم أي رحلة مقيّمة لكن توجد رحلات.
- **الحساب:** الورقة **عرض** لـ **`DailyVehicleBehaviorScore`** فقط؛ بدون أي تعديل على **`DailyVehicleBehaviorScoreCalculator`**.

---

## 15. Phase 9G — Score Config Foundation (Core فقط)

- **لا واجهة ولا API ولا تحرير تخزين** في هذه المرحلة؛ لا تغيير على **`VehicleTrackingScreen`**, **`TripsListSection`**, البطاقات، أو الأوراق.
- **`DriverBehaviorScoreConfig`**: توسيع توثيق الحقول (عتبات الشرائط، تجاوزات، توقّف، إشعال، كفاءة، سقوف جزئية/كلية، **`minScorable*`**)، مع الحفاظ على **نفس القيم الافتراضية** عدديًا لمنافسة المراحل 9A–9F.
- **`normalized()`**: نسخة **آمنة** للاستخدام وقت التشغيل — ترفض **سلبية** و**غير منتَهٍ (`NaN`/`Infinity`)**، وتصحّح **`excellentMin ≥ goodMin ≥ moderateMin`** غير المعقول وتضبط **سقوف العقوبات** لتبقى داخل **`maxTotalPenalty ≤ baseScore`** وفق المنطق الحالي؛ وتُصلح **`minScorableDistanceKm`** و**`minScorableDuration`** (صفري أو سالب → **`defaults`**). الوظيفة **ثابتة على `defaults`** (أي `defaults.normalized()` يُقارن **`==`** مع **`defaults`**).
- **`cacheKey`**: سلسلة ثابتة مبنية على الشكل المعياري لاستعمال **memoization** لاحقًا.
- **المساواة**: **`operator ==`** و**`hashCode`** على كل الحقول للمقارنة واختبار التكامل.
- **الاستدعاء في الحاسبات**: **`DriverBehaviorScoreCalculator.calculateTripScore`** يستعمل **`config.normalized()`** عند الدخول؛ **`DailyVehicleBehaviorScoreCalculator`** يطبّق نفس المصدر الموحّد لتهيئة الفترة و**`riskLevelFromPeriodScore`** تستخدم **`normalized()`** لضمان شرائط آمنة عند الاستدعاء المستقل.
- **Provider**: **`driverBehaviorScoreConfigProvider`** يجيب **`DriverBehaviorScoreConfig.defaults`** الآن؛ **لم يُربَط بعد** بتسلسل الأولويات المقترح (**device ← group ← user ← local ← defaults**) — ذلك مرشّح لـ **Phase 9H** أو لاحقًا عند ظهورة الحاجة.
