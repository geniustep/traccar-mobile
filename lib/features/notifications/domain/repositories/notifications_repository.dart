import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> registerFcmToken(String token);
}
