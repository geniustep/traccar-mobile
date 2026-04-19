import '../../domain/entities/vehicle.dart';

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

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>? ?? {};
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    return VehicleModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ??
          json['plate'] as String? ?? '',
      type: json['category'] as String? ?? json['type'] as String? ?? 'car',
      status: json['status'] as String? ?? 'offline',
      speed: (position['speed'] as num?)?.toDouble() ?? 0,
      latitude: (position['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (position['longitude'] as num?)?.toDouble() ?? 0,
      address: position['address'] as String?,
      lastUpdate: DateTime.tryParse(
        json['lastUpdate'] as String? ?? position['fixTime'] as String? ?? '',
      )?.toLocal(),
      ignition: attributes['ignition'] as bool? ?? false,
      batteryVoltage: (attributes['battery'] as num?)?.toDouble(),
      fuelLevel: (attributes['fuel'] as num?)?.toDouble(),
      driverName: json['driverName'] as String?,
      groupId: json['groupId']?.toString(),
    );
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
