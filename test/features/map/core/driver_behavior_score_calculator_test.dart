import 'package:elmogps/features/map/core/driver_behavior_score_calculator.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trip_behavior_score_fixtures.dart';

void main() {
  group('DriverBehaviorScoreCalculator', () {
    test('مدة أقل من الحد الأدنى للقابلية → غير قابلة للتقييم', () {
      final trip = testTripSegmentForScore(
        distanceKm: 5,
        duration: const Duration(minutes: 2),
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      expect(r.isScorable, isFalse);
    });

    test('رحلة قصيرة جدًا مسافةًا → غير قابلة للتقييم', () {
      final trip = testTripSegmentForScore(
        distanceKm: 0.2,
        duration: const Duration(minutes: 40),
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      expect(r.isScorable, isFalse);
      expect(r.score, 0);
      expect(r.riskLevel, DriverRiskLevel.unknown);
      expect(r.factors.any((f) => f.code == 'shortTrip'), isTrue);
    });

    test('رحلة نظيفة → درجة عالية ومستوى ممتاز أو جيد', () {
      final trip = testTripSegmentForScore(
        distanceKm: 12,
        duration: const Duration(minutes: 45),
        maxSpeedKmh: 70,
        avgSpeedKmh: 42,
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      expect(r.isScorable, isTrue);
      expect(r.score, greaterThanOrEqualTo(90));
      expect(
        r.riskLevel == DriverRiskLevel.excellent ||
            r.riskLevel == DriverRiskLevel.good,
        isTrue,
      );
      expect(r.factors.any((f) => f.code == 'cleanTrip'), isTrue);
    });

    test('overspeed واحد يخفض الدرجة', () {
      final clean = testTripSegmentForScore();
      final withOv = testTripSegmentForScore(
        overspeedCount: 1,
        maxSpeedKmh: 95,
      );

      final r0 =
          DriverBehaviorScoreCalculator.calculateTripScore(clean);
      final r1 =
          DriverBehaviorScoreCalculator.calculateTripScore(withOv);
      expect(r1.score, lessThan(r0.score));
    });

    test('عدة تجاوزات تخفض الدرجة بشكل أوضح', () {
      final tLight = testTripSegmentForScore(overspeedCount: 2, maxSpeedKmh: 95);
      final tHeavy = testTripSegmentForScore(overspeedCount: 8, maxSpeedKmh: 95);
      final rLight = DriverBehaviorScoreCalculator.calculateTripScore(tLight);
      final rHeavy = DriverBehaviorScoreCalculator.calculateTripScore(tHeavy);
      expect(rHeavy.score, lessThan(rLight.score));
    });

    test('سرعة قصوى خطيرة مع تحليل → عامل heavyOverspeed', () {
      final trip = testTripSegmentForScore(
        overspeedCount: 1,
        maxSpeedKmh: 135,
      );
      final analysis = RouteEventAnalysisResult(
        stops: const [],
        overspeeds: [
          RouteOverspeedEvent(
            time: DateTime.utc(2024),
            speed: 130,
            latitude: 10,
            longitude: 11,
          ),
        ],
        ignitions: const [],
        summary: const RouteEventSummary(
          stopCount: 0,
          totalStopDuration: Duration.zero,
          overspeedCount: 1,
          maxSpeed: 130,
          ignitionTransitionCount: 0,
        ),
        ignitionDataLikelyPresent: false,
      );

      final r = DriverBehaviorScoreCalculator.calculateTripScore(
        trip,
        analysis: analysis,
      );

      expect(
        r.factors.any((f) => f.code == 'heavyOverspeed'),
        isTrue,
      );
    });

    test('وقفات زائدة → عقوبة توقّف محدودة', () {
      final low = testTripSegmentForScore(stopCount: 1, distanceKm: 8);
      final high = testTripSegmentForScore(stopCount: 25, distanceKm: 8);
      final rLow = DriverBehaviorScoreCalculator.calculateTripScore(low);
      final rHigh = DriverBehaviorScoreCalculator.calculateTripScore(high);

      expect(rHigh.breakdown.stopPenalty, greaterThan(rLow.breakdown.stopPenalty));
      expect(rHigh.breakdown.stopPenalty, lessThanOrEqualTo(20));
    });

    test('بيانات إشعال غير متاحة → لا عقوبة إشعال', () {
      final trip = testTripSegmentForScore(
        hasIgnitionData: false,
        ignitionOnCount: 99,
        ignitionOffCount: 99,
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      expect(r.breakdown.ignitionPenalty, 0);
      expect(r.factors.where((f) => f.code == 'ignitionTransitions'), isEmpty);
    });

    test('انتقالات إشعال كثيرة مع بيانات → عقوبة خفيفة', () {
      final trip = testTripSegmentForScore(
        hasIgnitionData: true,
        ignitionOnCount: 5,
        ignitionOffCount: 5,
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      expect(r.breakdown.ignitionPenalty, greaterThan(0));
      expect(
        r.factors.any((f) => f.code == 'ignitionTransitions'),
        isTrue,
      );
    });

    test('الدرجة محصورة بين ٠ و١٠٠', () {
      final extreme = testTripSegmentForScore(
        overspeedCount: 50,
        maxSpeedKmh: 160,
        stopCount: 50,
        totalStopDuration: const Duration(minutes: 180),
        duration: const Duration(minutes: 240),
      );
      final r =
          DriverBehaviorScoreCalculator.calculateTripScore(extreme);
      expect(r.score, inInclusiveRange(0, 100));
    });

    test('مجموع العقوبات لا يتجاوز السقف', () {
      const cfg = DriverBehaviorScoreConfig.defaults;
      final extreme = testTripSegmentForScore(
        overspeedCount: 100,
        maxSpeedKmh: 180,
        stopCount: 200,
        totalStopDuration: const Duration(minutes: 900),
        duration: const Duration(hours: 10),
      );
      final r = DriverBehaviorScoreCalculator.calculateTripScore(
        extreme,
        config: cfg,
      );

      expect(
        r.breakdown.totalPenalty,
        lessThanOrEqualTo(cfg.maxTotalPenalty),
      );
    });

    test('تهيئة مخصّصة تغيّر الدرجة', () {
      final trip =
          testTripSegmentForScore(overspeedCount: 3, maxSpeedKmh: 95);

      final soft = DriverBehaviorScoreConfig.defaults
          .copyWith(overspeedEventPenalty: 1);
      final rDef =
          DriverBehaviorScoreCalculator.calculateTripScore(trip);
      final rSoft = DriverBehaviorScoreCalculator.calculateTripScore(
        trip,
        config: soft,
      );

      expect(rSoft.score, greaterThan(rDef.score));
    });

    test('رحلة غير صالحة لا ترمي استثناء', () {
      final bad = TripSegment(
        selectionKey: 'bad',
        vehicleId: 'v',
        index: 1,
        startTime: DateTime.utc(2024),
        endTime: DateTime.utc(2024),
        duration: Duration.zero,
        startPosition:
            testTripSegmentForScore().startPosition,
        endPosition: testTripSegmentForScore().endPosition,
        distanceKm: double.nan,
        maxSpeedKmh: 40,
        avgSpeedKmh: 30,
        stopCount: 0,
        totalStopDuration: Duration.zero,
        overspeedCount: 0,
        ignitionOnCount: 0,
        ignitionOffCount: 0,
        hasIgnitionData: false,
      );

      expect(
        () => DriverBehaviorScoreCalculator.calculateTripScore(bad),
        returnsNormally,
      );

      expect(
        DriverBehaviorScoreCalculator.calculateTripScore(bad).isScorable,
        isFalse,
      );
    });

    test('behaviorScore على الـ extension يطابق الحاسبة', () {
      final trip = testTripSegmentForScore();
      final a = DriverBehaviorScoreCalculator.calculateTripScore(trip);
      final b = trip.behaviorScore();
      expect(b.score, a.score);
      expect(b.isScorable, a.isScorable);
    });
  });
}
