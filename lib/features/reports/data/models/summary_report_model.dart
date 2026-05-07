/// Traccar `GET /reports/summary` response model.
///
/// Unit notes:
/// - [maxSpeed] / [averageSpeed] → knots in JSON, stored as km/h here.
/// - [totalDistanceMeters]        → metres.
/// - [engineHoursMs]              → milliseconds.
class SummaryReportModel {
  const SummaryReportModel({
    required this.deviceId,
    required this.deviceName,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.totalDistanceMeters,
    required this.engineHoursMs,
    required this.spentFuel,
    this.startTime,
    this.endTime,
  });

  final int deviceId;
  final String deviceName;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final double totalDistanceMeters;
  final int engineHoursMs;
  final double spentFuel;
  final DateTime? startTime;
  final DateTime? endTime;

  factory SummaryReportModel.fromJson(Map<String, dynamic> json) {
    final maxKnots = (json['maxSpeed'] as num?)?.toDouble() ?? 0;
    final avgKnots = (json['averageSpeed'] as num?)?.toDouble() ?? 0;

    return SummaryReportModel(
      deviceId: (json['deviceId'] as int?) ?? 0,
      deviceName: json['deviceName'] as String? ?? '',
      maxSpeedKmh: maxKnots * 1.852,
      averageSpeedKmh: avgKnots * 1.852,
      totalDistanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      engineHoursMs: (json['engineHours'] as num?)?.toInt() ?? 0,
      spentFuel: (json['spentFuel'] as num?)?.toDouble() ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)?.toLocal()
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)?.toLocal()
          : null,
    );
  }
}
