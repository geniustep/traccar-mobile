import '../../domain/entities/alert.dart';

/// Maps a Traccar event row from `GET /reports/events`.
///
/// Traccar event structure:
/// ```json
/// { "id": 1, "type": "deviceOverspeed", "deviceId": 5,
///   "eventTime": "...", "positionId": 123,
///   "geofenceId": 0, "attributes": {} }
/// ```
class AlertModel {
  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.vehicleId,
    required this.vehicleName,
    required this.createdAt,
    required this.isRead,
    this.latitude,
    this.longitude,
    required this.attributes,
    this.geofenceId,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String description;
  final String vehicleId;
  final String vehicleName;
  final DateTime createdAt;
  final bool isRead;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> attributes;
  final int? geofenceId;

  /// Creates an AlertModel from a Traccar event JSON.
  ///
  /// [event]       — row from `GET /reports/events`
  /// [deviceName]  — looked-up from the devices cache (event only has deviceId)
  factory AlertModel.fromTraccarEvent(
    Map<String, dynamic> event, {
    String deviceName = '',
  }) {
    final type = event['type'] as String? ?? '';
    final attrs = Map<String, dynamic>.from(
      event['attributes'] as Map? ?? {},
    );
    final rawGf = (event['geofenceId'] as num?)?.toInt();

    return AlertModel(
      id: event['id']?.toString() ?? '',
      type: type,
      severity: _severity(type, attrs),
      title: _title(type, attrs),
      description: _description(type, attrs),
      vehicleId: event['deviceId']?.toString() ?? '',
      vehicleName: deviceName,
      createdAt:
          DateTime.tryParse(event['eventTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      isRead: false,
      latitude: (event['latitude'] as num?)?.toDouble(),
      longitude: (event['longitude'] as num?)?.toDouble(),
      geofenceId: (rawGf != null && rawGf > 0) ? rawGf : null,
      attributes: attrs,
    );
  }

  // ── Severity mapping ───────────────────────────────────────────────────────

  static String _severity(String type, Map<String, dynamic> attrs) {
    switch (type) {
      case 'alarm':
        final alarm = attrs['alarm'] as String? ?? '';
        if (alarm == 'sos' || alarm == 'hardBraking') return 'critical';
        return 'high';
      case 'deviceOverspeed':
        return 'high';
      case 'geofenceExit':
      case 'geofenceEnter':
        return 'medium';
      case 'deviceOffline':
      case 'deviceOnline':
      case 'deviceMoving':
      case 'deviceStopped':
        return 'low';
      case 'maintenance':
        return 'medium';
      default:
        return 'info';
    }
  }

  // ── Human-readable title ───────────────────────────────────────────────────

  static String _title(String type, Map<String, dynamic> attrs) {
    switch (type) {
      case 'alarm':
        return _alarmTitle(attrs['alarm'] as String? ?? '');
      case 'deviceOverspeed':
        return 'تجاوز السرعة المسموح بها';
      case 'geofenceExit':
        return 'خروج من المنطقة الجغرافية';
      case 'geofenceEnter':
        return 'دخول المنطقة الجغرافية';
      case 'deviceOffline':
        return 'الجهاز غير متصل';
      case 'deviceOnline':
        return 'الجهاز متصل';
      case 'deviceMoving':
        return 'بدأت الحركة';
      case 'deviceStopped':
        return 'توقف الجهاز';
      case 'ignitionOff':
        return 'إيقاف المحرك';
      case 'ignitionOn':
        return 'تشغيل المحرك';
      case 'maintenance':
        return 'تنبيه صيانة';
      default:
        return type;
    }
  }

  static String _alarmTitle(String alarm) {
    switch (alarm) {
      case 'sos':
        return 'SOS — نداء استغاثة';
      case 'hardBraking':
        return 'كبح مفاجئ';
      case 'hardAcceleration':
        return 'تسارع مفاجئ';
      case 'hardCornering':
        return 'انعطاف مفاجئ';
      case 'powerOff':
        return 'انقطاع الطاقة';
      case 'powerOn':
        return 'استعادة الطاقة';
      case 'tamper':
        return 'تلاعب بالجهاز';
      default:
        return 'إنذار: $alarm';
    }
  }

  // ── Human-readable description ─────────────────────────────────────────────

  static String _description(String type, Map<String, dynamic> attrs) {
    switch (type) {
      case 'deviceOverspeed':
        final speed = (attrs['speed'] as num?)?.toDouble();
        final limit = (attrs['speedLimit'] as num?)?.toDouble();
        if (speed != null && limit != null) {
          return 'السرعة ${(speed * 1.852).toStringAsFixed(0)} كم/س تجاوزت الحد ${(limit * 1.852).toStringAsFixed(0)} كم/س';
        }
        return 'تجاوز الحد المسموح للسرعة';
      case 'geofenceExit':
        return 'المركبة خرجت من المنطقة الجغرافية المحددة';
      case 'geofenceEnter':
        return 'المركبة دخلت المنطقة الجغرافية';
      case 'deviceOffline':
        return 'انقطع الاتصال بالجهاز';
      case 'deviceOnline':
        return 'عاد الاتصال بالجهاز';
      default:
        return '';
    }
  }

  AlertEntity toEntity() => AlertEntity(
        id: id,
        type: type,
        severity: severity,
        title: title,
        description: description,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        createdAt: createdAt,
        isRead: isRead,
        latitude: latitude,
        longitude: longitude,
        attributes: attributes,
        geofenceId: geofenceId,
      );
}
