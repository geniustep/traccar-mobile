import 'dart:math' as math;

import 'daily_behavior_score_models.dart';
import 'driver_behavior_score_calculator.dart';
import 'driver_behavior_score_config.dart';
import 'driver_behavior_score_models.dart';
import 'trip_segment_models.dart';

/// Phase **9D** — aggregates per-window vehicle behavior without UI.
///
/// **Tie-breaking (best/worst):** when scores tie, the **first** trip in traversal order wins
/// (**strict inequality** upgrades only: `>` for best, `<` for worst).
class DailyVehicleBehaviorScoreCalculator {
  DailyVehicleBehaviorScoreCalculator._();

  static double _tripWeightKm(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm < 0) {
      return 1.0;
    }
    return math.max(distanceKm, 1.0);
  }

  /// Same thresholds as **`DriverBehaviorScoreCalculator`** [`_riskBand`], inlined to avoid altering 9A.
  static DriverRiskLevel riskLevelFromPeriodScore(
    int score,
    DriverBehaviorScoreConfig config,
  ) {
    final c = config.normalized();
    if (score >= c.excellentMin) return DriverRiskLevel.excellent;
    if (score >= c.goodMin) return DriverRiskLevel.good;
    if (score >= c.moderateMin) return DriverRiskLevel.moderate;
    return DriverRiskLevel.highRisk;
  }

  /// Aggregates **`trips`** into a **`DailyVehicleBehaviorScore`** snapshot.
  static DailyVehicleBehaviorScore calculateDailyVehicleBehaviorScore({
    required List<TripSegment> trips,
    DriverBehaviorScoreConfig scoreConfig = DriverBehaviorScoreConfig.defaults,
  }) {
    try {
      final n = trips.length;
      if (n == 0) {
        return const DailyVehicleBehaviorScore(
          score: 0,
          riskLevel: DriverRiskLevel.unknown,
          isScorable: false,
          totalTrips: 0,
          scorableTrips: 0,
          unscorableTrips: 0,
          totalDistanceKm: 0,
          totalDuration: Duration.zero,
          totalOverspeedEvents: 0,
          totalStops: 0,
          totalStopDuration: Duration.zero,
          tripScoreEntries: [],
        );
      }

      final cfg = scoreConfig.normalized();

      double totalKm = 0;
      var totalDur = Duration.zero;
      var totalOv = 0;
      var totalStopsAgg = 0;
      var totalStopDurAgg = Duration.zero;

      final entries = <TripBehaviorScoreEntry>[];
      for (final t in trips) {
        final s = DriverBehaviorScoreCalculator.calculateTripScore(
          t,
          config: cfg,
        );
        entries.add(TripBehaviorScoreEntry(trip: t, score: s));

        totalKm += t.distanceKm.isFinite ? t.distanceKm : 0;
        totalDur += t.duration;
        totalOv += t.overspeedCount;
        totalStopsAgg += t.stopCount;
        totalStopDurAgg += t.totalStopDuration;
      }

      var scorable = 0;
      var unscorable = 0;
      double weightedNum = 0;
      double weightedDen = 0;
      var arithSum = 0;
      var arithmeticCount = 0;

      TripSegment? bestTrip;
      TripSegment? worstTrip;
      DriverBehaviorScore? bestScr;
      DriverBehaviorScore? worstScr;
      int? bestScrVal;
      int? worstScrVal;

      for (final e in entries) {
        final s = e.score;
        if (s.isScorable) {
          scorable++;
          final w = _tripWeightKm(e.trip.distanceKm);
          weightedNum += s.score * w;
          weightedDen += w;
          arithSum += s.score;
          arithmeticCount++;

          if (bestScrVal == null || s.score > bestScrVal) {
            bestScrVal = s.score;
            bestTrip = e.trip;
            bestScr = s;
          }
          if (worstScrVal == null || s.score < worstScrVal) {
            worstScrVal = s.score;
            worstTrip = e.trip;
            worstScr = s;
          }
        } else {
          unscorable++;
        }
      }

      if (scorable == 0) {
        return DailyVehicleBehaviorScore(
          score: 0,
          riskLevel: DriverRiskLevel.unknown,
          isScorable: false,
          totalTrips: n,
          scorableTrips: 0,
          unscorableTrips: unscorable,
          totalDistanceKm: totalKm,
          totalDuration: totalDur,
          totalOverspeedEvents: totalOv,
          totalStops: totalStopsAgg,
          totalStopDuration: totalStopDurAgg,
          bestTrip: null,
          worstTrip: null,
          bestTripScore: null,
          worstTripScore: null,
          tripScoreEntries: List<TripBehaviorScoreEntry>.unmodifiable(entries),
          weightedAverageRaw: null,
          arithmeticAverageScore: null,
        );
      }

      final weightedRaw = weightedDen > 0 ? weightedNum / weightedDen : 0.0;
      final rounded =
          weightedRaw.round().clamp(0, 100); // Already in [0,100] logically; clamp defensively.
      final arithAvg =
          arithmeticCount > 0 ? (arithSum / arithmeticCount) : null;

      return DailyVehicleBehaviorScore(
        score: rounded,
        riskLevel: riskLevelFromPeriodScore(rounded, cfg),
        isScorable: true,
        totalTrips: n,
        scorableTrips: scorable,
        unscorableTrips: unscorable,
        totalDistanceKm: totalKm,
        totalDuration: totalDur,
        totalOverspeedEvents: totalOv,
        totalStops: totalStopsAgg,
        totalStopDuration: totalStopDurAgg,
        bestTrip: bestTrip,
        worstTrip: worstTrip,
        bestTripScore: bestScr,
        worstTripScore: worstScr,
        tripScoreEntries: List<TripBehaviorScoreEntry>.unmodifiable(entries),
        weightedAverageRaw: weightedRaw,
        arithmeticAverageScore: arithAvg,
      );
    } catch (_) {
      return const DailyVehicleBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        isScorable: false,
        totalTrips: 0,
        scorableTrips: 0,
        unscorableTrips: 0,
        totalDistanceKm: 0,
        totalDuration: Duration.zero,
        totalOverspeedEvents: 0,
        totalStops: 0,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
      );
    }
  }
}
