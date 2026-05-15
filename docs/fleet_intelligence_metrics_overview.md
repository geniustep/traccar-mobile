# مؤشرات ذكاء الأسطول — Fleet Intelligence Metrics (Phase 10A / Core فقط)

المسار في المستودع: [`docs/fleet_intelligence_metrics_overview.md`](fleet_intelligence_metrics_overview.md).

---

## 1. الهدف

تجميع **ملخص واحد عن أسطول** خلال نافذة زمنية (يوم، أسبوع، نفس نافذة التتبّع، إلخ) من بيانات **جاهزة**: لكل مركبة قائمة **[`TripSegment`](../lib/features/map/core/trip_segment_models.dart)** التي سبق اشتقاقها (**Phase 8**) وتقييمها عبر خط **Phase 9**.

النتيجة **[`FleetIntelligenceMetrics`](../lib/features/map/core/fleet_intelligence_metrics_models.dart)** + قائمة **`FleetVehicleIntelligenceSummary`** توفّر:

- عدّاً للمركبات **النشطة** والخاملة ومع رحلات،  
- مجاميع **رحلات / مسافة / مدة قيادة / مدة توقّف / توقّفات / تجاوزات سرعة**,  
- **متوسط تقييم** للأسطول (من المركبات القابلة للتقييم فقط)،  
- أفضل وأضعف مركبة (حسب تقييم الفترة)،  
- أكثر مركبة نشاطًا (مسافة)، وتجاوزًا للسرعة، وتوقّفًا (مدّة)،  
- قائمة **`vehiclesNeedingAttention`**,  
- **`FleetRiskDistribution`** حسب مستوى خطر الفترة لكل مركبة.

**Phase 10A** تقتصر على **نواة**: نماذج، تهيئة خفيفة، حاسبة، اختبارات، هذه الوثيقة.  
**لا** واجهة لوحة أسطول، **لا** `l10n`، **لا** API شبكية، **لا** تخزين.

---

## 2. العلاقة بمراحل 8 و 9

1. كل **[`TripSegment`](../lib/features/map/core/trip_segment_models.dart)** يعبّر عن رحلة مجزّأة مع مجاميع (مسافة، مدة، توقّف، تجاوزات، إلخ).  
2. لكل مركبة يُستدعى **`DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore`** (**Phase 9D**) على قائمة الرحلات تلك المركبة — نفس منطق **متوسط وزني للرحلات القابلة للتقييم فقط** و**مستوى خطر الفترة** و**أفضل/أسوأ رحلة**.  
3. أسطول **لا يعيد حساب الرحلات**؛ فقط يجمع ما خرج من الخط اليومي لكل مركبة.

التفاصيل المرجعية: [`docs/driver_behavior_score_overview.md`](driver_behavior_score_overview.md)، [`docs/trip_segmentation_overview.md`](trip_segmentation_overview.md).

---

## 3. المدخلات

| النوع | الملف |
|--------|--------|
| **`FleetVehicleTripInput`** | [`fleet_intelligence_metrics_models.dart`](../lib/features/map/core/fleet_intelligence_metrics_models.dart) |
| **`calculate(...)`** | [`fleet_intelligence_metrics_calculator.dart`](../lib/features/map/core/fleet_intelligence_metrics_calculator.dart) |

الاستدعاء النموذجي:

```dart
FleetIntelligenceMetricsCalculator.calculate(
  vehicles: [
    FleetVehicleTripInput(
      vehicleId: '…',
      vehicleName: optionalName,
      trips: tripSegmentsForThatVehicleInWindow,
    ),
    …
  ],
  scoreConfig: DriverBehaviorScoreConfig.defaults, // أو مجرّبة
);
```

 **`FleetIntelligenceMetricsConfig`** (عتبات انتباه، وزن مسافة المركبة) اختياري ويستخدم **`normalized()` + `defaults`**.

لا يوجد جلب مسار أو Riverpod أو خرائط داخل الحاسبة.

---

## 4. المخرجات الأساسية

### 4.1 `FleetVehicleIntelligenceSummary`

