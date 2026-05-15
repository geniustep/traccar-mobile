import '../../../../core/constants/elmo_fleet_attribute_keys.dart';
import '../../../map/core/vehicle_status_resolver.dart';
import '../../../fleet_domain/vehicle_odometer_reader.dart';
import '../../domain/entities/vehicle.dart';

/// Merged from Traccar `GET /devices` + `GET /positions`.
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.name,
    required this.plateNumber,
    this.uniqueId,
    this.course,
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
    this.insuranceExpiry,
    this.technicalInspectionExpiry,
    this.latestOdometerKm,
    this.deviceAttributes = const {},
  });

  final String id;
  final String name;
  final String plateNumber;
  final String? uniqueId;
  final double? course;
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
  final DateTime? insuranceExpiry;
  final DateTime? technicalInspectionExpiry;
  final double? latestOdometerKm;

  /// Copy of Traccar `device.attributes` (device row only — excludes position attrs).
  final Map<String, dynamic> deviceAttributes;

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
    final course = (position?['course'] as num?)?.toDouble();

    final status = _deriveStatus(deviceStatus, speedKmh, ignition);

    final uid = device['uniqueId'] as String?;

    return VehicleModel(
      id: (device['id'] as int).toString(),
      name: device['name'] as String? ?? '',
      plateNumber: attrs['plate'] as String? ?? uid ?? '',
      uniqueId: uid,
      course: course,
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
      insuranceExpiry: _parseFlexibleDate(
        attrs[ElmoFleetAttributeKeys.vehicleInsuranceExpiryIso],
      ),
      technicalInspectionExpiry: _parseFlexibleDate(
        attrs[ElmoFleetAttributeKeys.vehicleTechnicalExpiryIso],
      ),
      latestOdometerKm:
          VehicleOdometerReader.odometerKmFromPositionAttrs(posAttrs),
      deviceAttributes: Map<String, dynamic>.from(attrs),
    );
  }

  static String _deriveStatus(
    String deviceStatus,
    double speedKmh,
    bool ignition,
  ) {
    return VehicleStatusResolver.fromDeviceAndTelemetry(
      deviceStatus: deviceStatus,
      speedKmh: speedKmh,
      ignitionOn: ignition,
    );
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  static DateTime? _parseFlexibleDate(dynamic raw) {
    if (raw == null) return null;
    final s = '$raw'.trim();
    if (s.isEmpty) return null;
    final full = s.contains('T') ? s : '${s}T00:00:00Z';
    return DateTime.tryParse(full)?.toLocal();
  }

  VehicleEntity toEntity() => VehicleEntity(
        id: id,
        name: name,
        plateNumber: plateNumber,
        uniqueId: uniqueId,
        course: course,
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
        insuranceExpiry: insuranceExpiry,
        technicalInspectionExpiry: technicalInspectionExpiry,
        latestOdometerKm: latestOdometerKm,
        deviceAttributes:
            Map<String, dynamic>.from(deviceAttributes),
      );
}
