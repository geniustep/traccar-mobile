# بنية خرائط ELMOGPS — Map Core والشاشات

وثيقة تقنية مختصرة بعد تحسينات **Phase 1**، **Phase 2A–2C**، **Phase 3A–3D**، **Phase 4A–4B**، **Phase 5A–7E**، و**Phase 8** (تجزئة الرحلات، قائمة الرحلات، خريطة رحلة واحدة، Replay بنطاق رحلة؛ تفاصيل التقسيم: **`docs/trip_segmentation_overview.md`**).  

**Replay (R1–R10) :** ملخص المراحل، QA النهائي، أوامر الاختبار، والقيود — **[`docs/replay_release_notes.md`](replay_release_notes.md)**.  
المسار: `docs/map_screens_overview.md`.

---

## 1. نظرة عامة

نظام الخرائط في ELMOGPS مبني على:

- **Map Core** — طبقة مشتركة في `lib/features/map/core/` (سياسة زوم، ماركرات، مسارات، دمج بيانات حية، رندر جيوفنس للأسطول، إلخ).
- **صفحات متخصصة** — كل شاشة تضيف سياقها فقط (مزودات Riverpod، تخطيط واجهة، تنقل) وتستدعي الـ Core بدل تكرار منطق الرسم.

**مبدأ:** الرسم المعقّد (ماركرات، بوليثينات، حدود جيوفنس، عتبات زوم) يمر عبر **Factory / Builder / Renderer / Policy** وليس بنسخ كود داخل كل شاشة.

---

## 2. الصفحات الأساسية ومساراتها

| الصفحة | ملف تقريبي | مسار / سياق |
|--------|-------------|-------------|
| **LiveMapScreen** | `lib/features/map/presentation/screens/live_map_screen.dart` | `/map` (داخل `MainShell`) |
| **VehicleTrackingScreen** | `lib/features/map/presentation/screens/vehicle_tracking_screen.dart` | `/vehicles/:id/track` |
| **RouteReportMapScreen** | `lib/features/reports/presentation/screens/route_report_map_screen.dart` | `/reports/route-map` (`extra`: `ReportFilterParams` + اسم مركبة) |
| **ReplayReportScreen** | `lib/features/reports/presentation/screens/replay_report_screen.dart` | `/reports/replay` (`extra`: `ReportFilterParams`، اسم مركبة) |
| **MultiVehicleReplayScreen** | `lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart` | `/vehicles/replay-multi` (2–5 مركبات، يوم واحد) — **Phase R7** |
| **TripDetailMapScreen** | `lib/features/reports/presentation/screens/trip_detail_map_screen.dart` | `/vehicles/:id/trip-map` (`extra`: `ReportFilterParams`، `tripSubtitle`) |
| **FleetIntelligenceDashboardScreen** (**Phase 10B–10G**) | `lib/features/fleet_intelligence/presentation/screens/fleet_intelligence_dashboard_screen.dart` | `/fleet-intelligence` (ملخص أسطول؛ **`fleetIntelligenceMetricsProvider`** + فلاتر + **تخزين مؤقت قصير** (TTL افتراضي **3 دقائق**) لنفس **`cacheStableKey`** مع تجاوز عند **`refreshNonce`**؛ **`FleetAttentionCenterCard`**؛ نقرة مركبة في القسم المصنّف → **`VehicleTrackingScreen`**؛ نقرة في **مركز المتابعة** → **`showFleetAttentionDetailsSheet`** ثم أزرار تنقّل اختيارية نحو تفاصيل المركبة أو الخريطة أو الرحلات بدون جلب جديد عند فتح الورقة). |
| **GeofenceMapPicker** | `lib/features/geofences/presentation/widgets/geofence_map_picker.dart` | مدمج في المحرر والتفاصيل (ليس مسارًا مستقلاً) |
| **GeofenceEditorScreen** | `lib/features/geofences/presentation/screens/geofence_editor_screen.dart` | `/geofences/:id/edit` أو إنشاء `new` |
| **GeofenceDetailsScreen** | `lib/features/geofences/presentation/screens/geofence_details_screen.dart` | عرض تفاصيل منطقة + معاينة خريطة唯读 |

---

## 3. دور كل صفحة / مكوّن

| | الدور الوظيفي |
|--|----------------|
| **LiveMapScreen** | **مراقبة الأسطول**: كل المركبات، تجميع عند زوم منخفض، بحث/فلتر، مركبة مختارة، طبقات خفيفة (جيوفنس، تنبيهات، مسار يوم للمختارة فقط). بث **REST + WebSocket**. |
| **VehicleTrackingScreen** | **تتبع وتحليل مركبة واحدة**: موقع حي + مسار في نطاق من/إلى، إحصاءات، متابعة كاميرا، ماركر سيارة ومسار عبر الـ Core؛ **طبقة Route Intelligence** (تحليل خارج البناء + ماركرات عبر `RoutePolylineBuilder.buildRouteIntelligenceMarkers` مع `reportStyle: false`). لوحة أسفل الخريطة تتضمن **Route Event Timeline** و**قائمة الرحلات المجزأة (Phase 8)** أسفل خط زمني الأحداث عند توفر نقاط GPS؛ **لا** استبدال لشاشة التقارير الثقيلة. |
| **RouteReportMapScreen** | **مسار تاريخي من التقارير أو نافذة رحلة واحدة (Phase 8C)** عبر المعاملات الاختيارية: بوليثين ملوّن، ماركرات بداية/نهاية/أقصى سرعة/ساعية حسب الزوم؛ **بدون WebSocket**؛ `RoutePolylineBuilder` + `MapZoomPolicy`؛ ذكاء المسار `reportStyle: true`؛ **Route Event Timeline** + زر Replay اختياري عند **`onOpenReplayShortcut`**. |
| **ReplayReportScreen** | **إعادة تشغيل الرحلة**: بوليثينات ملوّنة (**R1:** مقاطع عند فجوات GPS) + ماركر متحرك + **`ReplaySnapshotPanel` (R2)** + تحكمات إعادة. **Route Intelligence:** Timeline (**§11**) + **`dataGap`**؛ **`ReplayGapsSheet`**. انظر **§12–§13**. |
| **TripDetailMapScreen** | **Phase 8C — خريطة رحلة واحدة:** يضبط نافذة **`ReportFilterParams`** على بداية/نهاية الرحلة (UTC + buffer صغير) ويعيد استخدام **`RouteReportMapScreen`** عبر حقول **`contextualSubtitle`** و **`onOpenReplayShortcut`**؛ نفس **`reportRouteProvider`**، وبوليثينات وTimeline وبطاقة تفاصيل الأحداث؛ **بدون إضافة واجهة برمجية جديدة في هذه المرحلة**. |
| **GeofenceMapPicker** | **رسم وتعديل** شكل المنطقة (دائرة/مضلع) داخل المحرر: نقر لعرض المركز أو إضافة رؤوس، `GeofenceMapRenderer.buildEditorGeometry` + `MapZoomPolicy` (سمك، handles، عنوان عند زوم مناسب). |
| **GeofenceEditorScreen** | نموذج الاسم، اللون، النوع، الربط بالمركبات، التنبيهات؛ يغلّف **`GeofenceMapPicker`** ويمرّر `fitNonce` / `emptyHint`. |
| **GeofenceDetailsScreen** | **معاينة منطقة فقط**: نفس **`GeofenceMapPicker`** بـ `interactive: false` + `mapTitle` + `fitNonce`؛ لا حفظ من الخريطة هنا. |

---

## 4. ملفات Map Core (مسؤوليات)

المجلد الأساسي: `lib/features/map/core/`.

