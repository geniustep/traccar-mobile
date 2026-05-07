import '../../../../core/models/traccar_event.dart';
import '../../../alerts/domain/entities/alert.dart';

/// The subset of Traccar event types that are surfaced on the dashboard.
///
/// Minor telemetry events (e.g. `deviceMoving`, `driverChanged`) are excluded
/// so only actionable, operator-relevant alerts appear.
const Set<String> kDashboardAlertTypes = {
  'alarm',
  'deviceOverspeed',
  'geofenceEnter',
  'geofenceExit',
  'ignitionOn',
  'ignitionOff',
  'deviceOffline',
  'deviceOnline',
  'maintenance',
};

abstract final class DashboardAlertFilter {
  /// Returns true when [type] is an actionable dashboard alert.
  static bool isImportant(String type) => kDashboardAlertTypes.contains(type);

  /// Convenience overload for a [TraccarEvent] (used by socket providers).
  static bool isImportantEvent(TraccarEvent event) =>
      isImportant(event.type);

  /// Convenience overload for an [AlertEntity] (used by REST providers).
  static bool isImportantAlert(AlertEntity alert) =>
      isImportant(alert.type);

  /// Builds a stable deduplication key for a socket-sourced alert.
  ///
  /// Socket events always have a numeric [id] from Traccar, so we prefer that.
  /// The composite fallback ensures no duplicate appears if the same event
  /// is delivered more than once with id == 0.
  static String alertId(TraccarEvent event) {
    if (event.id > 0) return '${event.id}';
    return '${event.deviceId}_${event.type}_${event.eventTime.toIso8601String()}';
  }
}
