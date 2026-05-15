import 'package:flutter/foundation.dart';

import 'daily_behavior_score_models.dart';
import 'driver_behavior_score_models.dart';
import 'trip_segment_models.dart';

/// Per-vehicle trips payload for **[FleetIntelligenceMetricsCalculator]** (no API layer).
@immutable
class FleetVehicleTripInput {
  const FleetVehicleTripInput({
    required this.vehicleId,
    required this.trips,
    this.vehicleName,
  });

  final String vehicleId;
  final String? vehicleName;
  final List<TripSegment> trips;
}

/// Buckets over **fleet vehicles** (each vehicle counted once by its period **[DriverRiskLevel]**).
@immutable
class FleetRiskDistribution {
  const FleetRiskDistribution({
    required this.excellentCount,
    required this.goodCount,
    required this.moderateCount,
    required this.highRiskCount,
    required this.unknownCount,
  });

  final int excellentCount;
  final int goodCount;
  final int moderateCount;
  final int highRiskCount;
  final int unknownCount;

  int get total =>
      excellentCount +
      goodCount +
      moderateCount +
      highRiskCount +
      unknownCount;
}

/// One vehicle roll-up built from **[DailyVehicleBehaviorScore]** plus identity fields.
@immutable
class FleetVehicleIntelligenceSummary {
  const FleetVehicleIntelligenceSummary({
    required this.vehicleId,
    required this.vehicleName,
    required this.totalTrips,
    required this.scorableTrips,
    required this.totalDistanceKm,
    required this.totalDrivingDuration,
    required this.totalStops,
    required this.totalStopDuration,
    required this.totalOverspeedEvents,
    required this.dailyVehicleBehaviorScore,
    required this.periodScore,
    required this.isPeriodScorable,
    required this.riskLevel,
    required this.bestTrip,
    required this.worstTrip,
    required this.needsAttention,
    required this.isActive,
  });

  final String vehicleId;
  final String? vehicleName;

  final int totalTrips;
  final int scorableTrips;

  final double totalDistanceKm;
  final Duration totalDrivingDuration;
  final int totalStops;
  final Duration totalStopDuration;
  final int totalOverspeedEvents;

  /// Full period snapshot (**Phase 9D** pipeline).
  final DailyVehicleBehaviorScore dailyVehicleBehaviorScore;

  /// Mirrors **[DailyVehicleBehaviorScore.score]** (`null` when [!isPeriodScorable]).
  final int? periodScore;

  final bool isPeriodScorable;

  final DriverRiskLevel riskLevel;

  final TripSegment? bestTrip;
  final TripSegment? worstTrip;

  final bool needsAttention;

  /// **true** when the vehicle has trips **or** positive roll-up distance.
  final bool isActive;
}

/// Fleet-wide aggregates for one reporting window — **Phase 10A** Core only.
@immutable
class FleetIntelligenceMetrics {
  const FleetIntelligenceMetrics({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.inactiveVehicles,
    required this.vehiclesWithTrips,
    required this.totalTrips,
    required this.totalDistanceKm,
    required this.totalDrivingDuration,
    required this.totalStopDuration,
    required this.totalStops,
    required this.totalOverspeedEvents,
    required this.averageScore,
    required this.isScorable,
    required this.riskDistribution,
    required this.bestVehicleSummary,
    required this.worstVehicleSummary,
    required this.mostActiveVehicleSummary,
    required this.mostOverspeedVehicleSummary,
    required this.mostStoppedVehicleSummary,
    required this.vehiclesNeedingAttention,
    required this.vehicleSummaries,
    this.weightedAverageRaw,
  });

  final int totalVehicles;

  /// Vehicles with **`isActive`** in **[FleetVehicleIntelligenceSummary]**.
  final int activeVehicles;

  /// **`totalVehicles - activeVehicles`**.
  final int inactiveVehicles;

  /// Count of inputs with **`trips.isNotEmpty`**.
  final int vehiclesWithTrips;

  final int totalTrips;
  final double totalDistanceKm;
  final Duration totalDrivingDuration;
  final Duration totalStopDuration;
  final int totalStops;
  final int totalOverspeedEvents;

  /// Distance-weighted mean across vehicles with **[isPeriodScorable]** /
  /// **unknown vehicles excluded**.
  ///
  /// **0** when [!isScorable].
  final int averageScore;

  /// **true** if at least one vehicle produced **[DailyVehicleBehaviorScore.isScorable]**.
  final bool isScorable;

  final FleetRiskDistribution riskDistribution;

  final FleetVehicleIntelligenceSummary? bestVehicleSummary;
  final FleetVehicleIntelligenceSummary? worstVehicleSummary;
  final FleetVehicleIntelligenceSummary? mostActiveVehicleSummary;

  /// Highest **[totalOverspeedEvents]**; tie → first in traversal order (**`>`**).
  final FleetVehicleIntelligenceSummary? mostOverspeedVehicleSummary;

  /// Highest **[totalStopDuration]**; tie → first in traversal order (**`>`**).
  final FleetVehicleIntelligenceSummary? mostStoppedVehicleSummary;

  final List<FleetVehicleIntelligenceSummary> vehiclesNeedingAttention;

  /// One entry per **[FleetVehicleTripInput]** (stable input order preserved).
  final List<FleetVehicleIntelligenceSummary> vehicleSummaries;

  /// Same weighting as [averageScore], before rounding; `null` if [!isScorable].
  final double? weightedAverageRaw;
}