| الملف | المسؤولية |
|-------|-----------|
| **`vehicle_marker_factory.dart`** | ألوان/أشكال ماركرات الأسطول، الدبابيس، التجميع، أيقونة السيارة العلوية من `assets/map/nav_car_top.svg` (bitmap **شمال ثابت** + **`Marker.rotation`** للاتجاه)، كاش للـ Bitmap، ألوان replay حسب السرعة. |
| **`map_zoom_policy.dart`** | قرارات **الزوم الذكي**: تجميع، أيقونة سيارة مقابل دبوس، ماركرات مسار/ساعة، طبقات تنبيه/مسار اليوم، سماكة/عناصر محرر الجيوفنس، تخفيف نقاط المسار. **Route intelligence:** `showRouteStopMarkers` / `showRouteOverspeedMarkers` / `showRouteIgnitionMarkers` (بارام `reportStyle`) و`routeEventStopMarkerBudget` / `routeEventOverspeedMarkerBudget` / `routeEventIgnitionMarkerBudget`. يعتمد على `MapZoomThresholds` في `vehicle_status_thresholds.dart`. |
| **`route_polyline_builder.dart`** | بوليثينات ملوّنة حسب السرعة، ماركرات بداية/نهاية/أقصى سرعة، نقاط ساعية، تخفيف النقاط (`decimateForMapWithMax`)، خيارات مثل `omitRouteEndMarker` / `livePositionForRouteEndDedup` لشاشة التتبع؛ **`buildRouteIntelligenceMarkers`** / **`buildRouteIntelligenceMarkerBundle`** لماركرات التوقف / تجاوز السرعة / الإشعال من نتيجة `RouteEventAnalyzer`، مع **`onMarkerTap`** اختياري (Phase 7B) لربط كل ماركر بـ **`RouteEventTimelineItem`** دون إعادة تحليل. |
| **`route_event_analyzer.dart`** | تحليل **أحداث المسار** من قائمة `RoutePoint` مرتبة: توقفات، تجاوز سرعة، انتقالات إشعال (عند موثوقية البيانات). لا يغيّر المزودات. |
| **`route_event_models.dart`** | نماذج النتائج: `RouteStopEvent`، `RouteOverspeedEvent`، `RouteIgnitionEvent`، `RouteEventSummary`، `RouteEventAnalysisResult`، و`RouteEventAnalysisConfig` (عتبات السرعة والمدة). |
| **`route_event_ui.dart`** | **`formatRouteIntelSummaryLine`**: سطر ملخص واحد للواجهة (تتبع / تقرير) دون تكرار منطق العرض داخل الشاشات. |
| **`route_event_timeline_models.dart`** | دمج **`RouteStopEvent`** / **`RouteOverspeedEvent`** / **`RouteIgnitionEvent`** ضمن قائمة موحدة **`RouteEventTimelineItem`**؛ تعداد **`RouteTimelineEntryKind`**؛ دالة **`buildRouteEventTimelineItems(analysis, l10n)`** لترتيب زمني ونصوص العرض (بدون إعادة استدعاء **`RouteEventAnalyzer`**). **`routeEventTimelineValidPosition`** للتحقق من الإحداثيات قبل التركيز على الخريطة. |
| **`route_intelligence_threshold_resolution.dart`** | Phase 6F: **`RouteIntelligenceThresholdResolution`** / **`RouteIntelligenceThresholdSources`** — نفس أرقام **`RouteIntelligenceThresholds`** المستخدمة اليوم مع **مصادر لكل حقل** للمعاينة والـ Debug لاحقاً؛ الوثائق: **`docs/route_intelligence_thresholds_source.md`** (قسم Threshold Source Trace). |
| **`geofence_map_renderer.dart`** | **`buildShapes`**: دوائر/مضلعات من كيانات جيوفنس للأسطول (مع حد أقصى بعدد حسب الزوم). **`buildEditorGeometry`**: دائرة/مضلع واحد للمحرر مع `strokeWidth` قابل للضبط. |
| **`vehicle_status_resolver.dart`** | تسمية حالة المركبة (moving / idle / stopped / offline / unknown) من السرعة، الإشعال، حداثة الموقع، صلاحية الإحداثيات. |
| **`vehicle_live_merger.dart`** | دمج **كيان مركبة من REST** مع **موقع WebSocket**؛ يطبّق سياسات العمر والإحداثيات الصالحة. |
| **`live_vehicle_mapper.dart`** | نقطة دخول معمارية (تصدير/توثيق) نحو دمج المركبة الحية — التنفيذ الفعلي في **`vehicle_live_merger`**. |
| **`map_camera_follow_controller.dart`** | متابعة الكاميرا للأسطول/مركبة واحدة، تمييز الحركة البرمجية عن سحب المستخدم، خفض ارتجاج التحديثات. |
| **`vehicle_status_thresholds.dart`** | عتبات السرعة، أعمار الموضع، **نطاقات زوم** (`MapZoomThresholds`: نظرة عامة، مدينة، حي، مركبة، جيوفنس محرر، إلخ). **عتبات ماركرات ذكاء المسار:** `routeStopMarkersReportMinZoom` / `routeStopMarkersTrackingMinZoom`، `routeOverspeedMarkersReportMinZoom` / `routeOverspeedMarkersTrackingMinZoom`، `routeIgnitionMarkersReportMinZoom` / `routeIgnitionMarkersTrackingMinZoom`. |
| **`alert_marker_builder.dart`** | دبابيس تنبيهات مهمة غير مقروءة على خريطة الأسطول. |
| **`trip_segment_models.dart`** | **Phase 8A:** **`TripSegmentationConfig`**، **`TripSegment`**. عتبات التقسيم منفصلة عن **`RouteIntelligenceThresholds`** (التي تمرّ إلى **`RouteEventAnalyzer`** فقط). |
| **`trip_segmenter.dart`** | **Phase 8A:** **`TripSegmenter.build`** — نقاط مرتبة → رحلات؛ لكل رحلة **`RouteEventAnalyzer.analyze(subset)`** + **`enrichRouteIntelStopsFromRoutePoints`**. |
| **`trip_segment_summary.dart`** | مسافة المسار (Haversine)، متوسط السرعة المركّبة، **`reportFilterParamsForTrip`** لتوحيد **`ReportFilterParams.from/to`** (UTC) مع buffer. |
| **`daily_behavior_score_models.dart`** / **`daily_behavior_score_calculator.dart`** (**Phase 9D**) | تجميع **فترة للمركبة** من قائمة **`TripSegment`**: **`DailyVehicleBehaviorScore`** (متوسط وزني عبر الرحلات القابلة للتقييم فقط، أرقام إجمالية لكل الرحلات)؛ لا واجهات في هذه المرحلة؛ الوثائق: **`docs/driver_behavior_score_overview.md`** §12. |
| **`fleet_intelligence_metrics_models.dart`** / **`fleet_intelligence_metrics_config.dart`** / **`fleet_intelligence_metrics_calculator.dart`** (**Phase 10A**) | تجميع **أسطول**: **`FleetIntelligenceMetrics`** من قائمة **`FleetVehicleTripInput`** (مركبة + رحلات مجمّعة مسبقًا)؛ لا واجهات ولا شبكة في هذه المرحلة؛ الوثائق: **`docs/fleet_intelligence_metrics_overview.md`**. |
| **`driver_behavior_score_models.dart`** / **`driver_behavior_score_config.dart`** / **`driver_behavior_score_calculator.dart`** (**Phase 9A**) | نواة تقدير **نقاط سلوك على مستوى الرحلة**: درجة \[0،100\]، مستوى خطر، تفاصيل عقوبات، عوامل بـ **`code`** فقط (بدون `l10n` في الـ Core)؛ الوثائق: **`docs/driver_behavior_score_overview.md`**. |
| **ملحقات** | `vehicle_marker_style.dart` (أنماط enum)، وربط المزودات في `map_provider.dart` / `tracking_provider.dart`. |

أدوات عامة خارج `core` لكن مكملة:

- **`lib/core/maps/map_helper.dart`**: `fitPoints`، `routeColorForSpeed`، `buildGeofenceCircle` / `buildGeofencePolygon` (باراميتر `strokeWidth`).
- **`lib/features/map/presentation/widgets/trips_list.dart`**: قائمة بطاقات **الرحلات** (Phase 8B + **9B**)، سطر **التقييم** خفيف (`TripBehaviorScoreBadge` + `driverScore*` l10n)، حالة فارغة مترجمة، روابط لفتح **`TripDetailMapScreen`** أو **`ReplayReportScreen`**.
- **`lib/features/map/presentation/widgets/trip_behavior_score_badge.dart`**: سطر عرض موجز + ضغط لفتح تفاصيل **9C**.
- **`lib/features/map/presentation/widgets/trip_behavior_score_details_sheet.dart`**: **Phase 9C** — ورقة سفلية لشرح التقييم والعقوبات والعوامل (بدون أكواد خام).
- **`lib/features/map/presentation/utils/daily_behavior_score_formatters.dart`**: **`DailyBehaviorScoreUi`** — سطور عرض ملخص **تقييم الفترة** (**Phase 9E**) باستخدام **`dailyScore*`** و **`driverScore*`**.
- **`lib/features/map/presentation/widgets/daily_vehicle_behavior_score_card.dart`**: بطاقة **Score de conduite** أعلى **`TripsListSection`** في **`VehicleTrackingScreen`**؛ الضغط يفتح **Phase 9F** (**`daily_behavior_score_details_sheet.dart`**).
- **`lib/features/map/presentation/widgets/daily_behavior_score_details_sheet.dart`**: ورقة **`DailyBehaviorScoreDetailsSheet`** — تفاصيل تقييم **الفترة** (**Phase 9F**)، صفوف label/value بدون أكواد خام.
- **`lib/features/map/presentation/utils/trip_formatters.dart`**: تنسيق عنوان الرحلة، المدّة، أسطر العرض لمفاتيح l10n.
- **`lib/features/map/presentation/widgets/route_event_timeline.dart`**: ويدجت **`RouteEventTimeline`** — قائمة تفاعلية للأحداث (حد أولي للعناصر، زر توسيع/طي بنص ترجمات *Voir plus* / *Voir moins*)، قائمة **`ListView.builder`** بارتفاع ثابت، تمرير فقط؛ يقرأ **`RouteEventAnalysisResult?`** ومفتاح **`analysisKey`** لإبقاء تجميع الصفوف خفيفاً عند ثبات الدفعة.
- **`lib/features/map/presentation/widgets/route_intelligence_thresholds_preview.dart`** (**Phase 6G**): **`RouteIntelligenceThresholdsPreview`** / **`RouteIntelligenceVehicleThresholdPreview`** / **`RouteIntelligenceGlobalThresholdPreview`** — بطاقة **عرض فقط** للعتبات الفعلية ولمصدر كل حقل؛ مدمجة من **`VehicleDetailScreen`** و**`SettingsScreen`** (انظر **`docs/route_intelligence_thresholds_source.md`**).
- **`lib/features/map/presentation/widgets/route_intelligence_vehicle_central_threshold_editor.dart`** (**Phase 6K**): **`RouteIntelligenceVehicleCentralThresholdSection`** — أزرار تعديل/إعادة ضبط **عتبات تحليل المسار على المركبة فقط** في التكوين المركزي (ELMOGPS)؛ **لا** يغيّر الإعدادات المحلية؛ الصلاحيات: غير `readonly` و`UserRole` ليس viewer؛ مدمج أسفل المعاينة في **`VehicleDetailScreen`**.
- **`lib/features/map/presentation/widgets/route_intelligence_thresholds_editor.dart`** (**Phase 6H**): **`RouteIntelligenceLocalThresholdsEditor`** — تعديل **محلي فقط** (SharedPreferences) للطبقة `local` في السياق العام؛ في **`SettingsScreen`** أسفل المعاينة العالمية؛ **بدون** كتابة Traccar.

