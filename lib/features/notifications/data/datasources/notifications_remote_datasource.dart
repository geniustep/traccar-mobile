import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<NotificationModel>> getNotifications() async {
    return _client.get<List<NotificationModel>>(
      ApiConstants.notifications,
      fromJson: (data) => (data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markAsRead(String id) async {
    await _client.patch<void>(ApiConstants.markNotificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await _client.patch<void>(ApiConstants.markAllRead);
  }

  Future<void> registerFcmToken(String token) async {
    await _client.post<void>(
      ApiConstants.registerFcmToken,
      data: {'fcmToken': token, 'platform': 'flutter'},
    );
  }
}
