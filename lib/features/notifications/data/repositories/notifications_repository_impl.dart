import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final NotificationsRemoteDataSource _dataSource;

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final models = await _dataSource.getNotifications();
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.notifications;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
    } catch (_) {}
  }

  @override
  Future<void> registerFcmToken(String token) async {
    try {
      await _dataSource.registerFcmToken(token);
    } catch (_) {}
  }
}
