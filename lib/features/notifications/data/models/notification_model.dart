import '../../domain/entities/app_notification.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.vehicleId,
    this.alertId,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool isRead;
  final DateTime createdAt;
  final String? vehicleId;
  final String? alertId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'info',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      vehicleId: json['vehicleId'] as String?,
      alertId: json['alertId'] as String?,
    );
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        isRead: isRead,
        createdAt: createdAt,
        vehicleId: vehicleId,
        alertId: alertId,
      );
}