## 5. سلوك Smart Zoom (مختصر)

القيم الدقيقة تُعرَّف في **`MapZoomThresholds`** و **`MapZoomPolicy`** — لا تُكرَّر عشوائياً في الشاشات.

| السلوك | متى؟ |
|--------|------|
| **SVG car (أعلى السيارة)** | أسطول: زوم عالٍ وللغير مختار وفق `useTopDownForFleetVehicle` (عتبة ~15 وحد أقصى للمركبات الظاهرة). المختار: سيارة SVG مع تكبير نسبي. تتبع: سيارة SVG مع **`rotation = course`**. |
| **دبوس / cluster** | زوم منخفض: تجميع؛ زوم متوسط: دبابيس **`VehicleMarkerFactory`**؛ زوم عالٍ: مركبات فردية و/أو SVG حسب السياسة. |
| **ماركرات مسار** (بداية، نهاية، أقصى سرعة) | عبر **`RoutePolylineBuilder`**؛ إخفاء ماركر **نهاية** مسار اليوم عند التتبع الحي إذا كانت `_isToday` أو تقارب آخر نقطة مع الموضع الحي (لتفادي التراكب مع ماركر السيارة). |
| **Hourly markers** | `MapZoomPolicy.showRouteHourlyMarkers()` (عتبة زوم ~13). |
| **Geofence على الأسطول** | عدد أشكال محدود بـ `geofenceCap(zoom)`؛ سماكة ثابتة افتراضياً من `MapHelper` (محرر يستخدم سياسة منفصلة). |
| **Geofence handles (مركز/رؤوس)** | في **`GeofenceMapPicker`**: `showGeofenceEditorCircleCenterPin` و `showGeofenceEditorVertexHandles` عند زوم ≥ **~12**. |
| **Map title (اسم المنطقة)** | في المحرر/التفاصيل: `showGeofenceEditorMapTitle` عند زوم ≥ **~14.5** (ماركر مع `InfoWindow`). |
| **Route intelligence على Replay** | **`ReplayReportScreen`** يستعمل **`MapZoomPolicy`** (بنمط تقرير: `reportStyle: true`) لقرار إظهار ماركرات **التوقف** و**تجاوز السرعة** و**الإشعال** عبر `showRouteStopMarkers` / `showRouteOverspeedMarkers` / `showRouteIgnitionMarkers`، ولتطبيق **ميزانيات العدد** `routeEventStopMarkerBudget` / `routeEventOverspeedMarkerBudget` / `routeEventIgnitionMarkerBudget` — **بدون** إعادة تحليل المسار عند تغيّر الزوم. |

### أداء ReplayReportScreen (مع ذكاء المسار)

- **تحليل واحد لكل trace:** تُحلَّل القائمة **الكاملة** من `RoutePoint` (نفس دفعة التقرير) **مرة واحدة** عند تغيّر المسار، وليس نقاط العيّنة الخاصة بمحرّك الإعادة فقط.
- **بدون تحليل في كل tick:** لا يُعاد استدعاء `RouteEventAnalyzer` أثناء خطوات الإعادة؛ يحدَّث موضع/دوران **ماركر المركبة** فقط.
- **تخزين مؤقت للتحليل:** مفتاح من نوع **length + firstFix + lastFix** (طول القائمة وزمن أول وآخر نقطة) يمنع إعادة التحليل بلا داعٍ.
- **ماركرات الذكاء ثابتة قدر الإمكان:** تُبنى من نتيجة التحليل المخزَّنة؛ يُعاد بناء مجموعة ماركرات الذكاء عند تغيّر **مستوى الزوم** (وليس عند كل إطار إعادة).

---

## 6. قاعدة معمارية

**لا يُفترض** بناء **`BitmapDescriptor`** معقّد، أو توليد **polyline** ملوّن يدوياً، أو هندسة **Circle/Polygon** للجيوفنس **داخل الشاشة** إذا وُجد:

- **`VehicleMarkerFactory`** للماركرات،
- **`RoutePolylineBuilder`** للمسارات والماركرات المرتبطة (بما فيها **ذكاء المسار** عبر `buildRouteIntelligenceMarkers`)،
- **`GeofenceMapRenderer`** للجيوفنس (أسطول أو محرر)،
- **`MapZoomPolicy`** لقرارات الزوم والتفصيل،
- **`RouteEventAnalyzer`** لاستخراج أحداث المسار — **لا** يُطبَّع تكرار منطق التوقف/التجاوز/الإشعال داخل الشاشات.
- **`buildRouteEventTimelineItems`** + **`RouteEventTimeline`** لعرض خط زمني موحّد في الشاشات (انظر §11) — **لا** تكرار صفوف مخصّصة داخل كل شاشة.

الشاشة تمرّر البيانات والمزودات وتستدعي هذه الطبقة. يُستحسن **تخزين مؤقت** لنتيجة التحليل عند تغيّر قائمة النقاط (مفتاح طول/زمن أول وآخر نقطة) وليس إعادة التحليل في كل `build` بدون داعٍ.

---

## 7. Do / Don't

### Do

- استخدم **`VehicleMarkerFactory`** لأيقونات المركبات (أسطول، تتبع، replay، تجميع).
- استخدم **`RoutePolylineBuilder`** لمسارات ملوّنة ولماركرات البداية/النهاية/أقصى سرعة/الساعات، ولـ **`buildRouteIntelligenceMarkers`** عند عرض أحداث المسار.
- استخدم **`RouteEventAnalyzer.analyze`** ثم مرّر النتيجة إلى الـ Builder؛ استخدم **`route_event_ui`** لسطور الملخص إن لزم.
- استخدم **`buildRouteEventTimelineItems`** و **`RouteEventTimeline`** لقوائم أحداث المسار الزمنية (§11)، مع تمرير نفس **`RouteEventAnalysisResult`** المخزّن مسبقاً.
- استخدم **`MapZoomPolicy`** (و`MapZoomThresholds`) لأي منطق «نعرض التفاصيل من مستوى زوم كذا».
- استخدم **`GeofenceMapRenderer.buildShapes`** لطبقة الجيوفنس على الخريطة الحية، و **`buildEditorGeometry`** في المحرر.
- احتفظ بأي **اتجاه مركبة** عبر **`Marker.rotation`** مع bitmap **بدون** دمج دوران الـ course داخل الصورة (كاش أقل وأداء أفضل).

### Don't

- لا تبنِ **`BitmapDescriptor`** مخصّصاً داخل الشاشة إلا لسبب نادر وموثّق.
- لا تكرر `buildPolylines` يدوياً (حلقة `Polyline` + `routeColorForSpeed`) في شاشة جديدة.
- لا تنسخ عتبات الزوم كأرقام سحرية — وسّع **`MapZoomThresholds` / `MapZoomPolicy`**.
- لا تولد bitmap جديداً لكل **course** — استخدم دوران الماركر.
- لا تُحمّل **`LiveMapScreen`** بتحليلات ثقيلة أو مسارات كاملة لكل مركبة؛ ذلك لـ **`VehicleTrackingScreen`** / التقارير.

