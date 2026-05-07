import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/services/dashboard_alert_filter.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/insight.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'fleet_live_provider.dart';

// ── Repository & data providers ───────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    DashboardRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.read(dashboardRepositoryProvider).getSummary();
});

final dashboardInsightsProvider =
    FutureProvider.autoDispose<List<InsightEntity>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getInsights();
});

// ── Merged summary (REST baseline + live WebSocket overlay) ───────────────────

/// The effective [DashboardSummary] shown in the UI.
///
/// REST data is the authoritative baseline; WebSocket data overlays live
/// vehicle counts.  Alert count takes the **larger** of the two sources so
/// the dashboard number never goes backwards during a session.
///
/// Note: alertsToday here is for *display only* — it is not a formal report
/// figure since it may include events not yet persisted on the server.
DashboardSummary mergeWithLiveFleet(
  DashboardSummary base,
  FleetLiveCounts live,
  int socketAlertsToday,
) {
  // Display count: max of REST and live socket counts
  final effectiveAlerts = max(base.alertsToday, socketAlertsToday);

  if (!live.hasLiveData || live.total == 0) {
    return DashboardSummary(
      totalVehicles: base.totalVehicles,
      movingVehicles: base.movingVehicles,
      stoppedVehicles: base.stoppedVehicles,
      idleVehicles: base.idleVehicles,
      offlineVehicles: base.offlineVehicles,
      alertsToday: effectiveAlerts,
      criticalAlerts: base.criticalAlerts,
      tripsToday: base.tripsToday,
      totalDistanceToday: base.totalDistanceToday,
      lastUpdated: base.lastUpdated,
    );
  }

  // WebSocket data is available — override fleet status counts
  return DashboardSummary(
    totalVehicles: base.totalVehicles,
    movingVehicles: live.moving,
    stoppedVehicles: live.stopped,
    idleVehicles: live.idle,
    offlineVehicles: live.offline,
    alertsToday: effectiveAlerts,
    criticalAlerts: base.criticalAlerts,
    tripsToday: base.tripsToday,
    totalDistanceToday: base.totalDistanceToday,
    lastUpdated: base.lastUpdated,
  );
}

/// Derived provider that exposes the fully-merged summary as an [AsyncValue].
///
/// Computed once here and watched by UI sections — avoids the triple
/// invocation of [mergeWithLiveFleet] that was previously in the build method.
final mergedDashboardSummaryProvider =
    Provider<AsyncValue<DashboardSummary>>((ref) {
  final summaryAsync = ref.watch(dashboardSummaryProvider);
  final liveFleet = ref.watch(fleetLiveCountsProvider);
  final socketAlertsToday = ref.watch(socketEventsTodayCountProvider);

  return summaryAsync.whenData(
    (base) => mergeWithLiveFleet(base, liveFleet, socketAlertsToday),
  );
});

// ── Refresh notifier ──────────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<AsyncValue<void>> {
  DashboardNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Refreshes REST data without touching the WebSocket connection.
  ///
  /// After refresh, live socket updates continue to apply on top of the
  /// new REST baseline.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(dashboardInsightsProvider);
      _ref.invalidate(alertsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, AsyncValue<void>>(
        (ref) {
  return DashboardNotifier(ref);
});

// ── Dashboard alerts (REST baseline + live socket) ────────────────────────────

/// Recent alerts for the dashboard: REST baseline merged with live socket alerts.
///
/// Rules:
///   • Only [kDashboardAlertTypes] events are shown (non-actionable types filtered out).
///   • Socket alerts appear at the top (most recent first).
///   • Duplicate detection uses the normalised ID from [DashboardAlertFilter.alertId].
///   • An alert already in the REST list is not shown a second time from the socket.
final dashboardAlertsProvider = Provider<AsyncValue<List<AlertEntity>>>((ref) {
  final restAsync = ref.watch(alertsProvider);
  final liveAlerts = ref.watch(socketAlertsProvider);

  return restAsync.whenData((restList) {
    // Filter REST list to important types only
    final filteredRest =
        restList.where(DashboardAlertFilter.isImportantAlert).toList();

    final existingIds = filteredRest.map((a) => a.id).toSet();

    // Socket alerts that don't duplicate a REST entry
    final newFromSocket =
        liveAlerts.where((a) => !existingIds.contains(a.id)).toList();

    // Socket (newest) first, then REST baseline
    return [...newFromSocket, ...filteredRest];
  });
});
