/// Traccar `GET /reports/events` response model.
///
/// Note: deviceName is NOT in the Traccar response; it must be injected
/// via the device name map after fetching devices separately.
///
/// Speed in attributes is in knots — converted to km/h here.
class EventReportModel {
  const EventReportModel({
    required this.id,
    required this.type,
    required this.eventTime,
    required this.deviceId,
    required this.deviceName,
    this.speedKmh,
    this.positionId,
    this.geofenceId,
    this.maintenanceId,
    required this.attributes,
  });

  final int id;
  final String type;
  final DateTime eventTime;
  final int deviceId;
  final String deviceName;
  final double? speedKmh;
  final int? positionId;
  final int? geofenceId;
  final int? maintenanceId;
  final Map<String, dynamic> attributes;

  factory EventReportModel.fromJson(
    Map<String, dynamic> json, {
    String deviceName = '',
  }) {
    final attrs =
        Map<String, dynamic>.from(json['attributes'] as Map? ?? {});
    final speedKnots = (attrs['speed'] as num?)?.toDouble();

    return EventReportModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      eventTime:
          DateTime.tryParse(json['eventTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      deviceId: (json['deviceId'] as num?)?.toInt() ?? 0,
      deviceName: deviceName,
      speedKmh: speedKnots != null ? speedKnots * 1.852 : null,
      positionId: (json['positionId'] as num?)?.toInt(),
      geofenceId: (json['geofenceId'] as num?)?.toInt(),
      maintenanceId: (json['maintenanceId'] as num?)?.toInt(),
      attributes: attrs,
    );
  }
}
