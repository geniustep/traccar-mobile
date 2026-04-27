/// Traccar Position — a GPS fix sent by a tracking device.
/// Maps to the `/positions` API endpoint and WebSocket position updates.
class TraccarPosition {
  const TraccarPosition({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.fixTime,
    required this.serverTime,
    this.speed = 0,
    this.course = 0,
    this.altitude = 0,
    this.accuracy = 0,
    this.address,
    this.protocol,
    this.valid = true,
    this.attributes = const {},
  });

  final int id;
  final int deviceId;
  final double latitude;
  final double longitude;

  /// Time the GPS fix was captured by the device
  final DateTime fixTime;

  /// Time Traccar received the position
  final DateTime serverTime;

  /// Speed in knots (convert ×1.852 for km/h)
  final double speed;

  /// Heading in degrees (0–360)
  final double course;

  final double altitude;
  final double accuracy;
  final String? address;

  /// Tracker protocol (osmand, teltonika, etc.)
  final String? protocol;

  /// Whether the GPS fix is valid
  final bool valid;

  /// Device-specific telemetry (ignition, fuel, odometer, etc.)
  final Map<String, dynamic> attributes;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Speed converted from knots to km/h
  double get speedKmh => speed * 1.852;

  bool get isMoving => speed > 0.5;

  bool get ignitionOn => attributes['ignition'] as bool? ?? false;

  /// Some trackers send explicit motion; otherwise infer from speed.
  bool get motion =>
      attributes['motion'] as bool? ??
      attributes['movement'] as bool? ??
      isMoving;

  /// Harsh braking flags vary by protocol / computed attributes.
  bool get hardBrake {
    final hb = attributes['hardBraking'] ??
        attributes['hardBrake'] ??
        attributes['harshBraking'] ??
        attributes['harshBrake'];
    if (hb is bool) return hb;
    if (hb is num) return hb != 0;
    return false;
  }

  /// Vehicle supply voltage (V) — prefer `power`, then common fallbacks.
  double? get vehicleVoltage =>
      (attributes['power'] as num?)?.toDouble() ??
      (attributes['battery'] as num?)?.toDouble() ??
      (attributes['adc1'] as num?)?.toDouble();

  double? get fuelLevel => (attributes['fuel'] as num?)?.toDouble();
  double? get odometer => (attributes['odometer'] as num?)?.toDouble();
  double? get batteryLevel => (attributes['batteryLevel'] as num?)?.toDouble();
  double? get batteryVoltage => vehicleVoltage;

  String? get driverUniqueId => attributes['driverUniqueId'] as String?;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory TraccarPosition.fromJson(Map<String, dynamic> json) =>
      TraccarPosition(
        id: json['id'] as int,
        deviceId: json['deviceId'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        fixTime: DateTime.parse(json['fixTime'] as String),
        serverTime: DateTime.parse(
          json['serverTime'] as String? ?? json['fixTime'] as String,
        ),
        speed: (json['speed'] as num?)?.toDouble() ?? 0,
        course: (json['course'] as num?)?.toDouble() ?? 0,
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String?,
        protocol: json['protocol'] as String?,
        valid: json['valid'] as bool? ?? true,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'fixTime': fixTime.toIso8601String(),
        'serverTime': serverTime.toIso8601String(),
        'speed': speed,
        'course': course,
        'altitude': altitude,
        'accuracy': accuracy,
        if (address != null) 'address': address,
        if (protocol != null) 'protocol': protocol,
        'valid': valid,
        'attributes': attributes,
      };

  @override
  String toString() =>
      'TraccarPosition(device: $deviceId, lat: $latitude, lng: $longitude, '
      'speed: ${speedKmh.toStringAsFixed(1)} km/h)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TraccarPosition && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