---

## 8. Future Phases (اقتراحات — غير منفّذة افتراضياً)

- سحب وتعديل **رؤوس المضلع** (draggable vertices) في المحرر.
- **خريطة تنبيهات** مستقلة أو طبقة موسّعة.
- **Trip segmentation** (Phase 8) — تجزئة المسار اليومي أو في نطاق من/إلى إلى **رحلات** عبر `TripSegmenter`، عرضها من `VehicleTrackingScreen`، وتفاصيل رحلة واحدة عبر `TripDetailMapScreen` + `ReplayReportScreen` (المسار: **`docs/trip_segmentation_overview.md`**).

**Future Work — ذكاء المسار والتقارير (ما بعد Phase 4A):**

- **InfoWindow أو تفاصيل فورية** عند الضغط على صفّ في **Route Event Timeline** (**حاليّاً**: تركيز الكاميرا فقط على موقع الحدث).
- **عناوين التوقفات** (geocoding اختياري لـ `RouteStopEvent.address`، يظهر عنوان التوقف في الـ Timeline عند ملء الحقل).
- **اختبار يدوي على الأجهزة** لسيناريوهات Replay وTimeline وعدد كبير من الأحداث.
- **تحسين لوحة Replay للشاشات الصغيرة** (ارتفاع اللوحة، التمرير مع مخطط السرعة والـ Timeline).
- **عتبات تحليل قابلة للإعداد من الإعدادات** (مثلاً تجاوز السرعة ومدى التوقف بما يتعدّى الثوابت في `RouteEventAnalysisConfig` وحده).
- **مؤشر سلوك السائق** أو درجة مرتبطة بالأحداث.
- **تصدير الأحداث** ضمن التقارير (CSV/PDF/API).

---

## 9. مراجع سريعة للمسارات

```
/map                          → LiveMapScreen (أسطول)
/vehicles/:id/track           → VehicleTrackingScreen
/vehicles/:id/trip-map        → TripDetailMapScreen (Phase 8؛ extra: params + tripSubtitle)
/reports/route-map            → RouteReportMapScreen
/reports/replay               → ReplayReportScreen
/geofences/:id/edit           → GeofenceEditorScreen (+ GeofenceMapPicker)
(شاشة تفاصيل جيوفنس)         → GeofenceDetailsScreen (+ GeofenceMapPicker معاينة)
```

**بث مباشر (WebSocket):** `/map`، `/vehicles/.../track`.  
**بدون بث حي للمسار التاريخي:** `/reports/route-map`، `/reports/replay`.

---

## 10. طبقة ذكاء المسار — Route Intelligence (Phase 3A / توثيق 3B / Replay 3C)

طبقة **Route Intelligence** تحوّل نقاط المسار (`RoutePoint`) من رسم بوليثين فقط إلى **أحداث قابلة للعرض والتلخيص**، مع احترام **تخفيف النقاط** الموجود (`decimateForMapWithMax`) على البوليثين حيث ينطبق؛ **تحليل الأحداث** يُنفَّذ على قائمة النقاط **الكاملة** (أو نفس الدفعة التي تُغذي التحليل في الشاشة) وليس على كل إطار رسم.

**الشاشات التي تستخدم الطبقة حالياً:** **`VehicleTrackingScreen`**، **`RouteReportMapScreen`**، و**`ReplayReportScreen`** (مع `reportStyle: false` للتتبع و`reportStyle: true` لتقارير المسار وReplay).

### 10.1 الملفات المرجعية

| الملف | الدور |
|-------|--------|
| **`lib/features/map/core/route_event_analyzer.dart`** | `RouteEventAnalyzer.analyze` — استخراج التوقفات، تجاوزات السرعة، انتقالات الإشعال. |
| **`lib/features/map/core/route_event_models.dart`** | النماذج والإعداد `RouteEventAnalysisConfig` (عتبات الدخول/الخروج للتوقف، أدنى مدة، عتبة التجاوز). |
| **`lib/features/map/core/route_event_ui.dart`** | `formatRouteIntelSummaryLine` لسطر ملخص UI موحّد. |
| **`RoutePolylineBuilder.buildRouteIntelligenceMarkers`** | إنشاء مجموعة `Marker` للتوقف / التجاوز / الإشعال من `RouteEventAnalysisResult?` + `MapZoomPolicy` + `reportStyle` + `vehicleId`. |
| **`MapZoomPolicy`** | `showRouteStopMarkers` / `showRouteOverspeedMarkers` / `showRouteIgnitionMarkers` وحدود العدد `routeEvent*MarkerBudget`. |
| **`MapZoomThresholds` في `vehicle_status_thresholds.dart`** | أدنى زوم لظهور كل نوع ماركر (فرق بين **تقرير** و**تتبع**). |
| **`route_event_timeline_models.dart`**، **`presentation/widgets/route_event_timeline.dart`** | طبقة **Route Event Timeline** — تجميع وزمن؛ انظر §11. |

### 10.2 مخرجات `RouteEventAnalyzer`

- **Stop events** (`RouteStopEvent`): فترة توقف بـ `startTime`، `endTime`، `duration`، `latitude` / `longitude`، و`address` اختياري (غير مملوء تلقائياً حالياً).
- **Overspeed events** (`RouteOverspeedEvent`): لحظة **أقصى سرعة** داخل **نطاق متصل** فوق العتبة، مع `time`، `speed`، الإحداثيات.
- **Ignition events** (`RouteIgnitionEvent`): فقط عندما تُعتبر بيانات `RoutePoint.ignition` **موثوقة** (انظر 10.5) — انتقالات تشغيل/إطفاء بين نقطتين متتاليتين.

يُجمَّع ذلك في **`RouteEventAnalysisResult`** مع **`RouteEventSummary`** (عدد التوقفات، مجموع مدة التوقف، عدد التجاوزات، أقصى سرعة في المسار، عدد انتقالات الإشعال) وعلَم **`ignitionDataLikelyPresent`**.

### 10.3 منطق التوقفات (Stops)

- **دخول توقف:** السرعة أقل من **عتبة الدخول** (افتراض `RouteEventAnalysisConfig`: **أقل من 3 km/h**).
- **خروج من توقف:** السرعة أعلى من **عتبة الخروج** (هستيرesis، افتراض **أعلى من 5 km/h**).
- **أدنى مدة:** الحدث يُسجَّل فقط إذا مدة الفترة ≥ **4 دقائق** (قابلة عبر `RouteEventAnalysisConfig.minStopDuration`).
- **موقع التوقف على الخريطة:** نقطة **وسطى بالمؤشرات** بين بداية ونهاية فترة التوقف (ليست بالضرورة أول/آخر نقطة).

### 10.4 منطق تجاوز السرعة (Overspeed)

- يُفحص المسار كسلسلة **نطاقات متصلة** حيث السرعة **تجاوزت العتبة** (افتراض **`RouteEventAnalysisConfig`: 80 km/h**).
- لكل نطاق متصل يُنشأ **حدث واحد** عند اللحظة التي تحقق فيها **السرعة القصوى (peak)** ضمن ذلك النطاق.

### 10.5 منطق الإشعال (Ignition)

- المصدر: حقل **`RoutePoint.ignition`** (من سمات Traccar عند التوفر).
- **لا يُعرض** ماركر إشعال ولا يُذكَر في الملخص كنقاط إشعال إذا وُصفت السلسلة بأنها **غير موثوقة**: حالة شائعة عندما تكون كل القيم `false` و**لا توجد** أي انتقال ON/OFF (غالباً عدم إرسال السمة من الخادم).
- عند توفر انتقالات حقيقية، تُسجَّل أحداث **تشغيل/إطفاء** بين نقطتين متتابعتين.

### 10.6 الظهور على الخريطة حسب الشاشة

- **`VehicleTrackingScreen`:** بعد التحليل المخزَّن مؤقتاً، دمج `...RoutePolylineBuilder.buildRouteIntelligenceMarkers(..., reportStyle: false, ...)` مع ماركرات المسار الأخرى؛ سطر ملخص خفيف أسفل إحصاءات المسار عند وجود أحداث (عبر `formatRouteIntelSummaryLine`)؛ و**Timeline** أسفله عند وجود ≥ نقطتي مسار (**§11**).
- **`RouteReportMapScreen`:** نفس الماركرات مع `reportStyle: true`؛ سطر ملخص في اللوحة السفلية عند وجود أحداث؛ **Timeline** ضمن اللوحة عند ≥ نقطتي مسار (**§11**).
- **`ReplayReportScreen`:** نفس المسار المعماري: `RouteEventAnalyzer` + `buildRouteIntelligenceMarkers(..., reportStyle: true)` فوق مسار الإعادة الثابت؛ ماركر SVG للمركبة يبقى فوق الطبقة (`zIndex` أعلى). التحكّم بالكثافة عبر **`MapZoomPolicy`** و`onCameraIdle` / `getZoomLevel` مماثل لتقرير المسار، **بدون** إعادة تحليل عند كل tick (انظر §5 جدول «Route intelligence على Replay» وقسم «أداء ReplayReportScreen»). تعرض أيضاً قائمة زمنية للأحداث (**§11**).

