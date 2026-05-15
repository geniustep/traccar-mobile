import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connection/app_connection_monitor.dart';
import '../../../../core/debug/debug_log_store.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../fleet_intelligence/domain/fleet_dashboard_period.dart';
import '../../../fleet_intelligence/presentation/providers/fleet_intelligence_providers.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/services/dashboard_alert_filter.dart';
import '../../domain/dashboard_refresh_policy.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/insight.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'fleet_live_provider.dart';

// ── Repository & data providers ───────────────────────────────────────────────

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.read(traccarClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.read(dashboardRemoteDataSourceProvider));
});

/// Unified UTC timestamp shared by all providers within the same refresh cycle.
///
/// Overridden at the start of each refresh via [dashboardRefreshNowProvider].
/// Prevents near-simultaneous providers from computing slightly different
/// `DateTime.now()` values, which would produce different report URLs for
/// the same logical data window.
final dashboardRefreshNowProvider = StateProvider<DateTime>((ref) {
  return DateTime.now().toUtc();
});

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final refreshNow = ref.read(dashboardRefreshNowProvider);
  return ref.read(dashboardRepositoryProvider).getSummary(refreshNow: refreshNow);
});

final dashboardInsightsProvider =
    FutureProvider.autoDispose<List<InsightEntity>>((ref) async {
  final refreshNow = ref.read(dashboardRefreshNowProvider);
  return ref.read(dashboardRepositoryProvider).getInsights(refreshNow: refreshNow);
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

/// Tracks the state of the current dashboard refresh cycle.
class DashboardRefreshState {
  const DashboardRefreshState({
    this.isRefreshing = false,
    this.lastRefreshAt,
    this.lastRefreshMode = DashboardRefreshMode.none,
    this.error,
  });

  final bool isRefreshing;
  final DateTime? lastRefreshAt;
  final DashboardRefreshMode lastRefreshMode;
  final Object? error;

  bool get hasCachedData => lastRefreshAt != null;

  int get ageSeconds {
    if (lastRefreshAt == null) return -1;
    return DateTime.now().difference(lastRefreshAt!).inSeconds;
  }

  DashboardRefreshState copyWith({
    bool? isRefreshing,
    DateTime? lastRefreshAt,
    DashboardRefreshMode? lastRefreshMode,
    Object? error,
    bool clearError = false,
  }) {
    return DashboardRefreshState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      lastRefreshMode: lastRefreshMode ?? this.lastRefreshMode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardRefreshState> {
  DashboardNotifier(this._ref) : super(const DashboardRefreshState());

  final Ref _ref;

  /// Minimum interval between non-manual refreshes to prevent
  /// near-simultaneous triggers (e.g. dashboard_opened + route_resumed).
  static const _throttleWindow = Duration(seconds: 3);
  DateTime? _lastRefreshStarted;

  /// Smart refresh — picks the right mode automatically.
  Future<void> smartRefresh({
    required String reason,
    bool isManual = false,
  }) async {
    // Throttle non-manual duplicate triggers within the window
    if (!isManual && _lastRefreshStarted != null) {
      final elapsed = DateTime.now().difference(_lastRefreshStarted!);
      if (elapsed < _throttleWindow) {
        AppLogger.dashboard(
          'Refresh throttled: reason=$reason, '
          'elapsedMs=${elapsed.inMilliseconds}, '
          'throttleWindowMs=${_throttleWindow.inMilliseconds}',
        );
        return;
      }
    }

    final liveStatus = _ref.read(liveSyncStatusProvider);
    final mode = computeRefreshMode(
      lastRefreshAt: state.lastRefreshAt,
      hasCachedData: state.hasCachedData,
      isManualRefresh: isManual,
      liveStatus: liveStatus,
    );

    AppLogger.dashboard(
      'Refresh mode selected: ${mode.name}, '
      'reason: $reason, '
      'ageSeconds: ${state.ageSeconds}, '
      'hasCachedData: ${state.hasCachedData}, '
      'liveStatus: ${liveStatus.name}',
    );

    if (mode == DashboardRefreshMode.none) {
      AppLogger.dashboard(
        'Refresh skipped, reason: fresh_cache, ageSeconds: ${state.ageSeconds}',
      );
      return;
    }

    await _executeRefresh(mode: mode, source: reason);
  }

  /// Full refresh — legacy entry point for pull-to-refresh & explicit calls.
  Future<void> refresh({String source = 'unknown'}) async {
    await _executeRefresh(mode: DashboardRefreshMode.full, source: source);
  }

  Future<void> _executeRefresh({
    required DashboardRefreshMode mode,
    required String source,
  }) async {
    if (state.isRefreshing && mode != DashboardRefreshMode.full) {
      AppLogger.dashboard(
        'Refresh ignored: another refresh is running, requested: ${mode.name}',
      );
      return;
    }

    _lastRefreshStarted = DateTime.now();
    final sw = Stopwatch()..start();
    state = state.copyWith(
      isRefreshing: true,
      lastRefreshMode: mode,
      clearError: true,
    );

    // Unified timestamp for this refresh cycle
    final refreshNow = DateTime.now().toUtc();
    _ref.read(dashboardRefreshNowProvider.notifier).state = refreshNow;

    AppLogger.dashboard(
      '${_modeLabel(mode)} refresh started, source: $source, '
      'refreshNow: ${refreshNow.toIso8601String()}',
    );

    // For full/manual refresh, reset the coalescer cache
    if (mode == DashboardRefreshMode.full) {
      _ref.read(dashboardRemoteDataSourceProvider).resetCoalescer();
    }

    try {
      switch (mode) {
        case DashboardRefreshMode.none:
          break;

        case DashboardRefreshMode.silentLight:
          AppLogger.dashboard(
            'Invalidating provider: dashboardSummaryProvider, source: $source',
          );
          _ref.invalidate(dashboardSummaryProvider);
          AppLogger.dashboard(
            'Triggering: alertsProvider.load(), source: $source',
          );
          _ref.read(alertsProvider.notifier).load();

        case DashboardRefreshMode.medium:
          AppLogger.dashboard(
            'Invalidating provider: dashboardSummaryProvider, source: $source',
          );
          _ref.invalidate(dashboardSummaryProvider);
          AppLogger.dashboard(
            'Invalidating provider: dashboardInsightsProvider, source: $source',
          );
          _ref.invalidate(dashboardInsightsProvider);
          AppLogger.dashboard(
            'Triggering: alertsProvider.load(), source: $source',
          );
          _ref.read(alertsProvider.notifier).load();

        case DashboardRefreshMode.full:
          AppLogger.dashboard(
            'Invalidating provider: dashboardSummaryProvider, source: $source',
          );
          _ref.invalidate(dashboardSummaryProvider);
          AppLogger.dashboard(
            'Invalidating provider: dashboardInsightsProvider, source: $source',
          );
          _ref.invalidate(dashboardInsightsProvider);
          AppLogger.alerts('Refresh requested: source=dashboard_$source');
          AppLogger.dashboard(
            'Triggering: alertsProvider.load(), source: $source',
          );
          _ref.read(alertsProvider.notifier).load();
          for (final p in FleetDashboardPeriod.values) {
            AppLogger.dashboard(
              'Invalidating provider: fleetAdminSnapshotProvider(${p.name}), source: $source',
            );
            _ref.invalidate(fleetAdminSnapshotProvider(p));
          }
      }

      state = state.copyWith(
        isRefreshing: false,
        lastRefreshAt: DateTime.now(),
        lastRefreshMode: mode,
      );

      sw.stop();
      DebugLogStore.instance.dashboardRefreshDurationMs = sw.elapsedMilliseconds;
      AppLogger.dashboard(
        '[Dashboard] Refresh completed source=$source durationMs=${sw.elapsedMilliseconds}',
        durationMs: sw.elapsedMilliseconds,
      );
    } catch (e, st) {
      sw.stop();
      state = state.copyWith(isRefreshing: false, error: e);
      AppLogger.error(
        'Dashboard',
        '${_modeLabel(mode)} refresh failed, durationMs: ${sw.elapsedMilliseconds}',
        e,
        st,
      );
    }
  }

  String _modeLabel(DashboardRefreshMode m) => switch (m) {
        DashboardRefreshMode.none => 'None',
        DashboardRefreshMode.silentLight => 'Silent',
        DashboardRefreshMode.medium => 'Medium',
        DashboardRefreshMode.full => 'Full',
      };
}

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardRefreshState>((ref) {
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
  final restAsync = ref.watch(alertsProvider).alertsAsync;
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
