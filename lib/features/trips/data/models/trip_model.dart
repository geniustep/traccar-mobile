import '../../domain/entities/trip.dart';

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
    return TripModel(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleName: json['vehicleName'] as String? ?? '',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)?.toLocal()
          : null,
      startAddress: json['startAddress'] as String?,
      endAddress: json['endAddress'] as String?,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: json['duration'] as int? ?? 0,
      idleSeconds: json['idleDuration'] as int? ?? 0,
      maxSpeedKmh: (json['maxSpeed'] as num?)?.toDouble() ?? 0,
      averageSpeedKmh: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0,
      startLng: (json['startLng'] as num?)?.toDouble() ?? 0,
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: (json['endLng'] as num?)?.toDouble(),
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
