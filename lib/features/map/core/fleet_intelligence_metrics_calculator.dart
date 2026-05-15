import 'dart:math' as math;

import 'daily_behavior_score_calculator.dart';
import 'daily_behavior_score_models.dart';
import 'driver_behavior_score_config.dart';
import 'driver_behavior_score_models.dart';
import 'fleet_intelligence_metrics_config.dart';
import 'fleet_intelligence_metrics_models.dart';

/// Fleet roll-up over many vehicles — **Phase 10A** Core (no Riverpod / network / Maps).
///
/// Tie-breaking matches **§9D** semantics where applicable: **`>` / `<`** upgrades only so the
/// **first** vehicle / trip wins on equality.
class FleetIntelligenceMetricsCalculator {
  FleetIntelligenceMetricsCalculator._();

  static double _vehicleWeightKm(
    double totalDistanceKm,
    double floorKm,
  ) {
    final d =
        totalDistanceKm.isFinite && totalDistanceKm >= 0 ? totalDistanceKm : 0.0;
    return math.max(d, floorKm);
  }

  static bool _needsAttentionFromDaily({
    required DailyVehicleBehaviorScore daily,
    required FleetIntelligenceMetricsConfig cfg,
  }) {
    if (!daily.hasAnyTrips) {
      return false;
    }
    final level = daily.riskLevel;

    if (level == DriverRiskLevel.highRisk) {
      return true;
    }

    if (daily.isScorable && daily.score <= cfg.attentionScoreAtOrBelow) {
      return true;
    }

    if (level == DriverRiskLevel.moderate &&
        daily.totalOverspeedEvents >= cfg.moderateRiskOverspeedAttentionMin) {
      return true;
    }

    return false;
  }

  static FleetRiskDistribution _riskDistribution(
    Iterable<FleetVehicleIntelligenceSummary> rows,
  ) {
    var ex = 0, gd = 0, md = 0, hr = 0, un = 0;
    for (final s in rows) {
      switch (s.riskLevel) {
        case DriverRiskLevel.excellent:
          ex++;
          break;
        case DriverRiskLevel.good:
          gd++;
          break;
        case DriverRiskLevel.moderate:
          md++;
          break;
        case DriverRiskLevel.highRisk:
          hr++;
          break;
        case DriverRiskLevel.unknown:
          un++;
          break;
      }
    }
    return FleetRiskDistribution(
      excellentCount: ex,
      goodCount: gd,
      moderateCount: md,
      highRiskCount: hr,
      unknownCount: un,
    );
  }