### 10.7 التحكم بالزوم وميزانية الماركرات (Marker budgets)

القيم الدنيا للزوم تُعرَّف في **`MapZoomThresholds`** (مثلاً تقرير مقابل تتبع):

- **Stops:** `routeStopMarkersReportMinZoom` (**13**) مقابل `routeStopMarkersTrackingMinZoom` (**14**).
- **Overspeed:** `routeOverspeedMarkersReportMinZoom` (**13.5**) مقابل `routeOverspeedMarkersTrackingMinZoom` (**14.5**).
- **Ignition:** `routeIgnitionMarkersReportMinZoom` (**14**) مقابل `routeIgnitionMarkersTrackingMinZoom` (**15**).

**`ReplayReportScreen`** يعتمد **فرع التقرير** (`reportStyle: true`) لعتبات وميزانيات ماركرات الذكاء — مثل **`RouteReportMapScreen`** — حتى تبقى كثافة التفاصيل متسقة مع خرائط التقارير.

حتى عند تجاوز عتبة الظهور، **`MapZoomPolicy`** يحدّ **أقصى عدد ماركرات** لكل نوع (`routeEventStopMarkerBudget`، `routeEventOverspeedMarkerBudget`، `routeEventIgnitionMarkerBudget`) بحيث تُفضَّل أطول التوقفات أو تُقص ماركرات التجاوز عند زوم متوسط — يقل الازدحام على الخريطة.

### 10.8 قاعدة معمارية (تلخيص)

| يجب | يمنع |
|-----|------|
| استدعاء **`RouteEventAnalyzer.analyze`** لاستخراج الأحداث | تنفيذ منطق التوقف/التجاوز/الإشعال يدوياً داخل الشاشة |
| استدعاء **`RoutePolylineBuilder.buildRouteIntelligenceMarkers`** لرسم ماركرات الذكاء | إنشاء `Marker` مخصّص لكل حدث داخل الشاشة (تكرار وصعبة الصيانة) |
| الاعتماد على **`MapZoomPolicy`** لإظهار/إخفاء والحدّ من العدد | رسم كل أحداث دون تقييد عند زوم منخفض |

---

## 11. Route Event Timeline (Phase 4A) ولوحة التفاصيل (Phase 7A)

خط زمني **واضح ومشترك** للأحداث المستخرجة مسبقاً من **`RouteEventAnalyzer`**؛ يكمِّل ماركرات الخريطة ولا يستبدلها. **Phase 7A** تضيف عند الضغط على صف زمني **bottom sheet** خفيفاً يعيد استخدام **`RouteEventTimelineItem`** (ومعرّف **`buildRouteEventSheetPresentation`**) دون إعادة تحليل.

### 11.1 الملفات والواجهة

| المكون | الوصف |
|--------|--------|
| **`lib/features/map/core/route_event_timeline_models.dart`** | **`RouteEventTimelineItem`** + **`RouteTimelineEntryKind`**؛ حقول Phase 7A للورقة (**`stopStartTime`** / **`stopEndTime`** / **`stopAddress`** / **`overspeedMaxSpeedKmh`**). **`routeEventTimelineItemForStop`** / **`ForOverspeed`** / **`ForIgnition`** (Phase 7B): صف واحد بنفس منطق **`buildRouteEventTimelineItems`** للربط بماركرات الخريطة. **`buildRouteEventTimelineItems`**: دمج وترتيب زمني؛ **`address`** يُعرض عند توفره من التكوين المركزي. |
| **`lib/features/map/presentation/widgets/route_event_timeline.dart`** | **`RouteEventTimeline`** — عنوان قسم مستند إلى الترجمة؛ قائمة بتمرير داخل ارتفاع ثابت؛ زر لتوسيع/طي عدد الصفوف (نصّه في l10n: *Voir plus* / *Voir moins* وفق اللغة). |
| **`lib/features/map/core/route_event_timeline_sheet_details.dart`** | **Phase 7A:** **`buildRouteEventSheetPresentation(item, l10n)`** — نصوص منظّمة للوحة التفاصيل من **`RouteEventTimelineItem`** فقط (اختبارات خفيفة). |
| **`lib/features/map/presentation/widgets/route_event_details_sheet.dart`** | **Phase 7A:** **`RouteEventDetailsSheet.show`** — `showModalBottomSheet` خفيف؛ زر **إعادة التمركز** على الخريطة فقط عندما تكون الإحداثيات صالحة؛ **بدون** خريطة داخل الورقة. |

### 11.2 الدمج حسب الشاشة

| الشاشة | مكان الواجهة | عند الضغط على حدث |
|--------|----------------|---------------------|
| **`VehicleTrackingScreen`** | لوحة المعلومات السفلى، ضمن **`_RouteStatsSection`** أسفل سطر الذكاء. | **Timeline (7A):** **`animateCamera`** + إيقاف **follow**؛ **`RouteEventDetailsSheet`**. **ماركر ذكاء المسار (7B):** نفس الورقة عبر **`onMarkerTap`**؛ **لا** يُفعّل follow تلقائياً عند النقر على الماركر فقط؛ **`onRecenter`** يستدعي **`_animateCameraToRouteEvent`** (ويعطل follow كالسابق). |
| **`RouteReportMapScreen`** | اللوحة السفلى **`_BottomPanel`**، تحت الإحصاءات والملخص. | **Timeline:** **`animateCamera`** + **`RouteEventDetailsSheet`**. **ماركر ذكاء المسار (7B):** **`RouteEventDetailsSheet`** مع **`onRecenter`** يحرّك الكاميرا. |
| **`ReplayReportScreen`** | داخل **`_ReplayControls`** (مع **`RepaintBoundary`** حول الـ Timeline)، عند **`allPoints.length >= 2`**. | **Timeline:** **`seekTo`** + **`animateCamera`** + **`_followVehicle = false`** + ورقة بعد **`addPostFrameCallback`**. **ماركر ذكاء المسار (7B):** ورقة فقط (**لا** **`seekTo`** ولا إيقاف تشغيل)؛ **`onRecenter`** يعطّل **`_followVehicle`** ثم **`animateCamera`**. |

### 11.3 أداء وسلوك التحميل

- **لا إعادة لـ `RouteEventAnalyzer`:** الـ Timeline يستهلك **`RouteEventAnalysisResult?`** الذي تبنيه الشاشة أصلاً (نفس **`analysisKey`** المذكورة في الوثائق السابقة).
- **لا إعادة تجميع ثقيلة في كل إطار:** الويدجت يحتفظ بصفوف مشتقة عند ثبات **`analysisKey`** ومرجع التحليل (مع لغة العرض)، ويستخدم **`ListView.builder`** وحدّاً علوياً لعدد العناصر الظاهر قبل التوسعة.
- **قائمة أولى محدودة:** وضع **تتبع** أكثر تشدداً؛ **تقرير** و Replay يستعملون حدوداً أعلى أو ارتفاعاً أصغر؛ أزرار **مزيد / أقل** بدل تحميل مئات الصفوف دفعة واحدة.
- **Phase 7A — تفاصيل الحدث:** لا تُستدعى **`RouteEventAnalyzer`** من الورقة؛ المحتوى من **`RouteEventTimelineItem`** + ترجمة. فتح الورقة **عند اختيار المستخدم فقط** (ليس عند كل `build`). في **Replay** يُفتح الورقة بعد **`addPostFrameCallback`** وليس داخل مسار **`setState`** الثقيل للخريطة.

### 11.4 Phase 7A — Route Event Details Sheet

- **الملفات:** **`route_event_timeline_sheet_details.dart`** (منطق العرض)، **`route_event_details_sheet.dart`** ( الواجهة ).
- **المدخلات:** **`RouteEventTimelineItem`** (بما في ذلك الحقول الاختيارية التي يملؤها **`buildRouteEventTimelineItems`**).
- **الشاشات:** **`VehicleTrackingScreen`**, **`RouteReportMapScreen`**, **`ReplayReportScreen`** — نفس سلوك التركيز السابق + ورقة من **`showModalBottomSheet`**.
- **زر إعادة التمركز:** يظهر فقط عندما **`routeEventTimelineValidPosition(position)`**؛ ينفّذ نفس **`animateCamera`** دون إغلاق الورقة إلزامياً.

### 11.5 Phase 7B — نقر ماركر ذكاء المسار

