import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    NotificationsRemoteDataSource(ref.read(dioClientProvider)),
  );
});

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
}

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, AsyncValue<List<AppNotification>>>(
  (ref) => NotificationsNotifier(ref.read(notificationsRepositoryProvider)),
);

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications
          .whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ??
      0;
});
