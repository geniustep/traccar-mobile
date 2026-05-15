# لوحة ذكاء الأسطول — Fleet Intelligence Dashboard (Phase 10B–10G)

المسار في المستودع: [`docs/fleet_intelligence_dashboard_overview.md`](fleet_intelligence_dashboard_overview.md).

---

## 1. الهدف

عرض **FleetIntelligenceMetrics** لمسؤول ELMOGPS من بيانات مسار الجهاز الموجودة مسبقًا (**`RouteDataSource.getRoute`**), مع **فلاتر زمنية**, **سقف تحميل** بعدد المركبات, **تحديث يدوي**, و**مركز متابعة** للمركبات البارزة دون نقاط طرفية شبكية جديدة.

---

## 2. المسار والتنقل

| العنصر | التفاصيل |
|--------|-----------|
| مسار GoRouter | **`/fleet-intelligence`** في [`lib/app/router.dart`](../lib/app/router.dart) ضمن **`MainShell`** |
| شريط سفلي | يُعامل مثل **`/dashboard`** في **`MainShell._locationToIndex`** |
| بطاقة من الرئيسية | **Quick actions** في [`admin_dashboard_screen.dart`](../lib/features/fleet_intelligence/presentation/screens/admin_dashboard_screen.dart) — التحديث العام يستدعي **`invalidate(fleetIntelligenceMetricsProvider)`** |
| نقرة مركبة في **التصنيف / الترتيب** | **`/vehicles/:id/track`** (تتبّع حي) |
| نقرة مركبة في **مركز المتابعة** | **`showFleetAttentionDetailsSheet`** → ورقة ملخص (**10G**)؛ أزرار اختيارية → **`/vehicles/:id`**, **`/vehicles/:id/track`**, **`/vehicles/:id/trips`** (بدون جلب شبكة عند الفتح). |

---

## 3. المزودات والطبقة البيانية (10C–10F)

| المزود | الملف |
|--------|-------|
| **`fleetDashboardFilterProvider`** | [`fleet_intelligence_metrics_provider.dart`](../lib/features/fleet_intelligence/presentation/providers/fleet_intelligence_metrics_provider.dart) — **`FleetDashboardFilterState`** + **`refreshNonce`** |
| **`fleetIntelligenceQueryProvider`** | نفس الملف — نطاق **محلي** في الواجهة ثم **`toUtc`** للمسار |
| **`fleetIntelligenceMetricsProvider`** | **`FutureProvider` → `FleetIntelligenceDashboardState`** — يستخدم التخزين المؤقت (**10F**) عند الطلب |
| **`fleetIntelligenceDashboardCacheProvider`** | نفس الملف — نسخة **`FleetIntelligenceDashboardCache`** لكل **`ProviderScope`** (حياة التطبيق) |
| تصدير قديم | [`fleet_behavior_metrics_provider.dart`](../lib/features/fleet_intelligence/presentation/providers/fleet_behavior_metrics_provider.dart) يعيد تصدير الملف الجديد |

**محمّل قابل للاختبار:** [`fleet_intelligence_metrics_loader.dart`](../lib/features/fleet_intelligence/application/fleet_intelligence_metrics_loader.dart).

**تخزين مؤقت في الذاكرة:** [`fleet_intelligence_dashboard_cache.dart`](../lib/features/fleet_intelligence/application/fleet_intelligence_dashboard_cache.dart) — **`kFleetIntelligenceDashboardCacheTtl` = 3 دقائق** (ضمن النطاق الموصى به **2–5 دقائق** في هذه الوثيقة؛ المفتاح **`FleetIntelligenceQuery.cacheStableKey`** بدون **`refreshNonce`**؛ كل زيادة في **`refreshNonce`** تفرض تجاوز اللقطة وإعادة **`getRoute`** عند تنفيذ المزود).

**سقف افتراضي:** **`kFleetIntelligenceDefaultMaxVehicles` = 25**.

---

## 4. الفلاتر الزمنية (10D)

- **`FleetDashboardDatePreset`** + **`fleetDashboardLocalBounds`**: [`fleet_dashboard_date_preset.dart`](../lib/features/fleet_intelligence/presentation/fleet_dashboard_date_preset.dart) — اليوم (**00:00 → الآن**), الأمس (**يوم كامل**), آخر سبعة أيام (**من قبل ستة أيام 00:00 → الآن**), مخصّص عبر **`showDateRangePicker`**.

---

## 5. مكوّنات الواجهة

[`fleet_intelligence_dashboard_screen.dart`](../lib/features/fleet_intelligence/presentation/screens/fleet_intelligence_dashboard_screen.dart): Chips → **محوّل الوقت** → **`FleetIntelScoreCard`** → تلميحات جزئية → **`FleetIntelMetricGrid`** → **`FleetIntelRiskDistributionCard`** → **`FleetIntelRankingSection`** → **`FleetAttentionCenterCard`**.

مركز المتابعة: [`fleet_attention_center_card.dart`](../lib/features/fleet_intelligence/presentation/widgets/fleet_attention_center_card.dart) + [`fleet_attention_center_logic.dart`](../lib/features/fleet_intelligence/presentation/utils/fleet_attention_center_logic.dart).

**تفاصيل متابعة (10G):** نقرة بلاطة المركبة في المركز تستدعي [`showFleetAttentionDetailsSheet`](../lib/features/fleet_intelligence/presentation/widgets/fleet_attention_details_sheet.dart) على **`FleetAttentionItem`** الحالي (نفس **`FleetVehicleIntelligenceSummary`** و**`FleetAttentionReason`** دون إعادة **`getRoute`**). تنسيقات العرض: [`fleet_attention_details_formatters.dart`](../lib/features/fleet_intelligence/presentation/utils/fleet_attention_details_formatters.dart)؛ روابط اختيارية: [`fleet_attention_routes.dart`](../lib/features/fleet_intelligence/presentation/widgets/fleet_attention_routes.dart).

---

## 6. الاختبارات

تحت **`test/features/fleet_intelligence/`**: `fleet_intelligence_query_test`, `fleet_dashboard_date_preset_test`, `fleet_intelligence_metrics_loader_test`, `fleet_intelligence_dashboard_cache_test` (**Phase 10F**), `fleet_attention_center_logic_test`, `fleet_attention_details_formatters_test` (**Phase 10G**), إلى جانب **`fleet_intel_score_card_test`** و**`fleet_intelligence_formatters_test`**.

---

## 7. مقترح Phase 11A

عيّينة مركبات أو مجموعات قابلة للترقيم؛ إبطال تلقائي للتخزين المؤقت عند تحديث قائمة المركبات أو العتبات عند الحاجة لمزامنة أدق؛ تخزين دائري (LRU) أو عدة لقطات عند كثرة استعلامات مختلفة في الجلسة؛ تعميق واجهات إدارة الأسطول خارج نطاق هذه اللوحة إن وُجدت خارطة طريق منفصلة.
