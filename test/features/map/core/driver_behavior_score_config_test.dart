import 'package:elmogps/features/map/core/daily_behavior_score_calculator.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/presentation/providers/driver_behavior_score_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trip_behavior_score_fixtures.dart';

void main() {
  group('DriverBehaviorScoreConfig Phase 9G', () {
    test('defaults unchanged and normalized idempotent', () {
      const d = DriverBehaviorScoreConfig.defaults;
      final n = d.normalized();
      expect(n, equals(d));
      expect(n.normalized(), equals(n));
    });

    test('normalized repairs NaN thresholds and clamps max caps', () {
      final bad = const DriverBehaviorScoreConfig().copyWith(
        baseScore: double.nan,
        excellentMin: 50,
        goodMin: 80,
        moderateMin: 40,
        maxTotalPenalty: 500,
        maxSpeedPenalty: 100,
      );
      final n = bad.normalized();
      expect(n.baseScore, 100);
      expect(n.excellentMin, 90);
      expect(n.goodMin, 75);
      expect(n.moderateMin, 55);
      expect(n.maxTotalPenalty, lessThanOrEqualTo(n.baseScore));
      expect(n.maxSpeedPenalty, lessThanOrEqualTo(n.maxTotalPenalty));
    });

    test('normalized repairs minScorable duration and negative distance', () {
      final bad = const DriverBehaviorScoreConfig().copyWith(
        minScorableDistanceKm: -1,
        minScorableDuration: Duration.zero,
      );
      final n = bad.normalized();
      expect(n.minScorableDistanceKm, 0.5);
      expect(n.minScorableDuration, const Duration(minutes: 3));
    });

    test('cacheKey changes when overspeed penalty changes', () {
      const d = DriverBehaviorScoreConfig.defaults;
      final alt = d.copyWith(overspeedEventPenalty: 9);
      expect(d.cacheKey, isNot(alt.cacheKey));
    });

    test('equality/hashCode structural', () {
      const d = DriverBehaviorScoreConfig.defaults;
      final dup = DriverBehaviorScoreConfig(
        baseScore: d.baseScore,
        excellentMin: d.excellentMin,
        goodMin: d.goodMin,
        moderateMin: d.moderateMin,
        overspeedEventPenalty: d.overspeedEventPenalty,
        severeOverspeedEventPenalty: d.severeOverspeedEventPenalty,
        severeOverspeedKmh: d.severeOverspeedKmh,
        longStopShareThreshold: d.longStopShareThreshold,
        longStopPenalty: d.longStopPenalty,
        referenceStopsPerKm: d.referenceStopsPerKm,
        excessiveStopsPenaltyRate: d.excessiveStopsPenaltyRate,
        excessiveStopsPenalty: d.excessiveStopsPenalty,
        ignitionTransitionPenalty: d.ignitionTransitionPenalty,
        ignitionTransitionsSoftMax: d.ignitionTransitionsSoftMax,
        efficiencyAvgSpeedFloorKmh: d.efficiencyAvgSpeedFloorKmh,
        efficiencyStopCountFloor: d.efficiencyStopCountFloor,
        efficiencyPenalty: d.efficiencyPenalty,
        maxSpeedPenalty: d.maxSpeedPenalty,
        maxStopPenalty: d.maxStopPenalty,
        maxIgnitionPenalty: d.maxIgnitionPenalty,
        maxEfficiencyPenalty: d.maxEfficiencyPenalty,
        maxTotalPenalty: d.maxTotalPenalty,
        minScorableDistanceKm: d.minScorableDistanceKm,
        minScorableDuration: d.minScorableDuration,
      );
      expect(dup, equals(d));
      expect(dup.hashCode, equals(d.hashCode));
    });

    test('daily aggregate respects custom normalized config', () {
      final t = testTripSegmentForScore(distanceKm: 10, overspeedCount: 4);
      final hard =
          DriverBehaviorScoreConfig.defaults.copyWith(overspeedEventPenalty: 12);
      final soft =
          DriverBehaviorScoreConfig.defaults.copyWith(overspeedEventPenalty: 1);
      final dHard =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [t],
        scoreConfig: hard,
      );
      final dSoft =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [t],
        scoreConfig: soft,
      );
      expect(dHard.isScorable, isTrue);
      expect(dSoft.isScorable, isTrue);
      expect(dSoft.score, greaterThan(dHard.score));
    });

    test('riskLevel normalizes malformed thresholds before banding', () {
      final bad = DriverBehaviorScoreConfig.defaults.copyWith(
        excellentMin: 50,
        goodMin: 80,
      );
      expect(
        DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(93, bad),
        DriverRiskLevel.excellent,
      );
    });

    test('driverBehaviorScoreConfigProvider returns defaults', () {
      final c = ProviderContainer();
      final p = c.read(driverBehaviorScoreConfigProvider);
      expect(p, DriverBehaviorScoreConfig.defaults);
      c.dispose();
    });
  });
}
