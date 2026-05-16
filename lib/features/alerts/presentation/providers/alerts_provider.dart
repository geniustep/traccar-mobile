import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/protected_data_guard.dart';
import '../../../../core/debug/debug_log_store.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../data/datasources/alerts_remote_datasource.dart';
import '../../data/repositories/alerts_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(
    AlertsRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

// ── State ─────────────────────────────────────────────────────────────────────

class AlertsState {
  const AlertsState({
    this.alertsAsync = const AsyncValue.data([]),
    this.unreadCount = 0,
    this.statusFilter = 'all',
    this.isLoadingMore = false,
    this.offset = 0,
    this.hasMore = true,
    this.vehicleIdFilter,
    this.vehicleNameFilter,
  });

  /// 'all' | 'read' | 'unread'
  final String statusFilter;
  final AsyncValue<List<AlertEntity>> alertsAsync;
  final int unreadCount;
  final bool isLoadingMore;
  final int offset;
  final bool hasMore;
  final String? vehicleIdFilter;
  final String? vehicleNameFilter;

  bool get hasVehicleFilter =>
      vehicleIdFilter != null && vehicleIdFilter!.isNotEmpty;

  AlertsState copyWith({
    AsyncValue<List<AlertEntity>>? alertsAsync,
    int? unreadCount,
    String? statusFilter,
    bool? isLoadingMore,
    int? offset,
    bool? hasMore,
    String? vehicleIdFilter,
    String? vehicleNameFilter,
    bool clearVehicleFilter = false,
  }) {
    return AlertsState(
      alertsAsync: alertsAsync ?? this.alertsAsync,
      unreadCount: unreadCount ?? this.unreadCount,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      vehicleIdFilter: clearVehicleFilter
          ? null
          : (vehicleIdFilter ?? this.vehicleIdFilter),
      vehicleNameFilter: clearVehicleFilter
          ? null
          : (vehicleNameFilter ?? this.vehicleNameFilter),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier(this._repository, this._ref) : super(const AlertsState());

  final AlertsRepository _repository;
  final Ref _ref;

  static const int _pageSize = 50;

  /// In-flight guard: if [load] is already running, subsequent calls
  /// return the same [Future] instead of firing duplicate HTTP requests.
  Future<void>? _loadInFlight;

  /// In-flight guard for [refreshUnreadCount].
  Future<void>? _unreadCountInFlight;

  // ── Core load ──────────────────────────────────────────────────────────────

  Future<void> load({bool resetOffset = true}) {
    if (_loadInFlight != null) {
      AppLogger.alerts('load() coalesced: already in-flight');
      return _loadInFlight!;
    }
    _loadInFlight = _doLoad(resetOffset: resetOffset).whenComplete(() {
      _loadInFlight = null;
    });
    return _loadInFlight!;
  }

  Future<void> _doLoad({bool resetOffset = true}) async {
    final auth = _ref.read(authProvider);
    if (!canLoadProtectedData(auth)) {
      logSkippedProtectedLoad('Alerts');
      return;
    }

    if (resetOffset) {
      state = state.copyWith(
        alertsAsync: const AsyncValue.loading(),
        offset: 0,
        hasMore: true,
      );
    }

    try {
      final offset = resetOffset ? 0 : state.offset;

      final deviceId = int.tryParse(state.vehicleIdFilter ?? '');
      AppLogger.alerts(
        'Fetch started (filter=${state.statusFilter} offset=$offset '
        'vehicleId=${state.vehicleIdFilter ?? 'all'})',
      );

      final futures = await Future.wait([
        _repository.getAlerts(
          status: state.statusFilter,
          limit: _pageSize,
          offset: offset,
          deviceId: deviceId,
        ),
        _repository.getUnreadCount(),
      ]);

      if (!mounted) return;

      final alerts = futures[0] as List<AlertEntity>;
      final count = futures[1] as int;

      AppLogger.alerts(
        'Fetch success: total=${alerts.length} unread=$count '
        'vehicleFilter=${state.vehicleIdFilter ?? 'none'}',
      );
      if (state.hasVehicleFilter) {
        AppLogger.alerts(
          'Vehicle alerts loaded: vehicleId=${state.vehicleIdFilter} '
          'count=${alerts.length}',
        );
      }

      DebugLogStore.instance
        ..alertsLoadedCount = alerts.length
        ..alertsUnreadCount = count;

      state = state.copyWith(
        alertsAsync: AsyncValue.data(alerts),
        unreadCount: count,
        offset: offset + alerts.length,
        hasMore: alerts.length == _pageSize,
      );
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.alertsError('Fetch failed: $e');
      if (state.hasVehicleFilter) {
        AppLogger.alerts(
          'Vehicle alerts load failed: vehicleId=${state.vehicleIdFilter}',
        );
      }
      AppLogger.error('Alerts', 'load()', e, st);
      state = state.copyWith(alertsAsync: AsyncValue.error(e, st));
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  Future<void> setFilter(String status) async {
    if (state.statusFilter == status) return;
    AppLogger.alerts('Filter changed: $status');
    state = state.copyWith(statusFilter: status);
    await load();
  }

  /// Restricts alerts to one vehicle (device). Pass null to show all fleet alerts.
  Future<void> setVehicleFilter(
    String? vehicleId, {
    String? vehicleName,
  }) async {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      AppLogger.alerts(
        'Vehicle alerts filter applied: vehicleId=$vehicleId '
        'name=${vehicleName ?? ''}',
      );
      state = state.copyWith(
        vehicleIdFilter: vehicleId,
        vehicleNameFilter: vehicleName,
      );
    } else {
      AppLogger.alerts('Vehicle alerts filter cleared');
      state = state.copyWith(clearVehicleFilter: true);
    }
    await load();
  }

  // ── Load more (pagination) ────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (!canLoadProtectedData(_ref.read(authProvider))) {
      logSkippedProtectedLoad('Alerts');
      return;
    }
    if (state.isLoadingMore || !state.hasMore) return;
    final current = state.alertsAsync.valueOrNull;
    if (current == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final deviceId = int.tryParse(state.vehicleIdFilter ?? '');
      final more = await _repository.getAlerts(
        status: state.statusFilter,
        limit: _pageSize,
        offset: state.offset,
        deviceId: deviceId,
      );
      if (!mounted) return;
      state = state.copyWith(
        alertsAsync: AsyncValue.data([...current, ...more]),
        offset: state.offset + more.length,
        hasMore: more.length == _pageSize,
        isLoadingMore: false,
      );
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.alertsError('Load more failed: $e');
      AppLogger.error('Alerts', 'loadMore()', e, st);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(String id, {bool fromAlertDetail = false}) async {
    final numId = int.tryParse(id);
    if (numId == null) return;

    if (fromAlertDetail) {
      AppLogger.alerts('Auto mark read requested: alertId=$id');
    } else {
      AppLogger.alerts('Mark read requested: alertId=$id');
    }

    // Optimistic update
    _updateAlertLocally(id, isRead: true, readAt: DateTime.now());
    _decrementUnread();

    try {
      await _repository.markAlertRead(numId);
      // Refresh unread count from backend after mutation
      final count = await _repository.getUnreadCount();
      if (mounted) {
        state = state.copyWith(unreadCount: count);
        if (fromAlertDetail) {
          AppLogger.alerts(
            'Auto mark read success: alertId=$id unread=$count',
          );
        } else {
          AppLogger.alerts('Mark read success: alertId=$id unread=$count');
        }
      }
    } catch (e) {
      AppLogger.alertsError('Mark read failed: alertId=$id message=$e');
      // Keep optimistic update; don't revert (UX preference)
    }
  }

  /// Called from AlertDetailScreen after fetching `/alerts/:id`.
  /// Marks the alert as read and refreshes the list if currently showing unread.
  Future<void> markAlertReadById(int id) =>
      markAsRead(id.toString(), fromAlertDetail: true);

  // ── Mark all read ─────────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    AppLogger.alerts('Mark all read requested');

    // Optimistic update — mark every loaded alert as read
    state = state.copyWith(
      alertsAsync: state.alertsAsync.whenData(
        (list) => list.map((a) => a.copyWith(isRead: true)).toList(),
      ),
      unreadCount: 0,
    );

    try {
      await _repository.markAllAlertsRead();
      // Re-fetch unread count to confirm
      final count = await _repository.getUnreadCount();
      if (mounted) {
        state = state.copyWith(unreadCount: count);
        AppLogger.alerts('Mark all read success — unread=$count');
        AppLogger.alerts('Refresh after mark all read');
      }
    } catch (e) {
      AppLogger.alertsError('Mark all read failed: $e');
    }
  }

  // ── FCM / WebSocket refresh ───────────────────────────────────────────────

  /// Called when FCM foreground message arrives with an alertId.
  ///
  /// Phase 5 optimization: single refresh cycle — [load()] already fetches
  /// both the alerts list AND unread count in one Future.wait, so we don't
  /// call getUnreadCount() separately here. This eliminates the duplicate
  /// unread-count request that was previously fired.
  Future<void> refreshFromFcm(String alertId) async {
    if (!canLoadProtectedData(_ref.read(authProvider))) {
      logSkippedProtectedLoad('Alerts');
      return;
    }
    AppLogger.alerts('Refresh from FCM started (alertId=${alertId.isEmpty ? '-' : alertId})');
    DebugLogStore.instance
      ..alertsLastRefreshSource = 'FCM'
      ..alertsLastFcmAlertId = alertId.isNotEmpty ? alertId : null;

    final sw = Stopwatch()..start();
    try {
      if (state.statusFilter != 'read') {
        AppLogger.alerts('[Alerts] FCM refresh coalesced — single load cycle');
        await load();
      } else {
        final count = await _repository.getUnreadCount();
        if (!mounted) return;
        state = state.copyWith(unreadCount: count);
        DebugLogStore.instance.alertsUnreadCount = count;
      }
      sw.stop();
      DebugLogStore.instance
        ..alertsLastRefreshDurationMs = sw.elapsedMilliseconds
        ..fcmLastRefreshResult = 'success';
      if (mounted) {
        AppLogger.alerts(
          'Refresh from FCM success: unread=${state.unreadCount} durationMs=${sw.elapsedMilliseconds}',
        );
      }
    } catch (e, st) {
      sw.stop();
      DebugLogStore.instance.fcmLastRefreshResult = 'failed: $e';
      AppLogger.alertsError('Refresh from FCM failed: $e');
      AppLogger.error('Alerts', 'refreshFromFcm', e, st);
    }
  }

  /// Called on WebSocket event — lightweight unread-count refresh.
  Future<void> refreshUnreadCount() {
    if (_unreadCountInFlight != null) {
      AppLogger.alerts('[Alerts] Skipped unread-count: already refreshed in current cycle');
      return _unreadCountInFlight!;
    }
    _unreadCountInFlight = _doRefreshUnreadCount().whenComplete(() {
      _unreadCountInFlight = null;
    });
    return _unreadCountInFlight!;
  }

  Future<void> _doRefreshUnreadCount() async {
    if (!canLoadProtectedData(_ref.read(authProvider))) {
      logSkippedProtectedLoad('Alerts');
      return;
    }
    try {
      final count = await _repository.getUnreadCount();
      if (mounted) state = state.copyWith(unreadCount: count);
    } catch (e, st) {
      AppLogger.alertsError('refreshUnreadCount failed: $e');
      AppLogger.error('Alerts', 'refreshUnreadCount', e, st);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void resetOnLogout() {
    state = const AlertsState(
      alertsAsync: AsyncValue.data([]),
      unreadCount: 0,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateAlertLocally(String id, {required bool isRead, DateTime? readAt}) {
    state = state.copyWith(
      alertsAsync: state.alertsAsync.whenData(
        (list) => list
            .map((a) =>
                a.id == id ? a.copyWith(isRead: isRead, readAt: readAt) : a)
            .toList(),
      ),
    );
  }

  void _decrementUnread() {
    if (state.unreadCount > 0) {
      state = state.copyWith(unreadCount: state.unreadCount - 1);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

// NOT autoDispose — survives tab navigation so filter/unreadCount persist.
final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>(
  (ref) => AlertsNotifier(ref.read(alertsRepositoryProvider), ref),
);

/// Badge count — used by MainShell bottom nav.
/// Source: Backend `GET /alerts/unread-count` (via AlertsNotifier).
final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).unreadCount;
});

/// Vehicle-specific alerts (for vehicle detail screen).
final vehicleAlertsProvider = FutureProvider.autoDispose
    .family<List<AlertEntity>, String>((ref, vehicleId) async {
  if (!canLoadProtectedData(ref.read(authProvider))) {
    logSkippedProtectedLoad('Alerts');
    return [];
  }
  return ref.read(alertsRepositoryProvider).getVehicleAlerts(vehicleId);
});

/// Single alert detail — fetches from `GET /alerts/:id`.
/// Used by AlertDetailScreen so it always gets fresh data.
final alertDetailProvider =
    FutureProvider.autoDispose.family<AlertEntity?, String>((ref, alertId) async {
  if (!canLoadProtectedData(ref.read(authProvider))) {
    logSkippedProtectedLoad('Alerts');
    return null;
  }
  final numId = int.tryParse(alertId);
  if (numId == null) {
    AppLogger.alerts('Fetch detail skipped: invalid alertId=$alertId');
    return null;
  }
  AppLogger.alerts('Fetch detail started: alertId=$alertId');
  try {
    final entity = await ref.read(alertsRepositoryProvider).getAlertById(numId);
    AppLogger.alerts(
      'Fetch detail success: alertId=$alertId read=${entity.isRead}',
    );
    return entity;
  } catch (e) {
    AppLogger.alertsError('Fetch detail failed: alertId=$alertId message=$e');
    rethrow;
  }
});