- **الربط:** عند بناء الماركرات داخل **`RoutePolylineBuilder.buildRouteIntelligenceMarkerBundle`**، يُنشأ **`RouteEventTimelineItem`** لكل ماركر عبر **`routeEventTimelineItemForStop`** / **`routeEventTimelineItemForOverspeed`** / **`routeEventTimelineItemForIgnition`** (نفس منطق **`buildRouteEventTimelineItems`**).
- **`Marker.onTap`:** يستدعي **`RouteEventDetailsSheet.show`** من الشاشة (تمرير **`onMarkerTap`** إلى **`buildRouteIntelligenceMarkers`**). **`consumeTapEvents: true`** عند وجود **`onMarkerTap`** حتى يُستقبل النقر.
- **الشاشات:** **`VehicleTrackingScreen`**, **`RouteReportMapScreen`**, **`ReplayReportScreen`**.
- **Replay:** نقر الماركر **لا** يستدعي **`seekTo`** ولا يوقف التشغيل؛ زر **إعادة التمركز** داخل الورقة يعطّل متابعة المركبة (`_followVehicle = false`) ثم يحرّك الكاميرا حتى لا تُسحب فوراً أثناء الإعادة.
- **بدون تغيير:** **`RouteEventAnalyzer`**، العتبات، أو ترتيب **`zIndex`** (ماركر المركبة يبقى فوق طبقة أحداث المسار).

### 11.6 Phase 7C — اختيار حدث نشط (Timeline + ماركر)

- **المفتاح المشترك:** **`RouteEventTimelineItem.selectionKey`** (مُولَّد عبر **`routeEventTimelineSelectionKey`**) يطابق منطق التعريف نفسه في **`buildRouteIntelligenceMarkerBundle`** بحيث يمكن ربط صفّ زمني بماركر دون الاعتماد على نصوص العناوين.
- **الواجهة:** **`RouteEventTimeline.selectedItemKey`** يميّز الصف الظاهر بإطار خفيف؛ **`buildRouteIntelligenceMarkers`** / **`buildRouteIntelligenceMarkerBundle`** يستقبلان **`selectedEventKey`** لتعديل لون/ارتفاع طبقة بعض الماركرات للحدث المختار (دون إثقال واجهة إضافية).
- **الشاشات:** **`VehicleTrackingScreen`**, **`RouteReportMapScreen`**, **`ReplayReportScreen`** تحتفظ بحقل **`_selectedRouteEventKey`** (أو ما يعادله)، تُصفّره عند تغيّر مفتاح تحليل المسار/العتبات (نفس نقطة **`_sync*Intel`**)، وتُحدّثه عند **`onItemTap`** على الـ Timeline أو **`onMarkerTap`** على ماركر الذكاء.
- **Replay:** نقر الماركر **لا** يُشغّل **`seekTo`**؛ يقتصر على الورقة + تمييز الاختيار كما سبق.

### 11.7 Phase 7D — عنوان التوقف (عكس الترميز الجغرافي الخفيف)

- **نطاق:** **أحداث التوقف فقط** — لا عنوان لكل **`RoutePoint`** ولا لكل أحداث التجاوز/الإشعال في هذه المرحلة.
- **أولوية المصدر:** (1) **`RouteStopEvent.address`** أو أي **`RoutePoint.address`** داخل نافذة زمنية التوقف (حقل **`address`** في استجابة نقاط المسار من الخادم إن وُجد)؛ (2) ثم **`StopReverseGeocoder`** عبر **`RouteStopAddressResolver`** مع **ذاكرة تخزين مؤقت** بمفتاح إحداثيات مقرّبة إلى 5 منازل عشرية (**`routeStopAddressCacheKey`**).
- **التجميل بدون تغيير المحلل:** بعد **`RouteEventAnalyzer.analyze`** تستدعي الشاشات **`enrichRouteIntelStopsFromRoutePoints`** لدمج عناوين النقاط في **`RouteStopEvent`**؛ **`RouteEventAnalyzer`** نفسه لم يُبدَّل.
- **عدم الحظر:** **`prefetchStopAddressesSequential`** يحدّ ثم 20 توقفاً بلا عنوان لكل دفعة، ويُحدّث واجهة المستخدم تدريجياً عبر **`setState`**؛ الورقة **`RouteEventDetailsSheet`** تطلب حلاً إضافياً عند الحاجة عبر **`resolver`** الاختياري.
- **الربط الافتراضي:** **`stopReverseGeocoderProvider`** → **`NoOpStopReverseGeocoder`** (لا اتصال خارجي، لا مفاتيح API)؛ استبدال المزوّد عند ربط خادم أو SDK لاحقاً.
- **الشاشات:** التتبع، تقرير المسار، و Replay (مع إعادة بناء ماركرات الذكاء عند تحديث العناوين في Replay).

### 11.8 Phase 7E — فلترة أحداث المسار في الـ Timeline

- **نطاق:** واجهة **`RouteEventTimeline` فقط** — لا إعادة استدعاء **`RouteEventAnalyzer`** ولا تغيير عتبات أو ماركرات الخريطة في هذه المرحلة.
- **القيم:** **`RouteEventTimelineFilter`**: الكل، التوقفات، تجاوز السرعة، الإشعال (ON/OFF معاً).
- **التحكم:** كل شاشة (`VehicleTrackingScreen`, `RouteReportMapScreen`, `ReplayReportScreen`) تحتفظ بحالة الفلتر المحلية؛ تُعاد إلى «الكل» عند تغيّر مفتاح تحليل المسار (نفس دورة **`_sync*Intel`**). صف **`FilterChip`** أفقي خفيف مع أعداد لكل فئة.
- **الاختيار النشط (Phase 7C):** إذا كان **`selectedItemKey`** يشير إلى حدث غير ظاهر تحت الفلتر الحالي، لا يظهر تمييز في القائمة؛ يبقى المفتاح كما هو حتى يعود المستخدم إلى «الكل» أو يغيّر الفلتر.
- **`routeEventTimelineItemMatchesFilter`** / **`routeEventTimelineItemsFiltered`**: منطق الفلترة في **`route_event_timeline_models.dart`**.

---

## 12. Configurable Route Intelligence Thresholds (Phase 5A)

تُفرَق **عتبات تحليل الرحلة** (معنى التوقف / التجاوز / الإشعال) عن **عتبات العرض على الخريطة** (زوم، ميزانيات ماركرات، ظهور الملصقات) — هذه الأخيرة تبقى في **`MapZoomPolicy`** وما يخصها، ولا تُدمج مع التحليل.

| العنصر | الوصف |
|--------|--------|
| **`RouteIntelligenceThresholds`** (`lib/features/map/core/route_intelligence_thresholds.dart`) | نموذج العتبات: `stopSpeedEnterKmh`, `stopSpeedExitKmh`, `minStopDuration`, `overspeedThresholdKmh`, ومفاتيح `detectStops` / `detectOverspeed` / `detectIgnition`. **`defaults`** تطابق السلوك السابق قبل التخصيص. **`normalized()`** يصحّح قيماً غير صالحة دون إيقاف التشغيل. **`cacheKey`** مفتاح ثابت لـ memoization مع بصمة المسار. |
| **`routeIntelligenceThresholdsProvider`** (`lib/features/map/presentation/providers/route_intelligence_thresholds_provider.dart`) | **`RouteIntelligenceThresholds.defaults`** ثابتة (بدون دمج user/local) — للتوافق مع كود قديم. |
| **`routeIntelligenceGlobalThresholdsProvider`** (نفس الملف) | سياق **عام:** `user.attributes` → تفضيلات محلية → `defaults` (بدون جهاز/مجموعة). لإعدادات لاحقة وتقارير بلا `vehicleId`. |
| **`routeIntelligenceThresholdsForVehicleProvider`** (`family<String>`) | سياق **مركبة:** `device` → `group` → `user` → `local` → `defaults`؛ يفضّل **`liveVehicleProvider`** ثم **`vehiclesListProvider`**. **`vehicleId` فارغ:** `defaults` صِرفة. راجع **`docs/route_intelligence_thresholds_source.md`**. |

**دمج الشاشات:** **`VehicleTrackingScreen`**, **`RouteReportMapScreen`**, **`ReplayReportScreen`** تقرأ العتبات من **`routeIntelligenceThresholdsForVehicleProvider(vehicleId)`** وتدمج **`thresholds.cacheKey`** في مفتاح التحليل المخزَّن بحيث لا يُعاد التحليل إلا عند تغيّر المسار أو العتبات. في **Replay** يُستمع لتغيّر العتبات عبر **`ref.listen`** ويُحدَّث ماركر الذكاء فقط عند الحاجة دون المساس بمنطق tick الإعادة.

**ما لم يُنفَّذ بعد:** لا نموذج إعدادات في الواجهة؛ الـ Timeline وملخص السطر لا يكتبان رقماً ثابتاً لعتبة السرعة (يُعرض العدد فقط).

