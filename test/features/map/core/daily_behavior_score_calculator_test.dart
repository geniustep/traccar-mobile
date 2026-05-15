import 'dart:math' as math;

import 'package:elmogps/features/map/core/daily_behavior_score_calculator.dart';
import 'package:elmogps/features/map/core/daily_behavior_score_models.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_calculator.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trip_behavior_score_fixtures.dart';

void main() {
  DailyVehicleBehaviorScore calc(List<TripSegment> trips,
      {DriverBehaviorScoreConfig cfg = DriverBehaviorScoreConfig.defaults,}) {
    return DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
      trips: trips,
      scoreConfig: cfg,
    );
  }

  group('DailyVehicleBehaviorScoreCalculator', () {
    test('قائمة فارغة', () {
      final d = calc(const []);
      expect(d.isScorable, isFalse);
      expect(d.riskLevel, DriverRiskLevel.unknown);
      expect(d.score, 0);
      expect(d.totalTrips, 0);
      expect(d.hasAnyTrips, isFalse);
    });

    test('كل الرحلات غير قابلة للتقييم', () {
      final t1 =
          testTripSegmentForScore(selectionKey: 'a', distanceKm: 0.1, duration: const Duration(minutes: 45));
      final t2 = testTripSegmentForScore(selectionKey: 'b', distanceKm: 0.05);
      final d = calc([t1, t2]);
      expect(d.isScorable, isFalse);
      expect(d.riskLevel, DriverRiskLevel.unknown);
      expect(d.score, 0);
      expect(d.totalTrips, 2);
      expect(d.unscorableTrips, 2);
      expect(d.scorableTrips, 0);
      expect(d.bestTrip, isNull);
      expect(d.worstTrip, isNull);
    });

    test('رحلة واحدة نقية للتقييم', () {
      final t = testTripSegmentForScore(
        selectionKey: 'only',
        distanceKm: 20,
        duration: const Duration(minutes: 40),
      );
      final d = calc([t]);
      expect(d.isScorable, isTrue);
      expect(d.scorableTrips, 1);
      expect(d.bestTrip!.selectionKey, t.selectionKey);
      expect(d.worstTrip!.selectionKey, t.selectionKey);
      expect(d.bestTripScore!.score, d.score);
      expect(d.score, DriverBehaviorScoreCalculator.calculateTripScore(t).score);
    });

    test('متوسط وزني صحيح تقريبًا', () {
      final t1 = testTripSegmentForScore(
        selectionKey: 'w1',
        distanceKm: 10,
      );
      final t2 = testTripSegmentForScore(
        selectionKey: 'w2',
        distanceKm: 30,
      );
      final s1 = DriverBehaviorScoreCalculator.calculateTripScore(t1);
      final s2 = DriverBehaviorScoreCalculator.calculateTripScore(t2);
      expect(s1.isScorable, isTrue, reason: 'fixture t1');
      expect(s2.isScorable, isTrue, reason: 'fixture t2');

      final d = calc([t1, t2]);
      final weight1 = math.max(t1.distanceKm, 1.0);
      final weight2 = math.max(t2.distanceKm, 1.0);
      expect(
        d.weightedAverageRaw,
        closeTo(
          (s1.score * weight1 + s2.score * weight2) / (weight1 + weight2),
          0.02,
        ),
      );
      expect(d.score, d.weightedAverageRaw!.round().clamp(0, 100));
    });

    test('الرحلات غير القابلة لا تُدخل في المتوسط وزنيًا', () {
      final good = testTripSegmentForScore(
        selectionKey: 'g',
        distanceKm: 15,
      );
      final bad = testTripSegmentForScore(
        selectionKey: 'b',
        distanceKm: 0.08,
      );
      final d = calc([bad, good]);
      expect(DriverBehaviorScoreCalculator.calculateTripScore(bad).isScorable, isFalse);
      expect(DriverBehaviorScoreCalculator.calculateTripScore(good).isScorable, isTrue);

      expect(d.scorableTrips, 1);
      expect(d.unscorableTrips, 1);
      expect(d.isScorable, isTrue);
      expect(d.score, DriverBehaviorScoreCalculator.calculateTripScore(good).score);
      expect(d.weightedAverageRaw, isNotNull);
    });

    test('إجماليات المسارات من كل الرحلات', () {
      final t1 = testTripSegmentForScore(
        selectionKey: 'x',
        distanceKm: 12,
        duration: const Duration(minutes: 33),
        stopCount: 2,
        totalStopDuration: const Duration(minutes: 10),
        overspeedCount: 1,
      );
      final t2 = testTripSegmentForScore(
        selectionKey: 'y',
        distanceKm: 0.09,
        duration: const Duration(minutes: 44),
        stopCount: 4,
        totalStopDuration: const Duration(minutes: 5),
        overspeedCount: 3,
      );
      final d = calc([t1, t2]);
      expect(d.totalDistanceKm, closeTo(t1.distanceKm + t2.distanceKm, 1e-9));
      expect(d.totalDuration, t1.duration + t2.duration);
      expect(d.totalStops, 6);
      expect(d.totalStopDuration,
          const Duration(minutes: 15),);
      expect(d.totalOverspeedEvents, 4);
    });

    test('best / worst من القابلة فقط وتعادل يبقي الأول', () {
      final a = testTripSegmentForScore(
        selectionKey: 'a',
        distanceKm: 10,
      );
      final bSame = testTripSegmentForScore(
        selectionKey: 'b',
        distanceKm: 10,
      );
      final d = calc([a, bSame]);

      expect(
        DriverBehaviorScoreCalculator.calculateTripScore(a).score,
        DriverBehaviorScoreCalculator.calculateTripScore(bSame).score,
      );
      expect(d.bestTrip!.selectionKey, 'a');
      expect(d.worstTrip!.selectionKey, 'a');
    });

    test('Score النهائي محصور بين ٠ و١٠٠', () {
      final huge = [
        testTripSegmentForScore(
          selectionKey: 'e',
          overspeedCount: 50,
          maxSpeedKmh: 175,
          stopCount: 60,
          totalStopDuration: const Duration(minutes: 400),
          duration: const Duration(hours: 8),
          distanceKm: 40,
        ),
      ];
      final d = calc(huge);
      if (d.isScorable) {
        expect(d.score, inInclusiveRange(0, 100));
      }
      expect(() => calc(huge), returnsNormally);
    });

    test('تهيئة مخصّصة تؤثر على الدرجة', () {
      final t = testTripSegmentForScore(
        distanceKm: 10,
        overspeedCount: 4,
      );
      final hard = DriverBehaviorScoreConfig.defaults
          .copyWith(overspeedEventPenalty: 12);
      final soft =
          DriverBehaviorScoreConfig.defaults.copyWith(overspeedEventPenalty: 1);
      final dHard = calc([t], cfg: hard);
      final dSoft = calc([t], cfg: soft);
      expect(dHard.isScorable, isTrue);
      expect(dSoft.isScorable, isTrue);
      expect(dSoft.score, greaterThan(dHard.score));
    });

    test('لا استثناء للقائمة بأكملها مع رحلات عادية', () {
      final mixed = [
        testTripSegmentForScore(selectionKey: 'n', distanceKm: 6),
        testTripSegmentForScore(selectionKey: 's', distanceKm: 11),
      ];
      expect(
        () =>
            DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
              trips: mixed,
            ),
        returnsNormally,
      );
    });
  });

  group('riskLevelFromPeriodScore', () {
    const cfg = DriverBehaviorScoreConfig.defaults;
    test('matches config thresholds', () {
      expect(
        DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(93, cfg),
        DriverRiskLevel.excellent,
      );
      expect(
        DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(80, cfg),
        DriverRiskLevel.good,
      );
      expect(
        DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(60, cfg),
        DriverRiskLevel.moderate,
      );
      expect(
        DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(40, cfg),
        DriverRiskLevel.highRisk,
      );
    });
  });

  group('DailyVehicleBehaviorScore.tripScores', () {
    test('maps scores from entries في الترتيب', () {
      final t = testTripSegmentForScore();
      final d = DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [t],
      );
      expect(d.tripScores.length, 1);
      expect(d.tripScores.single, d.tripScoreEntries.single.score);
    });
  });
}
