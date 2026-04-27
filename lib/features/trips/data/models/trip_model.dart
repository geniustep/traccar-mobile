import '../../domain/entities/trip.dart';

/// Maps Traccar `GET /reports/trips` response.
///
/// Key unit differences from the old model:
/// - `duration` / `idleDuration` → **milliseconds** (divide by 1000 for seconds)
/// - `maxSpeed` / `averageSpeed`  → **knots** (multiply by 1.852 for km/h)
/// - longitude field name         → `startLon` / `endLon` (not Lng)
class TripModel {
  const TripModel({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.startTime,
    this.endTime,
    this.startAddress,
    this.endAddress,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.idleSeconds,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
  });

  final String id;
  final String vehicleId;
  final String vehicleName;
  final DateTime startTime;
  final DateTime? endTime;
  final String? startAddress;
  final String? endAddress;
  final double distanceMeters;
  final int durationSeconds;
  final int idleSeconds;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final double startLat;
  final double startLng;
  final double? endLat;
  final double? endLng;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    // Traccar returns duration and idleDuration in milliseconds
    final durationMs = (json['duration'] as num?)?.toInt() ?? 0;
    final idleMs = (json['idleDuration'] as num?)?.toInt() ?? 0;

    // Speed in knots → km/h
    final maxKnots = (json['maxSpeed'] as num?)?.toDouble() ?? 0;
    final avgKnots = (json['averageSpeed'] as num?)?.toDouble() ?? 0;

    // Traccar uses "Lon" not "Lng"
    final startLon = (json['startLon'] as num?)?.toDouble() ??
        (json['startLng'] as num?)?.toDouble() ?? 0;
    final endLon = (json['endLon'] as num?)?.toDouble() ??
        (json['endLng'] as num?)?.toDouble();

    return TripModel(
      id: json['id']?.toString() ??
          '${json['deviceId']}_${json['startTime']}',
      vehicleId: json['deviceId']?.toString() ?? '',
      vehicleName: json['deviceName'] as String? ?? '',
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)?.toLocal()
          : null,
      startAddress: json['startAddress'] as String?,
      endAddress: json['endAddress'] as String?,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: durationMs ~/ 1000,
      idleSeconds: idleMs ~/ 1000,
      maxSpeedKmh: maxKnots * 1.852,
      averageSpeedKmh: avgKnots * 1.852,
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0,
      startLng: startLon,
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: endLon,
    );
  }

  TripEntity toEntity() => TripEntity(
        id: id,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        startTime: startTime,
        endTime: endTime,
        startAddress: startAddress,
        endAddress: endAddress,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        idleSeconds: idleSeconds,
        maxSpeedKmh: maxSpeedKmh,
        averageSpeedKmh: averageSpeedKmh,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );
}
