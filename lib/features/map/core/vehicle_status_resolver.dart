import 'vehicle_status_thresholds.dart';

/// Single place for motion / connectivity status strings used across fleet + tracking.
///
/// Values align with [VehicleEntity.status]: `moving` | `idle` | `stopped` | `offline`.
/// `unknown` is returned only when inputs are ambiguous — callers map it to `offline`
/// for storage if the domain model has no `unknown`.
class VehicleStatusResolver {
  VehicleStatusResolver._();

  /// Traccar device row `status` + motion telemetry (REST merge, no socket).
  static String fromDeviceAndTelemetry({
    required String deviceStatus,
    required double speedKmh,
    required bool ignitionOn,
  }) {
    if (deviceStatus == 'offline' || deviceStatus == 'unknown') {
      return 'offline';
    }
    return fromMotionTelemetry(speedKmh: speedKmh, ignitionOn: ignitionOn);
  }

  /// Live socket position: keeps legacy behaviour (speed + ignition only; no `valid` gate).
  static String fromLiveSocket({
    required double speedKmh,
    required bool ignitionOn,
  }) {
    return fromMotionTelemetry(speedKmh: speedKmh, ignitionOn: ignitionOn);
  }

  /// Optional richer path for future use (stale fixes, invalid fixes).
  static String resolve({
    required double speedKmh,
    required bool ignitionOn,
    required bool positionLooksValid,
    required String? deviceStatus,
    DateTime? lastUpdate,
    Duration? offlineAfter,
  }) {
    final ds = deviceStatus;
    if (ds == 'offline' || ds == 'unknown') return 'offline';

    if (!positionLooksValid) return 'unknown';

    if (offlineAfter != null && lastUpdate != null) {
      if (DateTime.now().difference(lastUpdate) > offlineAfter) {
        return 'offline';
      }
    }

    return fromMotionTelemetry(speedKmh: speedKmh, ignitionOn: ignitionOn);
  }

  static String fromMotionTelemetry({
    required double speedKmh,
    required bool ignitionOn,
  }) {
    if (speedKmh > VehicleStatusThresholds.movingSpeedKmh) return 'moving';
    if (ignitionOn) return 'idle';
    return 'stopped';
  }
}