  /// Computes **[FleetIntelligenceMetrics]** from pre-fetched **`vehicles`** inputs.
  static FleetIntelligenceMetrics calculate({
    required List<FleetVehicleTripInput> vehicles,
    DriverBehaviorScoreConfig scoreConfig = DriverBehaviorScoreConfig.defaults,
    FleetIntelligenceMetricsConfig metricsConfig =
        FleetIntelligenceMetricsConfig.defaults,
  }) {
    try {
      final cfg = metricsConfig.normalized();
      final floorKm = cfg.minVehicleDistanceWeightKm;

      if (vehicles.isEmpty) {
        return const FleetIntelligenceMetrics(
          totalVehicles: 0,
          activeVehicles: 0,
          inactiveVehicles: 0,
          vehiclesWithTrips: 0,
          totalTrips: 0,
          totalDistanceKm: 0,
          totalDrivingDuration: Duration.zero,
          totalStopDuration: Duration.zero,
          totalStops: 0,
          totalOverspeedEvents: 0,
          averageScore: 0,
          isScorable: false,
          riskDistribution: FleetRiskDistribution(
            excellentCount: 0,
            goodCount: 0,
            moderateCount: 0,
            highRiskCount: 0,
            unknownCount: 0,
          ),
          bestVehicleSummary: null,
          worstVehicleSummary: null,
          mostActiveVehicleSummary: null,
          mostOverspeedVehicleSummary: null,
          mostStoppedVehicleSummary: null,
          vehiclesNeedingAttention: [],
          vehicleSummaries: [],
          weightedAverageRaw: null,
        );
      }

      final summaries = <FleetVehicleIntelligenceSummary>[];

      var active = 0;
      var withTrips = 0;
      var totalTripsFleet = 0;
      double totalKmFleet = 0;
      var totalDurFleet = Duration.zero;
      var totalStopDurFleet = Duration.zero;
      var totalStopsFleet = 0;
      var totalOvFleet = 0;

      for (final v in vehicles) {
        final daily = DailyVehicleBehaviorScoreCalculator
            .calculateDailyVehicleBehaviorScore(
          trips: v.trips,
          scoreConfig: scoreConfig,
        );

        final hasTrips = v.trips.isNotEmpty;
        if (hasTrips) {
          withTrips++;
        }

        final dist = daily.totalDistanceKm;
        final isActive =
            hasTrips || (dist.isFinite && dist > 0);
        if (isActive) {
          active++;
        }

        final periodScoreNullable =
            daily.isScorable ? daily.score : null;

        summaries.add(
          FleetVehicleIntelligenceSummary(
            vehicleId: v.vehicleId,
            vehicleName: v.vehicleName,
            totalTrips: daily.totalTrips,
            scorableTrips: daily.scorableTrips,
            totalDistanceKm: daily.totalDistanceKm,
            totalDrivingDuration: daily.totalDuration,
            totalStops: daily.totalStops,
            totalStopDuration: daily.totalStopDuration,
            totalOverspeedEvents: daily.totalOverspeedEvents,
            dailyVehicleBehaviorScore: daily,
            periodScore: periodScoreNullable,
            isPeriodScorable: daily.isScorable,
            riskLevel: daily.riskLevel,
            bestTrip: daily.bestTrip,
            worstTrip: daily.worstTrip,
            needsAttention:
                _needsAttentionFromDaily(daily: daily, cfg: cfg),
            isActive: isActive,
          ),
        );

        totalTripsFleet += daily.totalTrips;
        totalKmFleet += dist.isFinite ? dist : 0;
        totalDurFleet += daily.totalDuration;
        totalStopDurFleet += daily.totalStopDuration;
        totalStopsFleet += daily.totalStops;
        totalOvFleet += daily.totalOverspeedEvents;
      }

      final withFlags =
          List<FleetVehicleIntelligenceSummary>.unmodifiable(summaries);

      final attentionList =
          withFlags.where((e) => e.needsAttention).toList(growable: false);

      final dist = _riskDistribution(withFlags);

      FleetVehicleIntelligenceSummary? bestV;
      FleetVehicleIntelligenceSummary? worstV;
      var bestScrVal = -1;
      var worstScrVal = 256;

      double weightedNum = 0;
      double weightedDen = 0;
      var fleetScorable = false;

      for (final s in withFlags) {
        if (!s.isPeriodScorable || s.periodScore == null) {
          continue;
        }
        fleetScorable = true;
        final w = _vehicleWeightKm(s.totalDistanceKm, floorKm);
        weightedNum += s.periodScore! * w;
        weightedDen += w;

        if (s.periodScore! > bestScrVal) {
          bestScrVal = s.periodScore!;
          bestV = s;
        }
        if (s.periodScore! < worstScrVal) {
          worstScrVal = s.periodScore!;
          worstV = s;
        }
      }

      FleetVehicleIntelligenceSummary? mostKmV;
      var maxKm = -1.0;

      FleetVehicleIntelligenceSummary? mostOvV;
      var maxOv = -1;

      FleetVehicleIntelligenceSummary? mostStopDurV;
      var maxStopDurUs = -1;

      for (final s in withFlags) {
        final km =
            s.totalDistanceKm.isFinite ? s.totalDistanceKm : 0.0;

        if (km > maxKm) {
          maxKm = km;
          mostKmV = s;
        }

        final ov = s.totalOverspeedEvents;
        if (ov > maxOv) {
          maxOv = ov;
          mostOvV = s;
        }

        final sd = s.totalStopDuration.inMicroseconds;
        if (sd > maxStopDurUs) {
          maxStopDurUs = sd;
          mostStopDurV = s;
        }
      }

      // If no trips anywhere, specialization pointers stay null despite zeros.
      if (withTrips == 0) {
        mostKmV = null;
        mostOvV = null;
        mostStopDurV = null;
      }

      double? weightedRaw;
      int avgRounded = 0;
      if (fleetScorable && weightedDen > 0) {
        weightedRaw = weightedNum / weightedDen;
        avgRounded = weightedRaw.round().clamp(0, 100);
      } else {
        weightedRaw = null;
        avgRounded = 0;
      }

      return FleetIntelligenceMetrics(
        totalVehicles: vehicles.length,
        activeVehicles: active,
        inactiveVehicles: vehicles.length - active,
        vehiclesWithTrips: withTrips,
        totalTrips: totalTripsFleet,
        totalDistanceKm: totalKmFleet,
        totalDrivingDuration: totalDurFleet,
        totalStopDuration: totalStopDurFleet,
        totalStops: totalStopsFleet,
        totalOverspeedEvents: totalOvFleet,
        averageScore: avgRounded,
        isScorable: fleetScorable,
        riskDistribution: dist,
        bestVehicleSummary: fleetScorable ? bestV : null,
        worstVehicleSummary: fleetScorable ? worstV : null,
        mostActiveVehicleSummary: mostKmV,
        mostOverspeedVehicleSummary: mostOvV,
        mostStoppedVehicleSummary: mostStopDurV,
        vehiclesNeedingAttention: attentionList,
        vehicleSummaries: List<FleetVehicleIntelligenceSummary>.unmodifiable(
          withFlags,
        ),
        weightedAverageRaw: weightedRaw,
      );
    } catch (_) {
      return FleetIntelligenceMetrics(
        totalVehicles: vehicles.length,
        activeVehicles: 0,
        inactiveVehicles: vehicles.length,
        vehiclesWithTrips: 0,
        totalTrips: 0,
        totalDistanceKm: 0,
        totalDrivingDuration: Duration.zero,
        totalStopDuration: Duration.zero,
        totalStops: 0,
        totalOverspeedEvents: 0,
        averageScore: 0,
        isScorable: false,
        riskDistribution: FleetRiskDistribution(
          excellentCount: 0,
          goodCount: 0,
          moderateCount: 0,
          highRiskCount: 0,
          unknownCount: vehicles.length,
        ),
        bestVehicleSummary: null,
        worstVehicleSummary: null,
        mostActiveVehicleSummary: null,
        mostOverspeedVehicleSummary: null,
        mostStoppedVehicleSummary: null,
        vehiclesNeedingAttention: const [],
        vehicleSummaries: const [],
        weightedAverageRaw: null,
      );
    }
  }
}