للمركبة الواحدة: هوية، إجماليات الرحلات، **`DailyVehicleBehaviorScore`** كامل، **`periodScore`** (قيمة عددية عند **`isPeriodScorable`** وإلا **`null`**)، مستوى الخطر للفترة، أفضل/أسوأ رحلة، **`needsAttention`**, **`isActive`**.

### 4.2 `FleetIntelligenceMetrics`

إجماليات أسطول + **`averageScore`** + **`weightedAverageRaw`** + مؤشرات **أفضل/أضعف/أنشط/أكثر تجاوزًا/أكثر توقفًا** + **`riskDistribution`** + **`vehiclesNeedingAttention`** + قائمة كل المركبات بترتيب المدخل.

---

## 5. كيف يُحسب المتوسط (**`averageScore`**)

1. يُعتبر فقط المركبات حيث **`DailyVehicleBehaviorScore.isScorable == true`**. المركبات **غير المعروفة تقييمًا** (لا توجد رحلات قابلة للتقييم) **لا تدخل المتوسط ولا تخفضه**.  
2. الوزن لكل مركبة قابلة: **`max(totalDistanceKm, minVehicleDistanceWeightKm)`** (افتراضي أرضية **1 كم**).  
3. **المتوسط الوزني الخام** = Σ(score×وزن)/Σوزن)، ثم **تقريب** و **`clamp` إلى \[0،100\]**.  
4. إذا **لم تبق أي مركبة قابلة**: **`isScorable = false`**, **`averageScore = 0`**, **`weightedAverageRaw = null`**.

---

## 6. أفضل / أسوأ مركبة

من بين المركبات **القابلة للتقييم فقط**:

- **الأفضل**: أعلى **`DailyVehicleBehaviorScore.score`**؛ عند التعادل تُختار **أول** مركبة في مصفوفة **`vehicles`** (ترقيم حصرية **`>`**).  
- **الأضعف**: أدنى درجة؛ عند التعادل **أول** فائز بشرط أصغر من بصورة حصرية (نفس روح تعادل **Phase 9D** مع الرحلات).

إذا لم يكن هناك أي مركبة قابلة: **`bestVehicleSummary`** و **`worstVehicleSummary`** تكون **`null`**.

---

## 7. `vehiclesNeedingAttention`

لا تُقييم مركبات **بلا أي رحلة** لهذا الغرض.

خلاف ذلك يُعتبر المركبة تحتاج انتباهًا إذا:

- **`riskLevel == highRisk`** للفترة، **أو**
- المركبة **قابلة للتقييم** و **`periodScore ≤ attentionScoreAtOrBelow`** (افتراضي **55**)، **أو**
- **`riskLevel == moderate`** و **`totalOverspeedEvents ≥ moderateRiskOverspeedAttentionMin`** (افتراضي **6**).

التفضيل الدقيق لكل عتبة: [`fleet_intelligence_metrics_config.dart`](../lib/features/map/core/fleet_intelligence_metrics_config.dart).

---

## 8. مركبات بلا رحلات

للمدخل الذي **`trips.isEmpty`**:

- لا تُعتبر ضمن **`vehiclesWithTrips`** (العدّاد يعتمد قائمة فارغة).  
- **`DailyVehicleBehaviorScore`** يكون حالة فارغة **Phase 9D** (**`unknown`**, **`!isScorable`**).  
- **`inactiveVehicles`** تزيد؛ **`activeVehicles`** لا تشتمل عليها.  
- تُوزَّع ضمن **`unknownCount`** في **`FleetRiskDistribution`**.  
- **لا** يُضاف ذلك إلى قائمة الانتباه الافتراضية.

المجاميع الأسطولية **للمسافة/الوقت/التجاوزات** تكون صفر لهذه المركبة.

---

## 9. حالات طرفية مختصرة

| الحالة | `isScorable` (أسطول) | `averageScore` | `riskDistribution` |
|--------|---------------------|----------------|---------------------|
| لا مدخلات | `false` | `0` | كل الأعداد صفر |
| مركبات بلا رحلات | `false` | `0` | كلها **`unknown`** |
| رحلات لكن كلها غير قابلة للتقييم | `false` | **`0`** (المجاميع تُجمَّع على كل الرحلات) | غالبًا كلها **`unknown`** |

---

## 10. Phase 10B–10F — لوحة ذكاء الأسطول (مُتصلة بالبيانات + ذاكرة مؤقتة)

