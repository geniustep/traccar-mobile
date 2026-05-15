import 'dart:math' as math;

import 'package:elmogps/features/map/core/daily_behavior_score_calculator.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_calculator.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_config.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fleet_intelligence_fixtures.dart';
import 'trip_behavior_score_fixtures.dart';

void main() {
  FleetIntelligenceMetrics calc(
    List<FleetVehicleTripInput> vehicles, {
    DriverBehaviorScoreConfig scoreCfg = DriverBehaviorScoreConfig.defaults,
    FleetIntelligenceMetricsConfig metricsCfg =
        FleetIntelligenceMetricsConfig.defaults,
  }) =>
      FleetIntelligenceMetricsCalculator.calculate(
        vehicles: vehicles,
        scoreConfig: scoreCfg,
        metricsConfig: metricsCfg,
      );

  group('FleetIntelligenceMetricsCalculator', () {
    test('قائمة مركبات فارغة', () {
      final m = calc(const []);
      expect(m.totalVehicles, 0);
      expect(m.isScorable, isFalse);
      expect(m.averageScore, 0);
      expect(m.vehicleSummaries, isEmpty);
      expect(m.riskDistribution.unknownCount, 0);
      expect(m.bestVehicleSummary, isNull);
      expect(m.vehiclesNeedingAttention, isEmpty);
    });

    test('مركبات بدون رحلات', () {
      final m = calc([
        fleetVehicleInput(id: 'a'),
        fleetVehicleInput(id: 'b', name: 'B'),
      ]);
      expect(m.totalVehicles, 2);
      expect(m.activeVehicles, 0);
      expect(m.inactiveVehicles, 2);
      expect(m.vehiclesWithTrips, 0);
      expect(m.isScorable, isFalse);
      expect(m.averageScore, 0);
      expect(m.riskDistribution.unknownCount, 2);
      expect(m.mostActiveVehicleSummary, isNull);
      expect(m.mostOverspeedVehicleSummary, isNull);
      expect(m.mostStoppedVehicleSummary, isNull);
      expect(m.totalTrips, 0);
      expect(m.vehicleSummaries.length, 2);
      for (final s in m.vehicleSummaries) {
        expect(s.isActive, isFalse);
        expect(s.isPeriodScorable, isFalse);
        expect(s.periodScore, isNull);
      }
    });

    test('مركبة واحدة برحلات نظيفة', () {
      final trip = testTripSegmentForScore(
        vehicleId: 'v1',
        selectionKey: 's1',
        distanceKm: 20,
        duration: const Duration(minutes: 40),
      );
      final m = calc([fleetVehicleInput(id: 'v1', trips: [trip])]);
      expect(m.totalVehicles, 1);
      expect(m.vehiclesWithTrips, 1);
      expect(m.activeVehicles, 1);
      expect(m.isScorable, isTrue);
      expect(m.totalTrips, 1);
      final daily =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [trip],
      );
      expect(m.averageScore, daily.score);
      expect(m.bestVehicleSummary!.vehicleId, 'v1');
      expect(m.worstVehicleSummary!.vehicleId, 'v1');
      expect(m.mostActiveVehicleSummary!.totalDistanceKm, trip.distanceKm);
      expect(m.riskDistribution.excellentCount + m.riskDistribution.goodCount,
          greaterThanOrEqualTo(1),);
    });

    test('عدة مركبات بدرجات مختلفة — best / worst / متوسط وزني', () {
      final goodTrip = testTripSegmentForScore(
        vehicleId: 'g',
        selectionKey: 'g1',
        distanceKm: 30,
      );
      final badTrip = testTripSegmentForScore(
        vehicleId: 'x',
        selectionKey: 'x1',
        distanceKm: 12,
        overspeedCount: 10,
        maxSpeedKmh: 135,
      );
      final m = calc([
        fleetVehicleInput(id: 'good', trips: [goodTrip]),
        fleetVehicleInput(id: 'bad', trips: [badTrip]),
      ]);
      expect(m.isScorable, isTrue);
      final goodDaily =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [goodTrip],
      );
      final badDaily =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [badTrip],
      );
      expect(goodDaily.isScorable, isTrue);
      expect(badDaily.isScorable, isTrue);

      expect(m.bestVehicleSummary!.periodScore!, greaterThan(
        m.worstVehicleSummary!.periodScore!,
      ),);

      final w1 = math.max(goodTrip.distanceKm, 1.0);
      final w2 = math.max(badTrip.distanceKm, 1.0);
      final expectedRaw = (goodDaily.score * w1 + badDaily.score * w2) /
          (w1 + w2);
      expect(m.weightedAverageRaw, closeTo(expectedRaw, 0.02));
      expect(
        m.averageScore,
        m.weightedAverageRaw!.round().clamp(0, 100),
      );
    });

    test('متوسط الأسطول لا يدخل مركبات unknown', () {
      final goodTrip = testTripSegmentForScore(
        selectionKey: 'ok',
        distanceKm: 25,
      );
      final shortTrip = testTripSegmentForScore(
        selectionKey: 'short',
        distanceKm: 0.06,
      );
      final m = calc([
        fleetVehicleInput(id: 'scorable', trips: [goodTrip]),
        fleetVehicleInput(id: 'unscorable', trips: [shortTrip]),
      ]);
      expect(m.isScorable, isTrue);

      final onlyGood =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [goodTrip],
      );
      expect(onlyGood.isScorable, isTrue);

      expect(m.averageScore, onlyGood.score);
      expect(m.vehicleSummaries.any((s) =>
          s.vehicleId == 'unscorable' && !s.isPeriodScorable,), isTrue,);
      expect(m.riskDistribution.unknownCount, greaterThanOrEqualTo(1));
    });

    test('mostActiveVehicle مسافة أكبر، وربط التعادل بالأول', () {
      final tFar = testTripSegmentForScore(
        vehicleId: 'far',
        selectionKey: 'f1',
        distanceKm: 100,
      );
      final tNear = testTripSegmentForScore(
        vehicleId: 'near',
        selectionKey: 'n1',
        distanceKm: 5,
      );
      final m = calc([
        fleetVehicleInput(id: 'near', trips: [tNear]),
        fleetVehicleInput(id: 'far', trips: [tFar]),
      ]);
      expect(m.mostActiveVehicleSummary!.vehicleId, 'far');
    });

    test('mostOverspeedVehicle', () {
      final tQuiet = testTripSegmentForScore(
        selectionKey: 'q',
        overspeedCount: 0,
      );
      final tBusy = testTripSegmentForScore(
        selectionKey: 'b',
        overspeedCount: 7,
        maxSpeedKmh: 115,
      );
      final m = calc([
        fleetVehicleInput(id: 'quiet', trips: [tQuiet]),
        fleetVehicleInput(id: 'busy', trips: [tBusy]),
      ]);
      expect(m.mostOverspeedVehicleSummary!.vehicleId, 'busy');
    });

    test('mostStoppedVehicle حسب مجموع مدة التوقّف', () {
      final tShortStop = testTripSegmentForScore(
        selectionKey: 'a',
        totalStopDuration: const Duration(minutes: 10),
      );
      final tLongStop = testTripSegmentForScore(
        selectionKey: 'z',
        totalStopDuration: const Duration(hours: 2),
      );
      final m = calc([
        fleetVehicleInput(id: 'vA', trips: [tShortStop]),
        fleetVehicleInput(id: 'vZ', trips: [tLongStop]),
      ]);
      expect(m.mostStoppedVehicleSummary!.vehicleId, 'vZ');
    });

    test('riskDistribution وفق مستويات الفترة لكل مركبة', () {
      final m = calc([
        fleetVehicleInput(id: 'idle'),
      ]);
      expect(m.riskDistribution.unknownCount, 1);
      expect(m.riskDistribution.total, m.totalVehicles);
    });

    test('needsAttention — خطر عالٍ و moderate مع تجاوزات كافية', () {
      final highRiskTrip = testTripSegmentForScore(
        selectionKey: 'hr',
        distanceKm: 15,
        overspeedCount: 12,
        maxSpeedKmh: 135,
      );
      final moderateOverspeedTrip = testTripSegmentForScore(
        selectionKey: 'mo',
        distanceKm: 15,
        overspeedCount: 8,
        maxSpeedKmh: 95,
      );
      final modDaily =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [moderateOverspeedTrip],
      );
      expect(modDaily.riskLevel, DriverRiskLevel.moderate,
          reason: 'Fixture should land in moderate band for overspeedAttention rule.',);

      final m = calc([
        fleetVehicleInput(id: 'risky', trips: [highRiskTrip]),
        fleetVehicleInput(id: 'modOv', trips: [moderateOverspeedTrip]),
      ]);
      final ids =
          m.vehiclesNeedingAttention.map((e) => e.vehicleId).toSet();
      expect(ids, contains('risky'));
      expect(ids, contains('modOv'));
    });

    test('إجماليات trips/distance/duration/stops/overspeed', () {
      final t1 = testTripSegmentForScore(
        selectionKey: '1',
        distanceKm: 5,
        duration: const Duration(minutes: 20),
        stopCount: 1,
        totalStopDuration: const Duration(minutes: 3),
        overspeedCount: 2,
      );
      final t2 = testTripSegmentForScore(
        selectionKey: '2',
        distanceKm: 7,
        duration: const Duration(minutes: 25),
        stopCount: 2,
        totalStopDuration: const Duration(minutes: 4),
        overspeedCount: 1,
      );
      final m = calc([
        fleetVehicleInput(id: 'one', trips: [t1, t2]),
      ]);
      expect(m.totalTrips, 2);
      expect(m.totalDistanceKm, closeTo(12.0, 1e-9));
      expect(
        m.totalDrivingDuration,
        const Duration(minutes: 45),
      );
      expect(m.totalStops, 3);
      expect(m.totalStopDuration,
          const Duration(minutes: 7),);
      expect(m.totalOverspeedEvents, 3);
    });

    test('درجة المتوسط المحصورة 0–100', () {
      final m = calc([
        fleetVehicleInput(
          id: 'solo',
          trips: [
            testTripSegmentForScore(selectionKey: 'x', distanceKm: 10),
          ],
        ),
      ]);
      expect(m.averageScore, inInclusiveRange(0, 100));
    });

    test('تهيئة metrics تغيّر عتبة الانتباه بالدرجة', () {
      final midTrip = testTripSegmentForScore(
        selectionKey: 'mid',
        distanceKm: 18,
        overspeedCount: 3,
        maxSpeedKmh: 100,
      );
      final daily =
          DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
        trips: [midTrip],
      );
      expect(daily.isScorable, isTrue);
      final score = daily.score;

      final loose = calc(
        [fleetVehicleInput(id: 'v', trips: [midTrip])],
        metricsCfg: FleetIntelligenceMetricsConfig(
          attentionScoreAtOrBelow: score + 5,
        ),
      );
      final tight = calc(
        [fleetVehicleInput(id: 'v', trips: [midTrip])],
        metricsCfg: FleetIntelligenceMetricsConfig(
          attentionScoreAtOrBelow: score - 5,
        ),
      );
      expect(loose.vehiclesNeedingAttention.length,
          greaterThanOrEqualTo(tight.vehiclesNeedingAttention.length),);
    });

    test('رحلات غير قابلة للتقييم فقط — isScorable=false و unknown', () {
      final t1 = testTripSegmentForScore(selectionKey: 'a', distanceKm: 0.05);
      final t2 = testTripSegmentForScore(selectionKey: 'b', distanceKm: 0.08);
      final m = calc([fleetVehicleInput(id: 'v', trips: [t1, t2])]);
      expect(m.isScorable, isFalse);
      expect(m.averageScore, 0);
      expect(m.weightedAverageRaw, isNull);
      expect(m.bestVehicleSummary, isNull);
      expect(m.worstVehicleSummary, isNull);
      expect(m.riskDistribution.unknownCount, 1);
      expect(m.totalTrips, 2);
      expect(m.totalDistanceKm, greaterThan(0));
    });

    test('لا يُرمى استثناء مع TripSegment ناقصة', () {
      final bad = TripSegment(
        selectionKey: 'bad',
        vehicleId: 'v',
        index: 1,
        startTime: DateTime.utc(2024),
        endTime: DateTime.utc(2024),
        duration: Duration.zero,
        startPosition: const LatLng(0, 0),
        endPosition: const LatLng(0, 0),
        distanceKm: double.nan,
        maxSpeedKmh: 10,
        avgSpeedKmh: 5,
        stopCount: -1,
        overspeedCount: -1,
        totalStopDuration: Duration.zero,
        ignitionOnCount: 0,
        ignitionOffCount: 0,
        hasIgnitionData: false,
      );
      expect(
        () => calc([fleetVehicleInput(id: 'v', trips: [bad])]),
        returnsNormally,
      );
    });
  });
}