**تصميم مصدر الإعدادات:** راجع **`docs/route_intelligence_thresholds_source.md`** (سياق مركبة مقابل سياق عالمي، Phase 6E). شاشات التتبع/التقرير/Replay تبقى على **`routeIntelligenceThresholdsForVehicleProvider`**.

---

## 12. Replay — فجوات البيانات الناقصة (Phase R1)

| العنصر | الوصف |
|--------|--------|
| **`replay_route_gap.dart`** | **`ReplayRouteGap`**, **`replayGapThreshold`** (`Duration(minutes: 10)`), **`ReplayRouteGapDetector.detectGaps`** على قائمة **كاملة مرتبة زمنياً** (`dt > threshold`). |
| **`RoutePolylineBuilder.buildReplaySpeedColoredPolylinesRespectingGaps`** | يقسّم المسار إلى مقاطع متصلة؛ **تخفيف منفصل لكل مقطع** حتى لا يخلق decimation فجوات وهمية؛ **لا** خط بين نقطتين عبر فجوة. |
| **`buildReplayGapMarkers`** | ماركر بنفسجي عند منتصف الفجوة؛ **`InfoWindow`** مترجم (بدون إشارة Traccar). |
| **الواجهة** | شارة «بيانات ناقصة: N» في لوحة التحكم؛ **`ReplayGapsSheet`** للتفاصيل؛ صف **`dataGap`** في **`RouteEventTimeline`** (فلتر «الكل» فقط). |
| **التشغيل** | **`ReplayController`** / seek / play **دون تغيير**؛ الضغط على فجوة يبحث أقرب نقطة تشغيل لوقت **أول fix بعد الفجوة**. |
| **سجلات debug** | **`AppLogger.replay`** عند التحميل: عدد النقاط، عدد الفجوات، أطول فجوة، العتبة. |

**قيود Phase R1:** لا polyline متقطع (dashed) — فصل المقاطع فقط. فلتر Timeline للفجوات عبر شريحة **`dataGaps`** (R3). Multi Replay يعيد استخدام نفس كاشف الفجوات في polylines (R7) دون Timeline `dataGap` كامل.

---

## 13. Replay — Current Point Snapshot (Phase R2)

| العنصر | الوصف |
|--------|--------|
| **`replay_point_snapshot.dart`** | **`ReplayPointSnapshot`** + **`ReplayPointSnapshotBuilder.fromRoutePoint`** — نموذج عرض من **`RoutePoint`** الحالي في **`ReplayController`** (نقاط التشغيل المُخفَّفة، وليس القائمة الكاملة للرسم). |
| **`replay_snapshot_panel.dart`** | **`ReplaySnapshotPanel`** — بطاقة في لوحة التحكم السفلية: وقت، سرعة، تقدم٪، حركة (متوقف &lt; 5 km/h / متحرك)، عنوان اختياري، تفاصيل قابلة للطي (إحداثيات، اتجاه، إشعال). |
| **التحديث** | يُعاد البناء تلقائياً عند كل tick لأن **`_ReplayControls`** يشاهد **`replayControllerProvider`** (play / pause / seek / timeline / restart). |
| **الإشعال** | يُعرض فقط عندما **`RouteEventAnalysisResult.ignitionDataLikelyPresent`** على المسار الكامل. |
| **الفجوات (R1)** | شارة «بعد انقطاع البيانات» عندما **`fixTime`** النقطة الحالية ≈ **`gapEndTime`** (±1.5 ث). |
| **الحساسات (R9)** | في **التفاصيل الموسّعة** فقط — fuel، battery، GSM، أقمار، دقة/hdop، سائق (نص) — **إن وُجدت** في `RoutePoint.attributes`؛ لا قيم وهمية. |

**قيود Phase R2:** لا Multi Replay في هذه البطاقة؛ الإشعال يُعرض عند **`ignitionDataLikelyPresent`** على المسار الكامل (تحليل ذكاء المسار).

---

## 14. Replay — Timeline Upgrade (Phase R3)

| العنصر | الوصف |
|--------|--------|
| **`replay_timeline_helpers.dart`** | بداية/نهاية المسار، دمج supplemental، **`replayTimelineSeekTimeForItem`**, ملخص الأحداث. |
| **أنواع الصفوف** | `stop`, `overspeed`, `ignitionOn/Off`, **`dataGap`**, **`routeStart`**, **`routeEnd`**. |
| **الفلاتر** | الكل، التوقفات، تجاوز السرعة، الإشعال، **بيانات ناقصة (`dataGaps`)** — شريحة الفجوات تظهر فقط عند `counts.dataGaps > 0`. |
| **العرض** | شارة نوع الحدث، شريط لوني جانبي، **`dataGap`** بلون بنفسجي؛ ملخص سطر واحد في Replay (`showReplayEventSummary`). |
| **لوحة مضغوطة (UI-1)** | افتراضياً: Timeline يعرض **حدّين** فقط؛ عند ≥10 تنبيهات تُؤخَّر **Alerts** في عرض «الكل» المختصر؛ زر **See all events** داخل قسم الأحداث؛ سرعات x1–x8 في صف ثانٍ؛ **`_basePanelHeight`** ≈300 لإبراز الخريطة. |
| **الضغط** | seek + كاميرا + Snapshot (عبر **`ReplayController`**) + ورقة تفاصيل؛ **dataGap** → أول fix بعد الفجوة؛ **routeStart/End** → index 0 / الأخير. |

**لم يُنفَّذ:** Zoom زمني للـ Timeline؛ ربط متقدم بين المخطط والـ Timeline (يبقى **`highlightTime`** من النقطة الحالية فقط).

---

---

## 15. Replay — Events Integration (Phase R4)

| العنصر | الوصف |
|--------|--------|
| **مصادر الأحداث** | `GET /reports/events` عبر **`eventsReportProvider`**؛ تنبيهات **`GET /alerts/`** (مع `from`/`to`/`deviceId`) عبر **`replayPeriodExternalEventsProvider`**. |
| **طبقة التحويل** | **`replay_external_event.dart`**, **`replay_external_event_mapper.dart`**, **`replay_event_deduplication.dart`** — دمج مع تحليل المسار المحلي؛ أولوية Backend عند تطابق النوع ±30 ث. |
| **Timeline** | صفوف إضافية عبر **`externalTimelineItems`** في **`RouteEventTimeline`**؛ فلتر **«التنبيهات»** لـ `externalEvent` فقط؛ overspeed/ignition/stop من التقارير تدخل الفلاتر الحالية. |
| **الخريطة** | علامات وردية/برتقالية لأحداث ذات إحداثيات GPS فقط (حد أقصى 20) — **`ReplayExternalEventMarkers`**. |
| **بدون موقع** | يظهر في Timeline فقط؛ الموضع للـ seek = أقرب نقطة مسار؛ لا علامة خريطة. |
| **التفاصيل** | ورقة **`RouteEventDetailsSheet`** مع نوع/وقت/وصف؛ «الموقع غير متوفر» عند غياب GPS. |
| **الأداء** | جلب مرة واحدة عند فتح Replay (لا أثناء التشغيل). |

**لم يُربط / غير متوفر:** أحداث fuel/media/driver إن لم تُرجَع من API؛ إشعارات push كـ timeline؛ geocoding جديد للتنبيهات بدون إحداثيات.

**لم يُكسر:** R1 (فجوات)، R2 (Snapshot)، R3 (بداية/نهاية، فلاتر، ملخص).

---

---

## 16. Replay — Motion Smoothness (Phase R5)

| العنصر | الوصف |
|--------|--------|
| **Step controls** | أزرار «النقطة السابقة» / «النقطة التالية» بجانب التشغيل — `stepPrevious` / `stepNext` في **`ReplayController`** (إيقاف مؤقت ثم `seekTo`). |
| **Interpolation** | انزلاق بصري للعلامة فقط عبر **`replay_motion_helper.dart`** + `AnimationController` في الشاشة — **لا** يغيّر Snapshot (يبقى على `currentPoint` الحقيقي). |
| **منع عبر الفجوة** | `canInterpolateBetween` يرفض إذا: Δt > `replayGapThreshold`، Δt ≤ 0، إحداثيات غير صالحة، تداخل مع `ReplayRouteGap`، سرعة غير منطقية (>220 km/h). |
| **عبر gap** | قفزة فورية للعلامة (بدون انزلاق). |
| **الكاميرا** | auto-follow يتحرك عند نهاية الانزلاق أو عند القفزة؛ لا تحديث لكل إطار أثناء الانزلاق. |

**لم يُنفَّذ:** interpolation لبيانات Snapshot أو تغيير معنى سرعات x1–x8.

---

---

## 17. Single Replay — Tests & Stability (Phase R6)

مرحلة **لا تضيف Features** — تثبيت واختبارات وتوثيق بعد R1–R5.

### مجموعة الاختبارات الآلية

