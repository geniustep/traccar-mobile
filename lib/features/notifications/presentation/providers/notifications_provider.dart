import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/protected_data_guard.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../features/alerts/presentation/providers/alerts_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    NotificationsRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages the standalone notifications screen (separate from the alerts tab).
///
/// FCM and WebSocket events no longer create local notification objects;
/// instead they trigger a refresh of the [alertsProvider] which is the
/// single source of truth for all alert data.
class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data([]));

  final NotificationsRepository _repository;
  final Ref _ref;

  bool _alive = true;

  /// Deduplication set — alertIds seen this session via FCM or WebSocket.
  /// Prevents duplicate refresh calls for the same event.
  final Set<String> _seenAlertIds = {};

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  // ── Core ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    final auth = _ref.read(authProvider);
    if (!canLoadProtectedData(auth)) {
      logSkippedProtectedLoad('Notifications');
      return;
    }

    state = const AsyncValue.loading();
    try {
      final list = await _repository.getNotifications();
      if (!_alive) return;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!_alive) return;
      AppLogger.error('Notifications', 'load()', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    if (!_alive) return;
    state = state.whenData(
      (list) =>
          list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    if (!_alive) return;
    state = state.whenData(
      (list) => list.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  // ── FCM events ────────────────────────────────────────────────────────────

  /// Called when a foreground FCM message arrives.
  ///
  /// Reads the [alertId] from [data] and triggers a refresh of the
  /// [alertsProvider] (Backend is the source of truth).
  /// Does NOT create a local notification entry from FCM data.
  void addFcmEvent(Map<String, dynamic> data) {
    if (!_alive) return;
    if (!canLoadProtectedData(_ref.read(authProvider))) return;

    final type = '${data['type'] ?? '?'}';
    final alertId = data['alertId'] as String?;

    AppLogger.fcm(
      '[FCM] Foreground message: type=$type alertId=${alertId ?? '-'}',
    );

    if (alertId != null) {
      if (_seenAlertIds.contains(alertId)) {
        AppLogger.fcm('[FCM] Refresh skipped: duplicate alertId=$alertId');
        return;
      }
      _seenAlertIds.add(alertId);
    }

    AppLogger.fcm('[FCM] Triggering alerts refresh source=fcm_foreground');
    _ref.read(alertsProvider.notifier).refreshFromFcm(alertId ?? '');
  }

  /// Called when a live WebSocket event arrives.
  ///
  /// Acts as a lightweight refresh signal — does NOT create a local entry.
  void addLiveEventSignal(String? alertIdFromSocket) {
    if (!_alive) return;
    if (!canLoadProtectedData(_ref.read(authProvider))) return;

    if (alertIdFromSocket != null) {
      if (_seenAlertIds.contains(alertIdFromSocket)) {
        AppLogger.fcm(
          'WebSocket signal skipped: duplicate alertId=$alertIdFromSocket',
        );
        return;
      }
      _seenAlertIds.add(alertIdFromSocket);
    }

    _ref.read(alertsProvider.notifier).refreshUnreadCount();
  }

  void resetOnLogout() {
    _seenAlertIds.clear();
    state = const AsyncValue.data([]);
  }
}

// NOT autoDispose — survives navigation so deduplication state persists.
final notificationsProvider = StateNotifierProvider<
    NotificationsNotifier, AsyncValue<List<AppNotification>>>(
  (ref) => NotificationsNotifier(
    ref.read(notificationsRepositoryProvider),
    ref,
  ),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications
          .whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ??
      0;
});
