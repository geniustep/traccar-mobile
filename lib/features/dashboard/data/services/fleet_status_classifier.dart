/// Speed threshold (km/h) above which a vehicle is considered "moving".
/// Applied uniformly by both REST summary builder and live WebSocket provider.
const double kMovingSpeedThreshold = 5.0;

/// The four mutually-exclusive fleet status buckets.
enum FleetBucket { moving, stopped, idle, offline }

/// Single source of truth for classifying a vehicle's real-time status.
///
/// Previously the same logic existed in two places:
///   • [DashboardSummaryModel.fromTraccar] (REST)
///   • `_bucketFor()` in fleet_live_provider.dart (WebSocket)
///
/// Both now delegate here so thresholds and fallback rules stay consistent.
abstract final class FleetStatusClassifier {
  /// Classifies a device into one of [FleetBucket].
  ///
  /// Parameters:
  ///   [deviceStatus] — Traccar `device.status` ("online"/"offline"/"unknown"/null)
  ///   [speedKmh]     — current speed already converted to **km/h**
  ///   [ignition]     — ignition state from position.attributes; null = unknown
  ///
  /// Fallback rules when data is incomplete:
  ///   • null or "offline"/"unknown" status → [FleetBucket.offline]
  ///   • speed > [kMovingSpeedThreshold] → [FleetBucket.moving]
  ///   • ignition on  → [FleetBucket.idle]
  ///   • otherwise   → [FleetBucket.stopped]
  static FleetBucket classify({
    required String? deviceStatus,
    required double speedKmh,
    bool? ignition,
  }) {
    if (deviceStatus == null ||
        deviceStatus == 'offline' ||
        deviceStatus == 'unknown') {
      return FleetBucket.offline;
    }

    if (speedKmh > kMovingSpeedThreshold) return FleetBucket.moving;

    return (ignition ?? false) ? FleetBucket.idle : FleetBucket.stopped;
  }
}
