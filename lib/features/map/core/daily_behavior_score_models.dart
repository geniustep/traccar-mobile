import 'package:flutter/foundation.dart';

import 'driver_behavior_score_models.dart';
import 'trip_segment_models.dart';

/// One trip paired with its [DriverBehaviorScore] (same [DriverBehaviorScoreConfig]
/// pipeline as **`DriverBehaviorScoreCalculator.calculateTripScore`**).
@immutable
class TripBehaviorScoreEntry {
  const TripBehaviorScoreEntry({
    required this.trip,
    required this.score,
  });

  final TripSegment trip;
  final DriverBehaviorScore score;
}

/// Aggregated driving score for many **[TripSegment]** over a reporting window (Core only — Phase 9D).
///
/// **`score`** reflects a **weighted** average across **scorable** trips only; non-scorable trips are
/// counted but **never** pulled the daily score downward (they simply do not contribute to the weights).
@immutable
class DailyVehicleBehaviorScore {
  const DailyVehicleBehaviorScore({
    required this.score,
    required this.riskLevel,
    required this.isScorable,
    required this.totalTrips,
    required this.scorableTrips,
    required this.unscorableTrips,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.totalOverspeedEvents,
    required this.totalStops,
    required this.totalStopDuration,
    this.bestTrip,
    this.worstTrip,
    this.bestTripScore,
    this.worstTripScore,
    required this.tripScoreEntries,
    this.weightedAverageRaw,
    this.arithmeticAverageScore,
  });

  /// Rounded **`[0..100]`** weighted period score (**scorable** trips only).
  final int score;

  final DriverRiskLevel riskLevel;

  /// **`false`** when there are zero trips **or** no scorable trips.
  final bool isScorable;

  final int totalTrips;
  final int scorableTrips;
  final int unscorableTrips;

  final double totalDistanceKm;
  final Duration totalDuration;
  final int totalOverspeedEvents;
  final int totalStops;
  final Duration totalStopDuration;

  final TripSegment? bestTrip;
  final TripSegment? worstTrip;

  final DriverBehaviorScore? bestTripScore;
  final DriverBehaviorScore? worstTripScore;

  /// Preserves caller [TripSegment] list order within [tripScoreEntries].
  final List<TripBehaviorScoreEntry> tripScoreEntries;

  /// Weighted average before rounding (scorable subset only); `null` if [!isScorable].
  final double? weightedAverageRaw;

  /// Simple arithmetic mean of scorable **`score`** integers; `null` if none.
  final double? arithmeticAverageScore;

  bool get hasAnyTrips => totalTrips > 0;

  /// Convenience for UI layers (maps 1:1 with [tripScoreEntries]).
  List<DriverBehaviorScore> get tripScores =>
      tripScoreEntries.map((e) => e.score).toList(growable: false);
}
