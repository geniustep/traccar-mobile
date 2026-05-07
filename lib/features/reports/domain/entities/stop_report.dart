import '../../data/models/stop_report_model.dart';

/// Domain entity for a Traccar stop report entry.
class StopReport {
  const StopReport({
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

  Duration get duration => Duration(seconds: durationSeconds);

  static StopReport fromModel(StopReportModel m) => StopReport(
        deviceId: m.deviceId,
        deviceName: m.deviceName,
        lat: m.lat,
        lng: m.lng,
        address: m.address,
        startTime: m.startTime,
        endTime: m.endTime,
        durationSeconds: m.durationSeconds,
        engineHoursMs: m.engineHoursMs,
        spentFuel: m.spentFuel,
      );
}
