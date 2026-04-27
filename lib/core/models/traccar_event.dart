/// Traccar Event — triggered when a rule/notification condition is met.
/// Delivered both via REST (`/reports/events`) and WebSocket stream.
class TraccarEvent {
  const TraccarEvent({
    required this.id,
    required this.type,
    required this.deviceId,
    required this.eventTime,
    this.positionId,
    this.geofenceId,
    this.maintenanceId,
    this.attributes = const {},
  });

  final int id;

  /// Event type string from Traccar (see [TraccarEventType])
  final String type;

  final int deviceId;
  final DateTime eventTime;
  final int? positionId;
  final int? geofenceId;
  final int? maintenanceId;
  final Map<String, dynamic> attributes;

  // ── Computed ──────────────────────────────────────────────────────────────

  TraccarEventType get eventType => TraccarEventType.fromString(type);

  bool get isCritical => eventType.isCritical;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory TraccarEvent.fromJson(Map<String, dynamic> json) => TraccarEvent(
        id: json['id'] as int,
        type: json['type'] as String? ?? 'unknown',
        deviceId: json['deviceId'] as int,
        eventTime: DateTime.parse(json['eventTime'] as String),
        positionId: json['positionId'] as int?,
        geofenceId: json['geofenceId'] as int?,
        maintenanceId: json['maintenanceId'] as int?,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'deviceId': deviceId,
        'eventTime': eventTime.toIso8601String(),
        if (positionId != null) 'positionId': positionId,
        if (geofenceId != null) 'geofenceId': geofenceId,
        if (maintenanceId != null) 'maintenanceId': maintenanceId,
        'attributes': attributes,
      };

  @override
  String toString() =>
      'TraccarEvent(id: $id, type: $type, device: $deviceId)';
}

/// All standard Traccar event type strings.
enum TraccarEventType {
  deviceOnline,
  deviceOffline,
  deviceUnknown,
  deviceStopped,
  deviceMoving,
  deviceOverspeed,
  deviceFuelDrop,
  deviceFuelIncrease,
  geofenceEnter,
  geofenceExit,
  alarm,
  ignitionOn,
  ignitionOff,
  maintenance,
  commandResult,
  driverChanged,
  mediaPhoto,
  unknown;

  static TraccarEventType fromString(String type) => switch (type) {
        'deviceOnline' => deviceOnline,
        'deviceOffline' => deviceOffline,
        'deviceUnknown' => deviceUnknown,
        'deviceStopped' => deviceStopped,
        'deviceMoving' => deviceMoving,
        'deviceOverspeed' => deviceOverspeed,
        'deviceFuelDrop' => deviceFuelDrop,
        'deviceFuelIncrease' => deviceFuelIncrease,
        'geofenceEnter' => geofenceEnter,
        'geofenceExit' => geofenceExit,
        'alarm' => alarm,
        'ignitionOn' => ignitionOn,
        'ignitionOff' => ignitionOff,
        'maintenance' => maintenance,
        'commandResult' => commandResult,
        'driverChanged' => driverChanged,
        'mediaPhoto' => mediaPhoto,
        _ => unknown,
      };

  bool get isCritical => switch (this) {
        deviceOverspeed ||
        geofenceExit ||
        alarm ||
        deviceFuelDrop =>
          true,
        _ => false,
      };

  String get displayName => switch (this) {
        deviceOnline => 'Device Online',
        deviceOffline => 'Device Offline',
        deviceUnknown => 'Device Unknown',
        deviceStopped => 'Device Stopped',
        deviceMoving => 'Device Moving',
        deviceOverspeed => 'Overspeed',
        deviceFuelDrop => 'Fuel Drop',
        deviceFuelIncrease => 'Fuel Increase',
        geofenceEnter => 'Geofence Entry',
        geofenceExit => 'Geofence Exit',
        alarm => 'Alarm',
        ignitionOn => 'Ignition On',
        ignitionOff => 'Ignition Off',
        maintenance => 'Maintenance',
        commandResult => 'Command Result',
        driverChanged => 'Driver Changed',
        mediaPhoto => 'Photo',
        unknown => 'Unknown Event',
      };
}
