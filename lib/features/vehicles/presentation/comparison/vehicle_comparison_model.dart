/// One row in the vehicle comparison table for today.
class VehicleComparisonItem {
  const VehicleComparisonItem({
    required this.vehicleId,
    required this.name,
    this.plate,
    this.status,
    this.lastUpdate,
    this.distanceKm,
    this.tripsCount,
    this.stopsCount,
    this.stopDurationSeconds,
    this.maxSpeedKmh,
    this.averageSpeedKmh,
    this.alertsToday,
    this.engineDurationSeconds,
  });

  final String vehicleId;
  final String name;
  final String? plate;
  final String? status;
  final DateTime? lastUpdate;
  final double? distanceKm;
  final int? tripsCount;
  final int? stopsCount;
  final int? stopDurationSeconds;
  final double? maxSpeedKmh;
  final double? averageSpeedKmh;
  final int? alertsToday;
  final int? engineDurationSeconds;
}

/// Highlight winners for neutral summary chips (no ranking blame).
class VehicleComparisonHighlights {
  const VehicleComparisonHighlights({
    this.highestDistanceVehicleId,
    this.highestAlertsVehicleId,
    this.highestStopDurationVehicleId,
    this.mostRecentUpdateVehicleId,
  });

  final String? highestDistanceVehicleId;
  final String? highestAlertsVehicleId;
  final String? highestStopDurationVehicleId;
  final String? mostRecentUpdateVehicleId;

  static VehicleComparisonHighlights fromItems(List<VehicleComparisonItem> items) {
    String? maxDistId;
    double? maxDist;

    String? maxAlertsId;
    int? maxAlerts;

    String? maxStopId;
    int? maxStopSec;

    String? recentId;
    DateTime? recentAt;

    for (final item in items) {
      final d = item.distanceKm;
      if (d != null &&
          d > 0 &&
          (maxDist == null || d > maxDist)) {
        maxDist = d;
        maxDistId = item.vehicleId;
      }

      final a = item.alertsToday;
      if (a != null &&
          a > 0 &&
          (maxAlerts == null || a > maxAlerts)) {
        maxAlerts = a;
        maxAlertsId = item.vehicleId;
      }

      final s = item.stopDurationSeconds;
      if (s != null &&
          s > 0 &&
          (maxStopSec == null || s > maxStopSec)) {
        maxStopSec = s;
        maxStopId = item.vehicleId;
      }

      final lu = item.lastUpdate;
      if (lu != null && (recentAt == null || lu.isAfter(recentAt))) {
        recentAt = lu;
        recentId = item.vehicleId;
      }
    }

    return VehicleComparisonHighlights(
      highestDistanceVehicleId: maxDistId,
      highestAlertsVehicleId: maxAlertsId,
      highestStopDurationVehicleId: maxStopId,
      mostRecentUpdateVehicleId: recentId,
    );
  }
}
