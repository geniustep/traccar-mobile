import 'dart:convert';
import '../models/traccar_device.dart';
import '../models/traccar_event.dart';
import '../models/traccar_position.dart';

/// Parses the raw JSON message from the Traccar WebSocket.
///
/// Traccar sends one JSON object per message that may contain:
/// - `positions`  — list of position updates
/// - `devices`    — list of device status changes
/// - `events`     — list of triggered events
///
/// After [parse], read [SocketMessage.positions] and [SocketMessage.events]
/// (same as `msg.positions` / `msg.events` in JS). Live maps:
/// [livePositionsProvider], [liveEventsProvider].
///
/// Example payload:
/// ```json
/// {
///   "positions": [{ "id": 1, "deviceId": 42, "latitude": 24.7, ... }],
///   "devices":   [{ "id": 42, "status": "online", ... }],
///   "events":    [{ "id": 5,  "type": "deviceOverspeed", ... }]
/// }
/// ```
class SocketEventParser {
  const SocketEventParser();

  SocketMessage parse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final positions = (json['positions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TraccarPosition.fromJson)
              .toList() ??
          [];

      final devices = (json['devices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TraccarDevice.fromJson)
              .toList() ??
          [];

      final events = (json['events'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TraccarEvent.fromJson)
              .toList() ??
          [];

      return SocketMessage(
        positions: positions,
        devices: devices,
        events: events,
      );
    } catch (_) {
      return const SocketMessage.empty();
    }
  }
}

/// Parsed result of one WebSocket message.
class SocketMessage {
  const SocketMessage({
    this.positions = const [],
    this.devices = const [],
    this.events = const [],
  });

  const SocketMessage.empty()
      : positions = const [],
        devices = const [],
        events = const [];

  final List<TraccarPosition> positions;
  final List<TraccarDevice> devices;
  final List<TraccarEvent> events;

  bool get isEmpty =>
      positions.isEmpty && devices.isEmpty && events.isEmpty;

  bool get hasPositions => positions.isNotEmpty;
  bool get hasDevices => devices.isNotEmpty;
  bool get hasEvents => events.isNotEmpty;

  @override
  String toString() =>
      'SocketMessage(positions: ${positions.length}, '
      'devices: ${devices.length}, events: ${events.length})';
}
