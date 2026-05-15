import 'dart:math' as math;

import '../../map/core/driver_behavior_score_config.dart';
import '../../map/core/fleet_intelligence_metrics_calculator.dart';
import '../../map/core/fleet_intelligence_metrics_models.dart';
import '../../map/core/route_intelligence_thresholds.dart';
import '../../map/core/trip_segment_models.dart';
import '../../map/core/trip_segmenter.dart';
import '../../map/data/datasources/route_datasource.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../domain/fleet_intelligence_dashboard_state.dart';
import '../domain/fleet_intelligence_load_info.dart';
import '../domain/fleet_intelligence_query.dart';

typedef FleetIntelRouteFetcher = Future<List<RoutePoint>> Function(
  String deviceId, {
  DateTime? from,
  DateTime? to,
});

/// يحوّل قائمة مركبات + مسارات إلى **[FleetIntelligenceDashboardState]** — قابل للاختبار بدون خادم.
abstract final class FleetIntelligenceMetricsLoader {
  FleetIntelligenceMetricsLoader._();

  static Future<FleetIntelligenceDashboardState> load({
    required FleetIntelligenceQuery query,
    required List<VehicleEntity> allVehicles,
    required FleetIntelRouteFetcher fetchRoute,
    required RouteIntelligenceThresholds thresholds,
  }) async {
    final fleetRegisteredCount = allVehicles.length;

    var pool = List<VehicleEntity>.from(allVehicles);

    if (query.groupId != null && query.groupId!.trim().isNotEmpty) {
      final g = query.groupId!.trim();
      pool = pool.where((v) => (v.groupId ?? '') == g).toList();
    }

    if (query.vehicleIds != null && query.vehicleIds!.isNotEmpty) {
      final allow = query.vehicleIds!.toSet();
      pool = pool.where((v) => allow.contains(v.id)).toList();
    }

    if (!query.includeInactive) {
      pool = pool.where((v) => v.isOnline).toList();
    }

    pool.sort((a, b) {
      if (a.isOnline != b.isOnline) {
        return a.isOnline ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    final candidatesConsidered = pool.length;
    final cap = math.max(1, query.maxVehicles);
    final slice = pool.take(math.min(pool.length, cap)).toList();
    final skippedBeyondCap = math.max(0, candidatesConsidered - slice.length);

    var failures = 0;
    final inputs = <FleetVehicleTripInput>[];

    final fromUtc = query.fromLocal.toUtc();
    final toUtc = query.toLocal.toUtc();

    for (final v in slice) {
      try {
        final pts = await fetchRoute(
          v.id,
          from: fromUtc,
          to: toUtc,
        );
        final trips = TripSegmenter.build(
          vehicleId: v.id,
          points: pts,
          thresholds: thresholds,
          config: TripSegmentationConfig.defaults,
        );
        inputs.add(
          FleetVehicleTripInput(
            vehicleId: v.id,
            vehicleName: v.name,
            trips: trips,
          ),
        );
      } catch (_) {
        failures++;
        inputs.add(
          FleetVehicleTripInput(
            vehicleId: v.id,
            vehicleName: v.name,
            trips: const [],
          ),
        );
      }
    }

    final metrics = FleetIntelligenceMetricsCalculator.calculate(
      vehicles: inputs,
      scoreConfig: DriverBehaviorScoreConfig.defaults,
    );

    final loadInfo = FleetIntelligenceLoadInfo(
      fleetRegisteredCount: fleetRegisteredCount,
      candidatesConsidered: candidatesConsidered,
      routesAnalyzed: slice.length,
      routesFailedPartial: failures,
      skippedBeyondCap: skippedBeyondCap,
      maxVehicles: cap,
      fromLocal: query.fromLocal,
      toLocal: query.toLocal,
      usedOnlineFirstOrdering: true,
    );

    return FleetIntelligenceDashboardState(
      metrics: metrics,
      query: query,
      loadInfo: loadInfo,
      generatedAtUtc: DateTime.now().toUtc(),
    );
  }
}