- **المسار:** [`/fleet-intelligence`](../lib/app/router.dart) داخل **`MainShell`**.  
- **الشاشة:** [`fleet_intelligence_dashboard_screen.dart`](../lib/features/fleet_intelligence/presentation/screens/fleet_intelligence_dashboard_screen.dart).  
- **تنسيق عام:** [`fleet_intelligence_formatters.dart`](../lib/features/fleet_intelligence/presentation/utils/fleet_intelligence_formatters.dart).  
- **دخول سريع:** بطاقة في [`admin_dashboard_screen.dart`](../lib/features/fleet_intelligence/presentation/screens/admin_dashboard_screen.dart).

### Phase 10C — Fleet Intelligence Data Provider (**مُنفَّذ**)

| العنصر | الملف |
|--------|-------|
| الاستعلام + سقف العيّينة | [`fleet_intelligence_query.dart`](../lib/features/fleet_intelligence/domain/fleet_intelligence_query.dart) — **`kFleetIntelligenceDefaultMaxVehicles` = 25** |
| بيانات وصفية للحمولة | [`fleet_intelligence_load_info.dart`](../lib/features/fleet_intelligence/domain/fleet_intelligence_load_info.dart) |
| حالة الواجهة | [`fleet_intelligence_dashboard_state.dart`](../lib/features/fleet_intelligence/domain/fleet_intelligence_dashboard_state.dart) |
| المحمّل (قابل للاختبار بدون شبكة) | [`fleet_intelligence_metrics_loader.dart`](../lib/features/fleet_intelligence/application/fleet_intelligence_metrics_loader.dart) |
| **`fleetIntelligenceMetricsProvider`** + **`fleetDashboardFilterProvider`** | [`fleet_intelligence_metrics_provider.dart`](../lib/features/fleet_intelligence/presentation/providers/fleet_intelligence_metrics_provider.dart) — التصدير القديم في [`fleet_behavior_metrics_provider.dart`](../lib/features/fleet_intelligence/presentation/providers/fleet_behavior_metrics_provider.dart) يوجّه لنفس الملف. |

آلية التحميل (بدون نقطة طرفية شبكية جديدة وبدون كتابة):

1. قائمة المركبات من **`vehiclesListProvider`**.  
2. فلترة اختيارية: **`FleetIntelligenceQuery.groupId`**, **`vehicleIds`**, و**`includeInactive`** (متصلّة من حالة المرشّحات وتُمكن لاحقًا من التوسعة).  
3. ترتيب **متصل أولاً** ثم الاسم.  
4. عيّينة من **`maxVehicles`** (افتراضيًا **25**) تستدعي **`RouteDataSource.getRoute`** (نفس طبقة التقارير).  
5. **`TripSegmenter.build`** مع **`routeIntelligenceGlobalThresholdsProvider`**.  
6. **`FleetIntelligenceMetricsCalculator.calculate`**.

**فشل جزئي:** فشل **`getRoute`** لمركبة واحدة لا يلغي التحميل — تُحمَّل قائمة فارغة لتلك المركبة وتزاد **`FleetIntelligenceLoadInfo.routesFailedPartial`**.

---

### Phase 10D — فلاتر زمنية + تحديث يدوي (**مُنفَّذ**)

- **`FleetDashboardDatePreset`** + **`fleetDashboardLocalBounds`**: [`fleet_dashboard_date_preset.dart`](../lib/features/fleet_intelligence/presentation/fleet_dashboard_date_preset.dart) — اليوم (**من 00:00 محلي حتى الآن**)، الأمس (**00:00–23:59:59**)، آخر 7 أيام (**من منتصف الليل قبل 6 أيام حتى الآن**)، و**Personnalisé / مخصّص** عبر **`showDateRangePicker`**.  
- **`FleetDashboardFilterState`**: [`fleet_dashboard_filter_state.dart`](../lib/features/fleet_intelligence/presentation/fleet_dashboard_filter_state.dart) — **`refreshNonce`** لفرض تحديث بلا تغيير النطاق.  
- **`fleetIntelRefresh`** في شريط التطبيق + **`RefreshIndicator`**.

---

