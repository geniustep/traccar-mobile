import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../../../core/models/traccar_event.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    NotificationsRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final NotificationsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Prepends a live [TraccarEvent] from the WebSocket as an unread notification.
  void addLiveEvent(TraccarEvent event) {
    final notification = AppNotification(
      id: 'live_${event.id}',
      title: _titleFromType(event.type),
      body: 'الجهاز: ${event.deviceId}',
      category: event.isCritical ? 'critical' : 'info',
      isRead: false,
      createdAt: event.eventTime,
      vehicleId: event.deviceId.toString(),
      alertId: event.id.toString(),
    );

    state = state.whenData(
      (list) => [notification, ...list].take(200).toList(),
    );
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state = state.whenData(
      (list) =>
          list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    state = state.whenData(
      (list) => list.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  static String _titleFromType(String type) {
    const map = {
      'deviceOverspeed': 'تجاوز السرعة',
      'geofenceExit': 'خروج من المنطقة',
      'geofenceEnter': 'دخول المنطقة',
      'alarm': 'إنذار',
      'deviceOffline': 'انقطع الاتصال',
      'deviceOnline': 'عاد الاتصال',
      'deviceMoving': 'بدأت الحركة',
      'deviceStopped': 'توقفت المركبة',
      'ignitionOn': 'تشغيل المحرك',
      'ignitionOff': 'إيقاف المحرك',
    };
    return map[type] ?? type;
  }
}

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, AsyncValue<List<AppNotification>>>(
  (ref) {
    final notifier =
        NotificationsNotifier(ref.read(notificationsRepositoryProvider));

    // Wire WebSocket live events → prepend as new notifications in real time
    ref.listen<List<TraccarEvent>>(liveEventsProvider, (prev, next) {
      if (prev == null || next.length <= prev.length) return;
      final newCount = next.length - prev.length;
      for (final event in next.take(newCount)) {
        notifier.addLiveEvent(event);
      }
    });

    return notifier;
  },
);

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications
          .whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ??
      0;
});
