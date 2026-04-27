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

  /// Maps a Traccar event (from `GET /reports/events`) to a notification.
  factory NotificationModel.fromTraccarEvent(
    Map<String, dynamic> event, {
    String deviceName = '',
  }) {
    final type = event['type'] as String? ?? '';
    final attrs = Map<String, dynamic>.from(
      event['attributes'] as Map? ?? {},
    );
    return NotificationModel(
      id: event['id']?.toString() ?? '',
      title: _title(type),
      body: _body(type, attrs, deviceName),
      category: _category(type),
      isRead: false,
      createdAt:
          DateTime.tryParse(event['eventTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      vehicleId: event['deviceId']?.toString(),
      alertId: event['id']?.toString(),
    );
  }

  static String _title(String type) {
    const map = {
      'deviceOverspeed': 'تجاوز السرعة',
      'geofenceExit': 'خروج من المنطقة الجغرافية',
      'geofenceEnter': 'دخول المنطقة الجغرافية',
      'alarm': 'إنذار',
      'deviceOffline': 'انقطع الاتصال بالجهاز',
      'deviceOnline': 'عاد الاتصال بالجهاز',
      'deviceMoving': 'بدأت الحركة',
      'deviceStopped': 'توقفت المركبة',
      'ignitionOn': 'تشغيل المحرك',
      'ignitionOff': 'إيقاف المحرك',
      'maintenance': 'تنبيه صيانة',
    };
    return map[type] ?? type;
  }

  static String _body(
    String type,
    Map<String, dynamic> attrs,
    String deviceName,
  ) {
    final name = deviceName.isNotEmpty ? deviceName : 'المركبة';
    switch (type) {
      case 'deviceOverspeed':
        final speed = (attrs['speed'] as num?)?.toDouble();
        if (speed != null) {
          return '$name: ${(speed * 1.852).toStringAsFixed(0)} كم/س';
        }
        return '$name تجاوزت الحد المسموح';
      case 'geofenceExit':
        return '$name خرجت من المنطقة المحددة';
      case 'geofenceEnter':
        return '$name دخلت المنطقة المحددة';
      case 'alarm':
        return '$name — ${attrs['alarm'] ?? 'إنذار'}';
      default:
        return name;
    }
  }

  static String _category(String type) {
    if (type == 'alarm' || type == 'deviceOverspeed') return 'critical';
    if (type == 'geofenceExit') return 'warning';
    return 'info';
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
