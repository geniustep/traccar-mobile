class AppNotification {
  const AppNotification({
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
  final String category; // critical | warning | info
  final bool isRead;
  final DateTime createdAt;
  final String? vehicleId;
  final String? alertId;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      vehicleId: vehicleId,
      alertId: alertId,
    );
  }
}