### Phase 10E — Attention Center (**مُنفَّذ**)

| العنصر | الملف |
|--------|-------|
| أسباب الانتباه + قائمة مقيّدة (حتى عنصر **10**) | [`fleet_attention_center_logic.dart`](../lib/features/fleet_intelligence/presentation/utils/fleet_attention_center_logic.dart) |
| بطاقة الواجهة | [`fleet_attention_center_card.dart`](../lib/features/fleet_intelligence/presentation/widgets/fleet_attention_center_card.dart) |

الضغط على الصف يفتح **`/vehicles/:id/track`**.

---

### Phase 10F — ذاكرة تخزين مؤقت قصيرة (**مُنفَّذ**)

| العنصر | الملف |
|--------|-------|
| تخزين **`FleetIntelligenceDashboardState`** + **`fetchedAtUtc`** | [`fleet_intelligence_dashboard_cache.dart`](../lib/features/fleet_intelligence/application/fleet_intelligence_dashboard_cache.dart) |
| **`cacheStableKey`** (بدون **`refreshNonce`**) | [`fleet_intelligence_query.dart`](../lib/features/fleet_intelligence/domain/fleet_intelligence_query.dart) |
| الاستهلاك داخل **`fleetIntelligenceMetricsProvider`** | [`fleet_intelligence_metrics_provider.dart`](../lib/features/fleet_intelligence/presentation/providers/fleet_intelligence_metrics_provider.dart) |

**سياسة:** **`kFleetIntelligenceDashboardCacheTtl` = 3 دقائق** (توصية الوثائق **2–5 دقائق**). لقطة واحدة لكل **`cacheStableKey`**؛ لا يُعاد **`getRoute`** إذا كانت اللقطة صالحة **و** لم يتغيّر **`refreshNonce`** عن قيمته عند الكتابة. يحفظ نتائج **`partial`** كما هي؛ لا تغيير على **`FleetIntelligenceMetricsCalculator`** أو **`TripSegmenter`**.

---

### حدود الأداء وبيانات جزئية (UX)

- إذا تجاوز أسطول المستخدم **`maxVehicles`**، يظهر **`fleetIntelSampleNote`** + **`fleetIntelLimitedToVehicles`**.  
- عند **`getRoute`** جزئي الفاشل يظهر **`fleetIntelPartialRoutes`** + **`fleetIntelPartialData`** + **`fleetIntelAnalyzedVehicles`**.  

---

### النصوص (`l10n`)

لا تدرج جهة تقنية خلفية — تُستخدم «المنصّة», «التكوين المركزي», «الخادم» بشكل عام حيث يلزم. مفاتيح جديدة: **`fleetIntelCustomPeriod`**, **`fleetIntelRefresh`**, **`fleetIntelUpdatedAt`**, **`fleetIntelPartialData`**, **`fleetIntelAnalyzedVehicles`**, **`fleetIntelLimitedToVehicles`**, **`fleetAttention*`** (**EN / AR / FR / ES**).

---

## 11. المرجع الوثائقي للـ UI

- **`docs/fleet_intelligence_dashboard_overview.md`** — هيكل الواجهة والمزوّدات (**Phase 10B–10F**).

---

## 12. هذه المرحلة (10A) في Core لا تشمل ما يلي

- واجهة مستخدم جديدة.  
- نقاط طرفية شبكية جديدة.  
- أي تعديل على **`TripSegmenter`** أو على منطق **Phase 9A/9D** (إلا عند كان ضروريًا ومبررًا في مرحلة لاحقة).  
- اعتماد **خرائط** داخل Core الحاسبة.

---

## المراجع الفنية

| الملف |
|-------|
| [`fleet_intelligence_metrics_models.dart`](../lib/features/map/core/fleet_intelligence_metrics_models.dart) |
| [`fleet_intelligence_metrics_config.dart`](../lib/features/map/core/fleet_intelligence_metrics_config.dart) |
| [`fleet_intelligence_metrics_calculator.dart`](../lib/features/map/core/fleet_intelligence_metrics_calculator.dart) |
| اختبار: [`test/features/map/core/fleet_intelligence_metrics_calculator_test.dart`](../test/features/map/core/fleet_intelligence_metrics_calculator_test.dart) |
