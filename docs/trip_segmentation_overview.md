# تجزئة الرحلات — Trip segmentation (Phase 8)

هدف المرحلة: تحويل تسلسل **`RoutePoint`** داخل نافذة زمنية (يوم أو من/إلى) إلى **قائمة رحلات منطقية** يمكن عرضها، فتحها على خريطة، وإعادة تشغيلها (Replay)، **بدون** إنشاء نقاط طرفية شبكية جديدة؛ الاعتماد فقط على المسار المُحمَّل حالياً (`routeDetailProvider` / `reportRouteProvider`؛ **نفس تدفق تقرير المسار المركزي** دون نقاط طرفية شبكية جديدة لهذه المرحلة).

المسار: `docs/trip_segmentation_overview.md`.

---

## 1. المكوّنات

| جزء | الملف | الوظيفة |
|-----|-------|----------|
| النماذج | `lib/features/map/core/trip_segment_models.dart` | **`TripSegmentationConfig`**: عتبات التحرك، أدنى مدة/مسافة للرحلة، مدة توقف تنهي الرحلة، أكبر فجوة زمنية بين نقطتين، buffer لطلب **`ReportFilterParams`**. **`TripSegment`**: حقول ملخص الواجهة. |
| المُقطّع | `lib/features/map/core/trip_segmenter.dart` | **`TripSegmenter.build`**: تنقية زمنياً وفجوات نقاط؛ استخراج فترات «حركة»؛ رفض الرحلات القصيرة جداً؛ لكل قطعة نقاط: **`RouteEventAnalyzer.analyze(..., thresholds)`** ثم **`enrichRouteIntelStopsFromRoutePoints`**. |
| الملخصيات | `lib/features/map/core/trip_segment_summary.dart` | **`tripPathDistanceKm`**, **`tripAverageSpeedKmh`**, **`reportFilterParamsForTrip`**. |
| واجهة القائمة | `lib/features/map/presentation/widgets/trips_list.dart` | عرض قائمة؛ أزرار **عرض على الخريطة** و **إعادة التشغيل**. |
| تنسيق | `lib/features/map/presentation/utils/trip_formatters.dart` | نصوص العرض الموحَّدة بالاعتماد على **`AppLocalizations`**. |
| خريطة الرحلة | `lib/features/reports/presentation/screens/trip_detail_map_screen.dart` | غلاف رقيق على **`RouteReportMapScreen`**. |

---

## 2. منطق التقسيم (ملخّص)

1. **ترتيب** النقاط حسب **`fixTime`**.
2. **شق الزمن بين النقاط:** إذا كان الفرق بين نقطتين متتاليتين > **`maxPointGapDuration`** يُعتبر قطعًا للمسار؛ تُقيَّم كل قطعة مستقلاً.
3. **داخل كل قطعة:** تُعتبر نقطة «متحركة» إذا **السرعة ≥ `movingSpeedKmh`** أو (الإشعال مفعّل **و** السرعة ≥ **`ignitionAssistMinSpeedKmh`**).
4. **بداية الرحلة:** أوّل نقطة متحركة بعد غياب رحلة.
5. **نهاية الرحلة:** لو تراكمت مدة تقفّ غير متحركة **≥ `stopGapDuration`** منذ آخر نقطة متحركة، تُنهى الرحلة عند آخر نقطة متحركة (لا يُدخل الجزء الطويل من التوقف في نفس الرحلة بعد التقييم).
6. **الفرز النهائي:** تُرفض أي مقطع لا يحقق **`minTripDuration`** و **`minTripDistanceKm`**.

لا يتم دمج هذا المنطق مع **ترتيب عتبات Route Intelligence للأسطول** (device/group/user/local) — عتبات التقسيم محلية افتراضياً ضمن **`TripSegmentationConfig.defaults`**.

---

## 3. العلاقة مع Route Intelligence

لكل **`TripSegment`** يُمرَّر **نفس قائمة نقاط الرحلة الفرعية** إلى **`RouteEventAnalyzer`** مع **`routeIntelligenceThresholdsForVehicleProvider`** الفعّالة في شاشة التتبّع (بدون تغيير المحلّل نفسه). النتيجة ملء:

- عدد التوقفات المستوفية لشرط المحلّل، مجموع مدة التوقّف؛
- عدد تجاوزات السرعة؛
- عدد انتقالات الإشعال + **`hasIgnitionData`**.

التثبيث على العناوين يتم عبر **`enrichRouteIntelStopsFromRoutePoints`** كما في المسار الكامل.

---

## 4. الوقت و Timezone و Replay

- **`RoutePoint.fixTime`** في التطبيق يتبع تفسير JSON الحالي (`toLocal()` عند **`fromJson`**).
- عند فتح الخريطة أو Replay لرحلة، تُنشأ **`ReportFilterParams`** عبر **`reportFilterParamsForTrip`**: **`from` / `to` في UTC** = `trip.start/end` المحوَّلة إلى UTC **± buffer** (**`TripSegmentationConfig.bufferForReportParams`**، افتراضي ~25 ثانية) لالتقاط أول وآخر عيّنة بأمان على الحدّود.

ذلك يحافظ على توافق **`reportRouteProvider`** مع حساب المنصّة المركزية دون مزامنة خطأ ظاهرة.

---

## 5. أمثلة سلوكية (مبدئية)

- **حركة واحدة طويلة** → غالباً **رحلة واحدة**.
- **توقّف عمليًا طويل بعد قيادة** (≥ `stopGapDuration`) بدون قطع شبكة → رحلة لمرحلة الحركة، ثم انتظار رحلة أخرى عند بدء تحرّك من جديد إن طرأ.
- **انقطاع تتبّع بين نقطتين** لفترة > `maxPointGapDuration` → رحلات منفصلة حتى لو كانت المركبة فعلاً في رحلة واحدة؛ هذا مقصود لحماية تفسير المسار المعطوب.

---

## 6. اختبارات

- المنطق: `test/features/map/core/trip_segmenter_test.dart`
- Replay/تنسيق: `test/features/reports/trip_report_params_test.dart`، `test/features/map/presentation/trip_formatters_test.dart`

---

## Phase 9A — نقاط السلوك على مستوى الرحلة (Core)

- تنفيذ **نواة** تقدير نقاط بعد الرحلة: **`DriverBehaviorScoreCalculator`** وأزواج **`DriverBehaviorScore` / `DriverBehaviorScoreConfig`** في `lib/features/map/core/driver_behavior_score_*.dart`؛ التفاصيل والقيم والعوامل: **`docs/driver_behavior_score_overview.md`**.  
- **لا** تعتمد على `l10n` داخل الـ Core؛ تُستخدم **رموز `code`** فقط لتربيط الواجهة لاحقًا.

---

## Phase 9 (اقتراحات إضافية)

- ربط اختياري ل **`TripSegmentationConfig`** بتفضيلات مركزية أو محلّية (بدون خلط ترجيح **`RouteEventAnalyzer`**).
- تصدير الرحلات (CSV/PDF) أو مزامنة مع تقارير **Trips** من الخادم إن وُجدت واجهة قياسية.
- تسمية عنوان بداية/نهاية الرحلة بشكل أكثر تماسكًا مع عنوان التوقفات.
