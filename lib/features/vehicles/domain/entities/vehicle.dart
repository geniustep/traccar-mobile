class VehicleEntity {
  const VehicleEntity({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.status,
    required this.speed,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.lastUpdate,
    required this.ignition,
    required this.batteryVoltage,
    required this.fuelLevel,
    required this.driverName,
    required this.groupId,
    this.uniqueId,
    this.course,
    this.insuranceExpiry,
    this.technicalInspectionExpiry,
    this.latestOdometerKm,
    this.deviceAttributes = const {},
  });

  final String id;
  final String name;
  final String plateNumber;

  /// Traccar `uniqueId` (IMEI / hardware id) when present — used for search / display.
  final String? uniqueId;

  /// Latest heading in degrees (0–360) when known (REST position or live socket).
  final double? course;
  final String type;
  final String status; // moving | stopped | idle | offline
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

  /// مستمدة من الطبقة الموحّدة لـ Traccar داخل خصائص الجهاز.
  final DateTime? insuranceExpiry;
  final DateTime? technicalInspectionExpiry;

  /// تقدير عداد المسافة بكيلومترات عندما تُتاح بيانات الموضع.
  final double? latestOdometerKm;

  /// Traccar `device.attributes` as returned by `GET /devices` — used for
  /// fleet extensions (Route Intelligence thresholds, expiry fields, …).
  final Map<String, dynamic> deviceAttributes;

  bool get isMoving => status == 'moving';
  bool get isStopped => status == 'stopped';
  bool get isIdle => status == 'idle';
  bool get isOffline => status == 'offline';
  bool get isOnline => !isOffline;

  VehicleEntity copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? type,
    String? status,
    double? speed,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? lastUpdate,
    bool? ignition,
    double? batteryVoltage,
    double? fuelLevel,
    String? driverName,
    String? groupId,
    String? uniqueId,
    double? course,
    DateTime? insuranceExpiry,
    DateTime? technicalInspectionExpiry,
    double? latestOdometerKm,
    Map<String, dynamic>? deviceAttributes,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      ignition: ignition ?? this.ignition,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      driverName: driverName ?? this.driverName,
      groupId: groupId ?? this.groupId,
      uniqueId: uniqueId ?? this.uniqueId,
      course: course ?? this.course,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      technicalInspectionExpiry:
          technicalInspectionExpiry ?? this.technicalInspectionExpiry,
      latestOdometerKm: latestOdometerKm ?? this.latestOdometerKm,
      deviceAttributes: deviceAttributes ?? this.deviceAttributes,
    );
  }
}
