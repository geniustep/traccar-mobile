import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final NotificationsRemoteDataSource _dataSource;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final models = await _dataSource.getNotifications();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await _dataSource.markAllAsRead();
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _dataSource.registerFcmToken(token);
  }
}
