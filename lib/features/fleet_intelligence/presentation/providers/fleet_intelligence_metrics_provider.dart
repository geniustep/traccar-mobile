import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/fleet_intelligence_dashboard_cache.dart';
import '../../application/fleet_intelligence_metrics_loader.dart';
import '../../domain/fleet_intelligence_dashboard_state.dart';
import '../../domain/fleet_intelligence_query.dart';
import '../fleet_dashboard_filter_state.dart';
import '../fleet_dashboard_date_preset.dart';
import '../../../map/presentation/providers/route_intelligence_thresholds_provider.dart';
import '../../../map/presentation/providers/tracking_provider.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';

/// ذاكرة تخزين مؤقت لنتيجة اللوحة — حياة عملية واحدة؛ لا autoDispose (**Phase 10F**).
final fleetIntelligenceDashboardCacheProvider =
    Provider<FleetIntelligenceDashboardCache>((ref) {
  return FleetIntelligenceDashboardCache();
});

/// حالة المرشّحات — تغيّر **`FleetIntelligenceQuery.cacheKey`** (**Phase 10D**).
final fleetDashboardFilterProvider =
    StateNotifierProvider<FleetDashboardFilterNotifier, FleetDashboardFilterState>(
        (ref) => FleetDashboardFilterNotifier());

class FleetDashboardFilterNotifier extends StateNotifier<FleetDashboardFilterState> {
  FleetDashboardFilterNotifier() : super(const FleetDashboardFilterState());

  void setDatePreset(FleetDashboardDatePreset p, {bool clearCustom = false}) {
    state = state.copyWith(
      datePreset: p,
      clearCustomRange: clearCustom && p != FleetDashboardDatePreset.custom,
    );
  }

  /// يضبط الفترة المخصّصة ويفعّل **[FleetDashboardDatePreset.custom]**.
  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(
      datePreset: FleetDashboardDatePreset.custom,
      customRange: range,
    );
  }

  void bumpRefreshNonce() {
    state = state.copyWith(refreshNonce: state.refreshNonce + 1);
  }
}

/// **`FleetIntelligenceQuery`** مشتق من حالة الواجهة المحلية.
final fleetIntelligenceQueryProvider = Provider<FleetIntelligenceQuery>((ref) {
  final f = ref.watch(fleetDashboardFilterProvider);
  final bounds = fleetDashboardLocalBounds(
    preset: f.datePreset,
    now: DateTime.now(),
    customRange: f.customRange,
  );
  return FleetIntelligenceQuery(
    fromLocal: bounds.$1,
    toLocal: bounds.$2,
    maxVehicles: f.maxVehicles,
    includeInactive: f.includeInactive,
    refreshNonce: f.refreshNonce,
  );
});

/// لوحة ذكاء الأسطول الكاملة — لا تحديث تلقائي مستمر؛ **`invalidate`** أو **`bumpRefreshNonce`** (**Phase 10C–10F**).
///
/// إن وُجدت لقطة **TTL** مطابقة لـ **`cacheStableKey`** و**`refreshNonce`** تُعاد دون **`getRoute`** (**Phase 10F**).
final fleetIntelligenceMetricsProvider =
    FutureProvider.autoDispose<FleetIntelligenceDashboardState>((ref) async {
  ref.keepAlive();

  final query = ref.watch(fleetIntelligenceQueryProvider);
  final cache = ref.read(fleetIntelligenceDashboardCacheProvider);
  final nowUtc = DateTime.now().toUtc();
  final cached = cache.peekIfFresh(query: query, nowUtc: nowUtc);
  if (cached != null) {
    return cached;
  }

  final vehicles = await ref.watch(vehiclesListProvider.future);

  final th = ref.watch(routeIntelligenceGlobalThresholdsProvider);
  final ds = ref.read(routeDataSourceProvider);

  final loaded = await FleetIntelligenceMetricsLoader.load(
    query: query,
    allVehicles: vehicles,
    fetchRoute: ds.getRoute,
    thresholds: th,
  );
  cache.record(
    query: query,
    state: loaded,
    nowUtc: DateTime.now().toUtc(),
  );
  return loaded;
});
