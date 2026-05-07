/// Traccar `GET /reports/stops` response model.
///
/// Unit notes:
/// - [durationSeconds] → converted from milliseconds.
/// - [engineHoursMs]   → milliseconds.
class StopReportModel {
  const StopReportModel({
    required this.deviceId,
    required this.deviceName,
    required this.lat,
    required this.lng,
    this.address,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.engineHoursMs,
    required this.spentFuel,
  });

  final int deviceId;
  final String deviceName;
  final double lat;
  final double lng;
  final String? address;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int engineHoursMs;
  final double spentFuel;

  factory StopReportModel.fromJson(Map<String, dynamic> json) {
    final durationMs = (json['duration'] as num?)?.toInt() ?? 0;
    // Traccar uses "lon" not "lng"
    final lon = (json['lon'] as num?)?.toDouble() ??
        (json['lng'] as num?)?.toDouble() ?? 0;

    return StopReportModel(
      deviceId: (json['deviceId'] as int?) ?? 0,
      deviceName: json['deviceName'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: lon,
      address: json['address'] as String?,
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)?.toLocal()
          : null,
      durationSeconds: durationMs ~/ 1000,
      engineHoursMs: (json['engineHours'] as num?)?.toInt() ?? 0,
      spentFuel: (json['spentFuel'] as num?)?.toDouble() ?? 0,
    );
  }
}
