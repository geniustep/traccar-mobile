import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalVehicles,
    required this.movingVehicles,
    required this.stoppedVehicles,
    required this.idleVehicles,
    required this.offlineVehicles,
    required this.alertsToday,
    required this.criticalAlerts,
    required this.tripsToday,
    required this.totalDistanceToday,
    required this.lastUpdated,
  });

  final int totalVehicles;
  final int movingVehicles;
  final int stoppedVehicles;
  final int idleVehicles;
  final int offlineVehicles;
  final int alertsToday;
  final int criticalAlerts;
  final int tripsToday;
  final double totalDistanceToday;
  final DateTime lastUpdated;

  /// Builds a summary from raw Traccar data.
  ///
  /// [devices]   — list from `GET /devices`
  /// [positions] — list from `GET /positions` (keyed by deviceId)
  /// [trips]     — list from `GET /reports/trips` (today)
  /// [events]    — list from `GET /reports/events` (today)
  factory DashboardSummaryModel.fromTraccar({
    required List<Map<String, dynamic>> devices,
    required List<Map<String, dynamic>> positions,
    required List<Map<String, dynamic>> trips,
    required List<Map<String, dynamic>> events,
  }) {
    // Index positions by deviceId
    final posMap = <int, Map<String, dynamic>>{
      for (final p in positions)
        if (p['deviceId'] is int) (p['deviceId'] as int): p,
    };

    int moving = 0, stopped = 0, idle = 0, offline = 0;
    for (final d in devices) {
      final status = d['status'] as String? ?? 'offline';
      if (status == 'offline' || status == 'unknown') {
        offline++;
        continue;
      }
      final pos = posMap[d['id'] as int?];
      final posAttrs =
          Map<String, dynamic>.from(pos?['attributes'] as Map? ?? {});
      final speedKnots = (pos?['speed'] as num?)?.toDouble() ?? 0;
      final ignition = posAttrs['ignition'] as bool? ?? false;

      if (speedKnots * 1.852 > 2.0) {
        moving++;
      } else if (ignition) {
        idle++;
      } else {
        stopped++;
      }
    }

    final criticalTypes = {'alarm', 'deviceOverspeed'};
    final critical =
        events.where((e) => criticalTypes.contains(e['type'])).length;

    final totalDistance = trips.fold<double>(
      0,
      (sum, t) => sum + ((t['distance'] as num?)?.toDouble() ?? 0),
    );

    return DashboardSummaryModel(
      totalVehicles: devices.length,
      movingVehicles: moving,
      stoppedVehicles: stopped,
      idleVehicles: idle,
      offlineVehicles: offline,
      alertsToday: events.length,
      criticalAlerts: critical,
      tripsToday: trips.length,
      totalDistanceToday: totalDistance,
      lastUpdated: DateTime.now(),
    );
  }

  DashboardSummary toEntity() => DashboardSummary(
        totalVehicles: totalVehicles,
        movingVehicles: movingVehicles,
        stoppedVehicles: stoppedVehicles,
        idleVehicles: idleVehicles,
        offlineVehicles: offlineVehicles,
        alertsToday: alertsToday,
        criticalAlerts: criticalAlerts,
        tripsToday: tripsToday,
        totalDistanceToday: totalDistanceToday,
        lastUpdated: lastUpdated,
      );
}
