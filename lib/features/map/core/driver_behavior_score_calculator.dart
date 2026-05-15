import 'driver_behavior_score_config.dart';
import 'driver_behavior_score_models.dart';
import 'route_event_models.dart';
import 'trip_segment_models.dart';

/// Trip-level Driver Behavior Score (Phase 9A — core only).
class DriverBehaviorScoreCalculator {
  DriverBehaviorScoreCalculator._();

  /// Computes a heuristic score using [TripSegment] roll-ups plus optional analyzer output.
  ///
  /// Pass [analysis] when you already have the **same slice** `[RouteEventAnalysisResult]`
  /// used to build [trip]; it refines mild vs severe overspeed peaks. Omit it to rely purely
  /// on aggregates + peak speed heuristics.
  static DriverBehaviorScore calculateTripScore(
    TripSegment trip, {
    DriverBehaviorScoreConfig config = DriverBehaviorScoreConfig.defaults,
    RouteEventAnalysisResult? analysis,
  }) {
    final cfg = config.normalized();
    try {
      final valid = _isFiniteTrip(trip);
      final scorable = valid &&
          trip.distanceKm + 1e-9 >= cfg.minScorableDistanceKm &&
          trip.duration >= cfg.minScorableDuration;

      if (!valid || !scorable) {
        return DriverBehaviorScore(
          score: 0,
          riskLevel: DriverRiskLevel.unknown,
          classificationCode: 'unknown',
          breakdown: _emptyBreakdown(base: cfg.baseScore),
          factors: const [
            DriverBehaviorScoreFactor(
              code: 'shortTrip',
              type: 'shortTrip',
              points: 0,
              severity: DriverBehaviorFactorSeverity.info,
              description: 'confidence_not_scorable',
            ),
          ],
          isScorable: false,
        );
      }

      final factors = <DriverBehaviorScoreFactor>[];

      // --- Overspeed tiers -------------------------------------------------
      final totalOverspeed = analysis?.overspeeds.length ?? trip.overspeedCount;
      var mildOverspeed = 0;
      var severeOverspeed = 0;
      if (analysis != null) {
        for (final ev in analysis.overspeeds) {
          if (ev.speed >= cfg.severeOverspeedKmh) {
            severeOverspeed++;
          } else {
            mildOverspeed++;
          }
        }
      } else if (totalOverspeed > 0) {
        final peakSevere = trip.maxSpeedKmh >= cfg.severeOverspeedKmh;
        if (peakSevere) {
          severeOverspeed = totalOverspeed;
        } else {
          mildOverspeed = totalOverspeed;
        }
      }

      final rawMildComponent = mildOverspeed * cfg.overspeedEventPenalty;
      final rawSevereComponent =
          severeOverspeed * cfg.severeOverspeedEventPenalty;
      final rawSpeedUncapped = rawMildComponent + rawSevereComponent;
      final rawSpeedCombined =
          rawSpeedUncapped.clamp(0, cfg.maxSpeedPenalty);
      final speedScale =
          rawSpeedUncapped > 0 ? rawSpeedCombined / rawSpeedUncapped : 1.0;
      final mildPoints = rawMildComponent * speedScale;
      final severePoints = rawSevereComponent * speedScale;

      if (mildOverspeed > 0 && mildPoints > 0) {
        factors.add(
          DriverBehaviorScoreFactor(
            code: 'overspeed',
            type: 'overspeed',
            points: mildPoints,
            severity: DriverBehaviorFactorSeverity.medium,
            count: mildOverspeed,
          ),
        );
      }
      if (severeOverspeed > 0 && severePoints > 0) {
        factors.add(
          DriverBehaviorScoreFactor(
            code: 'heavyOverspeed',
            type: 'heavyOverspeed',
            points: severePoints,
            severity: DriverBehaviorFactorSeverity.high,
            count: severeOverspeed,
          ),
        );
      }

      // --- Stops ------------------------------------------------------------
      final durationMs = trip.duration.inMilliseconds.clamp(1, 1 << 62);
      final stopShare =
          trip.totalStopDuration.inMilliseconds / durationMs.toDouble();

      final stopsPerKm = trip.stopCount / (trip.distanceKm <= 0 ? 1e-6 : trip.distanceKm);
      final excessKm = stopsPerKm - cfg.referenceStopsPerKm;

      final longPen = stopShare >= cfg.longStopShareThreshold ? cfg.longStopPenalty : 0.0;

      double excessPen = excessKm > 0
          ? (excessKm * cfg.excessiveStopsPenaltyRate).clamp(
              0,
              cfg.excessiveStopsPenalty,
            )
          : 0.0;

      var rawStopPen = longPen + excessPen;
      rawStopPen = rawStopPen.clamp(0, cfg.maxStopPenalty);

      if (longPen > 0) {
        factors.add(
          DriverBehaviorScoreFactor(
            code: 'longStops',
            type: 'longStops',
            points: longPen,
            severity: DriverBehaviorFactorSeverity.low,
          ),
        );
      }
      if (excessPen > 0) {
        factors.add(
          DriverBehaviorScoreFactor(
            code: 'excessiveStops',
            type: 'excessiveStops',
            points: excessPen,
            severity: DriverBehaviorFactorSeverity.low,
            count: trip.stopCount,
          ),
        );
      }

      // --- Ignition (ignored when data absent) -----------------------------
      var rawIgnitionPen = 0.0;
      if (trip.hasIgnitionData) {
        final transitions = trip.ignitionOnCount + trip.ignitionOffCount;
        final extra = transitions - cfg.ignitionTransitionsSoftMax;
        if (extra > 0) {
          rawIgnitionPen = (extra * cfg.ignitionTransitionPenalty)
              .clamp(0, cfg.maxIgnitionPenalty);
          factors.add(
            DriverBehaviorScoreFactor(
              code: 'ignitionTransitions',
              type: 'ignitionTransitions',
              points: rawIgnitionPen,
              severity: DriverBehaviorFactorSeverity.low,
              count: transitions,
            ),
          );
        }
      }

      // --- Efficiency (tiny nudge only) -----------------------------------
      double rawEfficiencyPen = 0;
      if (trip.avgSpeedKmh <= cfg.efficiencyAvgSpeedFloorKmh &&
          trip.stopCount >= cfg.efficiencyStopCountFloor) {
        rawEfficiencyPen =
            cfg.efficiencyPenalty.clamp(0, cfg.maxEfficiencyPenalty);
        factors.add(
          DriverBehaviorScoreFactor(
            code: 'lowFlow',
            type: 'efficiency',
            points: rawEfficiencyPen,
            severity: DriverBehaviorFactorSeverity.low,
            count: trip.stopCount,
          ),
        );
      }

      final double speedPenalty = rawSpeedCombined.toDouble();
      final stopPenalty = rawStopPen;
      final ignitionPenalty = rawIgnitionPen;
      final efficiencyPenalty = rawEfficiencyPen;

      var totalPenalty = speedPenalty + stopPenalty + ignitionPenalty + efficiencyPenalty;
      totalPenalty = totalPenalty.clamp(0, cfg.maxTotalPenalty);

      var scoreDouble = cfg.baseScore - totalPenalty;
      scoreDouble = scoreDouble.clamp(0, cfg.baseScore);
      final score = scoreDouble.round().clamp(0, 100);

      final classification = _riskBand(score, cfg);

      final cleanCandidate = totalOverspeed == 0 &&
          rawStopPen < 1e-9 &&
          rawEfficiencyPen < 1e-9 &&
          !factors.any((f) =>
              f.code == 'longStops' ||
              f.code == 'excessiveStops');
      if (cleanCandidate) {
        final hasClean =
            factors.any((f) => f.code == 'cleanTrip');
        if (!hasClean) {
          factors.add(
            const DriverBehaviorScoreFactor(
              code: 'cleanTrip',
              type: 'cleanTrip',
              points: 0,
              severity: DriverBehaviorFactorSeverity.info,
            ),
          );
        }
      }

      return DriverBehaviorScore(
        score: score,
        riskLevel: classification.$1,
        classificationCode: classification.$2,
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: speedPenalty,
          stopPenalty: stopPenalty,
          ignitionPenalty: ignitionPenalty,
          efficiencyPenalty: efficiencyPenalty,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: totalPenalty,
          baseScore: cfg.baseScore,
        ),
        factors: List<DriverBehaviorScoreFactor>.unmodifiable(factors),
        isScorable: true,
      );
    } catch (_) {
      return DriverBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        classificationCode: 'unknown',
        breakdown: _emptyBreakdown(base: cfg.baseScore),
        factors: const [
          DriverBehaviorScoreFactor(
            code: 'invalidTrip',
            type: 'invalidTrip',
            points: 0,
            severity: DriverBehaviorFactorSeverity.info,
          ),
        ],
        isScorable: false,
      );
    }
  }

  static DriverBehaviorScoreBreakdown _emptyBreakdown({required double base}) =>
      DriverBehaviorScoreBreakdown(
        speedPenalty: 0,
        stopPenalty: 0,
        ignitionPenalty: 0,
        efficiencyPenalty: 0,
        shortTripPenalty: 0,
        confidencePenalty: 0,
        totalPenalty: 0,
        baseScore: base,
      );

  static bool _isFiniteTrip(TripSegment trip) {
    bool ok(num v) => !v.isNaN && !v.isInfinite;
    return ok(trip.distanceKm) &&
        ok(trip.maxSpeedKmh) &&
        ok(trip.avgSpeedKmh) &&
        trip.duration > Duration.zero &&
        trip.stopCount >= 0 &&
        trip.overspeedCount >= 0;
  }

  static (DriverRiskLevel, String) _riskBand(int score,
      DriverBehaviorScoreConfig config,) {
    if (score >= config.excellentMin) {
      return (DriverRiskLevel.excellent, 'excellent');
    }
    if (score >= config.goodMin) {
      return (DriverRiskLevel.good, 'good');
    }
    if (score >= config.moderateMin) {
      return (DriverRiskLevel.moderate, 'moderate');
    }
    return (DriverRiskLevel.highRisk, 'high_risk');
  }
}

extension TripSegmentBehaviorScoreExtension on TripSegment {
  DriverBehaviorScore behaviorScore({
    DriverBehaviorScoreConfig config = DriverBehaviorScoreConfig.defaults,
    RouteEventAnalysisResult? analysis,
  }) =>
      DriverBehaviorScoreCalculator.calculateTripScore(
        this,
        config: config,
        analysis: analysis,
      );
}
