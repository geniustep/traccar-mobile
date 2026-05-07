import '../../data/models/summary_report_model.dart';

/// Domain entity for a Traccar summary report.
class SummaryReport {
  const SummaryReport({
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

  double get totalDistanceKm => totalDistanceMeters / 1000;
  Duration get engineDuration => Duration(milliseconds: engineHoursMs);

  static SummaryReport fromModel(SummaryReportModel m) => SummaryReport(
        deviceId: m.deviceId,
        deviceName: m.deviceName,
        maxSpeedKmh: m.maxSpeedKmh,
        averageSpeedKmh: m.averageSpeedKmh,
        totalDistanceMeters: m.totalDistanceMeters,
        engineHoursMs: m.engineHoursMs,
        spentFuel: m.spentFuel,
        startTime: m.startTime,
        endTime: m.endTime,
      );
}
