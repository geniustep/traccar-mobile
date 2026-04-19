class TripEntity {
  const TripEntity({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.startTime,
    required this.endTime,
    required this.startAddress,
    required this.endAddress,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.idleSeconds,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
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

  bool get isOngoing => endTime == null;
}
