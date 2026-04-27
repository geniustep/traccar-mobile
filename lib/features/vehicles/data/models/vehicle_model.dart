import '../../domain/entities/vehicle.dart';

/// Merged from Traccar `GET /devices` + `GET /positions`.
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.status,
    required this.speed,
    required this.latitude,
    required this.longitude,
    this.address,
    this.lastUpdate,
    required this.ignition,
    this.batteryVoltage,
    this.fuelLevel,
    this.driverName,
    this.groupId,
  });

  final String id;
  final String name;
  final String plateNumber;
  final String type;
  final String status;
  final double speed;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? lastUpdate;
  final bool ignition;
  final double? batteryVoltage;
  final double? fuelLevel;
  final String? driverName;
  final String? groupId;

  /// Build from a Traccar device JSON merged with its latest position JSON.
  ///
  /// [device] — row from `GET /devices`
  /// [position] — matching row from `GET /positions` (keyed by deviceId), or null
  factory VehicleModel.fromTraccar(
    Map<String, dynamic> device,
    Map<String, dynamic>? position,
  ) {
    final attrs = Map<String, dynamic>.from(
      device['attributes'] as Map? ?? {},
    );
    final posAttrs = Map<String, dynamic>.from(
      position?['attributes'] as Map? ?? {},
    );

    final deviceStatus = device['status'] as String? ?? 'offline';
    final speedKnots = (position?['speed'] as num?)?.toDouble() ?? 0;
    final speedKmh = speedKnots * 1.852;
    final ignition = posAttrs['ignition'] as bool? ?? false;

    final status = _deriveStatus(deviceStatus, speedKmh, ignition);

    return VehicleModel(
      id: (device['id'] as int).toString(),
      name: device['name'] as String? ?? '',
      plateNumber: attrs['plate'] as String? ??
          device['uniqueId'] as String? ?? '',
      type: device['category'] as String? ?? 'car',
      status: status,
      speed: speedKmh,
      latitude: (position?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (position?['longitude'] as num?)?.toDouble() ?? 0,
      address: position?['address'] as String?,
      lastUpdate: _parseDate(
        device['lastUpdate'] as String? ?? position?['fixTime'] as String?,
      ),
      ignition: ignition,
      batteryVoltage: (posAttrs['power'] as num?)?.toDouble(),
      fuelLevel: (posAttrs['fuel'] as num?)?.toDouble(),
      driverName: attrs['driverName'] as String?,
      groupId: device['groupId'] == 0
          ? null
          : device['groupId']?.toString(),
    );
  }

  static String _deriveStatus(
    String deviceStatus,
    double speedKmh,
    bool ignition,
  ) {
    if (deviceStatus == 'offline' || deviceStatus == 'unknown') return 'offline';
    if (speedKmh > 2.0) return 'moving';
    if (ignition) return 'idle';
    return 'stopped';
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  VehicleEntity toEntity() => VehicleEntity(
        id: id,
        name: name,
        plateNumber: plateNumber,
        type: type,
        status: status,
        speed: speed,
        latitude: latitude,
        longitude: longitude,
        address: address,
        lastUpdate: lastUpdate,
        ignition: ignition,
        batteryVoltage: batteryVoltage,
        fuelLevel: fuelLevel,
        driverName: driverName,
        groupId: groupId,
      );
}