```bash
# Replay core (R1–R5 logic)
flutter test test/features/reports/

# Timeline / filters (R3 + R4 filters)
flutter test test/features/map/core/route_event_timeline_filter_test.dart
flutter test test/features/map/core/route_event_timeline_models_test.dart

# Static analysis (ملفات التقارير)
flutter analyze lib/features/reports/
```

### ما تغطيه الاختبارات

| منطقة | ملفات الاختبار الرئيسية |
|--------|-------------------------|
| **R1 Gaps** | `replay_route_gap_detector_test.dart` |
| **R2 Snapshot** | `replay_point_snapshot_test.dart` |
| **R3 Timeline** | `replay_timeline_helpers_test.dart`, `route_event_timeline_filter_test.dart` |
| **R4 Events** | `replay_external_event_mapper_test.dart`, `replay_event_deduplication_test.dart`, `replay_external_event_markers_test.dart` |
| **R5 Motion** | `replay_motion_helper_test.dart`, `replay_controller_test.dart` (step) |
| **Controller** | `replay_controller_test.dart` (play/pause/seek/speed/timer) |

### حدود الاختبارات

- **لا** widget tests لـ `GoogleMap` / `ReplayReportScreen` (تعتمد على QA يدوي).
- **لا** اختبارات شبكة لـ `replayPeriodExternalEventsProvider`.
- انزلاق العلامة (R5) يُختبر منطق `canInterpolateBetween` وليس إطارات Flutter.

### إصلاح استقرار (R6)

- إلغاء `AnimationController` للعلامة عند تغيير `params` في `didUpdateWidget` (منع leak بعد تغيير الفترة).

### QA يدوي — Single Replay

قائمة الفحص الكاملة (Single + Multi + KPIs + أجهزة) — **[`docs/replay_release_notes.md`](replay_release_notes.md)** § «QA Checklist finale».

### السلوك المستقر النهائي (R1–R5)

- فجوات ≥10 دقائق: polyline منفصل، timeline `dataGap`، لا انزلاق عبر الفجوة.
- Snapshot من `currentPoint` الحقيقي فقط.
- Timeline مدمج (محلي + supplemental + external مع dedup ±30 ث).
- Step + play x1–x8 + انزلاق علامة اختياري بين نقطتين آمنتين.

---

---

## 18. Single Vehicle Replay — مرجع موحّد (R1–R9)

**الشاشة:** `ReplayReportScreen` — `/reports/replay` — **`ReportFilterParams`** + اسم المركبة.

### مصدر البيانات

| العنصر | التفاصيل |
|--------|----------|
| API | تقرير المسار (`RouteDataSource` / `reportRouteProvider`) — **بدون API جديد** |
| `RoutePoint` | lat/lng، speed (km/h)، course، fixTime، ignition، address?، **attributes?** (R9) |
| نقاط كاملة | القائمة المحمّلة — gaps، events، تحليل ذكاء المسار |
| نقاط التشغيل | `ReplayController` — تصفية (0,0)، ترتيب، عيّنة **≤ 1200** للـ play/seek/snapshot |

### الخريطة

- Polyline ملوّن بالسرعة، **مقاطع منفصلة عند gaps** (§12).
- ماركرات: بداية/نهاية/أقصى سرعة/ساعية (حسب الزوم)؛ gaps بنفسجية؛ أحداث خارجية (GPS، max **20**)؛ ماركر مركبة متحرك.
- دوران الماركر عند speed ≥ 5 km/h واتجاه صالح.
- **fitBounds** عند التحميل؛ **auto-follow** (`_followVehicle`) يُوقف عند recentrer أو tap Timeline.

### Gaps (R1)

- عتبة **10 دقائق** بين fixes مرتبة.
- لا خط polyline عبر gap؛ `ReplayGapsSheet`؛ `dataGap` في Timeline؛ seek → أول fix بعد الفجوة.
- **لا** polyline متقطّع (dashed).

### Snapshot (R2 + R9)

- ثابت: وقت، سرعة، تقدم %، حركة، عنوان إن وُجد.
- موسّع: إحداثيات، اتجاه، إشعال (شرطي)، **حساسات** (حتى 4) من attributes فقط.
- «بعد انقطاع البيانات» عند fix قرب نهاية gap.

### Timeline (R3 + R4)

`routeStart` | `routeEnd` | `stop` | `overspeed` | `ignitionOn/Off` | `dataGap` | `externalEvent` — فلاتر + ملخص — tap → seek + كاميرا + ورقة تفاصيل.

### Events (R4)

تقارير events + تنبيهات الفترة؛ دمج ±30 ث dedup؛ بدون GPS = Timeline فقط.

### Motion (R5)

Step Next/Previous؛ glide بصري إن `canInterpolateBetween`؛ لا glide عبر gap؛ Snapshot = نقطة حقيقية.

### الحساسات (R9)

انظر §19 أدناه و**[`replay_release_notes.md`](replay_release_notes.md)** — لا عرض بدون بيانات؛ لا JSON خام.

**تفاصيل كل مرحلة:** §12 (R1) … §17 (R6).

---

## 19. Multi-Vehicle Replay (Phase R7)

**مسار:** `/vehicles/replay-multi` — **`MultiVehicleReplayScreen`** (2–5 مركبات، timeline موحّد). التفاصيل الكاملة: **`docs/multi_vehicle_replay.md` §19**.

| العنصر | الوصف |
|--------|--------|
| **fitBounds / Recentrer** | `MultiVehicleReplayMapHelpers` — مركبات **ظاهرة** فقط؛ padding 120؛ بدون crash عند صفر نقاط. |
| **Auto-follow** | اختياري (chip)؛ throttle ~900 ms؛ يتبع marqueurs المرئية أثناء التشغيل. |
| **مركبة نشطة** | `activeVehicleId` — tap على بطاقة الليجند؛ zIndex أعلى للماركر. |
| **Snapshot مختصر** | بطاقات أفقية: سرعة، حركة، وقت؛ بدون fuel/battery/GSM. |
| **إظهار/إخفاء** | polyline + marker؛ timeline الموحّد لا يتغيّر. |
| **ألوان** | لون ثابت افتراضي؛ **ألوان السرعة** اختيارية (مع gaps عبر `ReplayRouteGapDetector`). |
| **Single Replay** | **غير متأثر** — لا تغيير على `ReplayReportScreen` / `ReplayController`. |

**اختبارات:** `test/features/vehicles/presentation/replay_multi/` (52+).

### Phase R9 — Advanced Sensors (Single Replay)

- **`RoutePoint.attributes`** — خريطة اختيارية من route API (إن وُجدت في JSON).
- **`RoutePointAttributesMapper`** / **`ReplaySensorSnapshotBuilder`** — fuel، battery (`power`/voltage أو %)، GSM (`rssi`/%)، satellites، accuracy/hdop، driver (نص فقط).
- **العرض:** داخل **تفاصيل** `ReplaySnapshotPanel` الموسّعة فقط (حتى 4 قيم)؛ لا raw JSON؛ لا قيم وهمية.
- **الإشعال:** `RoutePoint.ignition` (يُملأ عند التحليل من attributes) له الأولوية.
- **Multi Replay:** لا عرض sensors في الواجهة (مؤجل)؛ KPIs R8 و R7 غير متأثرة.

### Phase R8 — Comparison KPIs

- **`MultiReplayKpiCalculator`** — مسافة تقريبية، مدة حركة/توقف، سرعة قصوى/متوسطة، توقفات وتجاوزات عبر **`RouteEventAnalyzer`** (عتبة 80 km/h افتراضية).
- **حساب مرة واحدة عند التحميل** — `comparisonSummary` في حالة التحميل.
- **واجهة:** chip «المقارنة» → Bottom Sheet؛ KPIs لكل المركبات المحمّلة مع تمييز المخفية/النشطة.
- **تفاصيل:** `docs/multi_vehicle_replay.md` §20.

---

## 20. Phase R10 — Documentation & QA

| العنصر | الموقع |
|--------|--------|
| **Release Notes R1–R10** | [`docs/replay_release_notes.md`](replay_release_notes.md) |
| **QA Checklist النهائي** | نفس الملف — 10 أقسام (Single، Gaps، Snapshot، Timeline، Events، Motion، Multi، KPIs، l10n، جهاز) |
| **أوامر الاختبار** | نفس الملف + §17 أعلاه |
| **Known limitations** | نفس الملف + أقسام R1–R9 هنا وفي `multi_vehicle_replay.md` |

**Phase R10 لا تضيف Features** — لا تغيير UI ولا منطق Replay.

### أوامر التحقق (Phase R10)

```bash
flutter test test/features/reports/
flutter test test/features/vehicles/presentation/replay_multi/
flutter test test/features/map/core/
flutter analyze lib/features/reports/ lib/features/vehicles/presentation/replay_multi/
```

---

*آخر تحديث: Phase R10 — توثيق Replay R1–R10 + QA؛ [`replay_release_notes.md`](replay_release_notes.md).*

---
