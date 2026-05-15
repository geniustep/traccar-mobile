import 'dart:math' as math;

import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:elmogps/features/map/core/trip_segment_summary.dart';
import 'package:elmogps/features/map/core/trip_segmenter.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_point_fixtures.dart';

void main() {
  const vid = '42';

  group('TripSegmenter', () {
    test('مسار فارغ → لا رحلات', () {
      expect(
        TripSegmenter.build(
          vehicleId: vid,
          points: const [],
          config: testSeg,
          thresholds: testRi,
        ),
        isEmpty,
      );
    });

    test('نقطة واحدة → لا رحلة', () {
      final trips = TripSegmenter.build(
        vehicleId: vid,
        points: [
          testRoutePoint(const LatLng(36.8, 10.13), 30, utc(2024, 6, 1, 10)),
        ],
        config: testSeg,
        thresholds: testRi,
      );
      expect(trips, isEmpty);
    });

    test('حركة مستمرة → رحلة واحدة', () {
      final t0 = utc(2024, 6, 1, 8);
      final pts = <RoutePoint>[
        for (var i = 0; i < 30; i++)
          testRoutePoint(
            LatLng(36.8 + i * 0.002, 10.13),
            50,
            t0.add(Duration(minutes: i)),
          ),
      ];
      final trips = TripSegmenter.build(
        vehicleId: vid,
        points: pts,
        thresholds: testRi,
      );
      expect(trips.length, 1);
      expect(trips.single.index, 1);
      expect(trips.single.distanceKm, greaterThan(0.15));
    });

    test('توقف طويل بين حركتين → رحلتان', () {
      final t0 = utc(2024, 6, 1, 7);
      final cfg = TripSegmentationConfig.defaults.copyWith(
        stopGapDuration: const Duration(minutes: 10),
        maxPointGapDuration: const Duration(minutes: 60),
      );
      final pts = <RoutePoint>[
        for (var i = 0; i < 5; i++)
          testRoutePoint(
            LatLng(36.8 + i * 0.002, 10.13),
            55,
            t0.add(Duration(minutes: i)),
          ),
        for (var j = 0; j < 12; j++)
          testRoutePoint(
            LatLng(36.81, 10.13),
            0,
            t0.add(Duration(minutes: 5 + j)),
          ),
        for (var k = 1; k <= 5; k++)
          testRoutePoint(
            LatLng(36.81 + k * 0.004, 10.14),
            60,
            t0.add(Duration(minutes: 5 + 12 + k)),
          ),
      ];

      final trips = TripSegmenter.build(
        vehicleId: vid,
        points: pts,
        config: cfg,
        thresholds: testRi,
      );
      expect(trips.length, 2);
    });

    test('فجوة زمنية كبيرة بين نقطتين → شقّان', () {
      final t0 = utc(2024, 6, 1, 6);
      final cfg = TripSegmentationConfig.defaults.copyWith(
        maxPointGapDuration: const Duration(minutes: 20),
      );
      final pts = [
        testRoutePoint(const LatLng(36.80, 10.13), 50, t0),
        testRoutePoint(
          const LatLng(36.805, 10.131),
          50,
          t0.add(const Duration(minutes: 8)),
        ),
        testRoutePoint(
          const LatLng(36.90, 10.20),
          50,
          t0.add(const Duration(minutes: 35)),
        ),
        testRoutePoint(
          const LatLng(36.91, 10.21),
          50,
          t0.add(const Duration(minutes: 40)),
        ),
      ];

      expect(
        TripSegmenter.build(vehicleId: vid, points: pts, config: cfg, thresholds: testRi)
            .length,
        2,
      );
    });

    test('رحلة قصيرة بالمدّة تُرفض', () {
      final t0 = utc(2024, 6, 1, 9);
      final pts = [
        testRoutePoint(const LatLng(36.80, 10.13), 55, t0),
        testRoutePoint(
          const LatLng(36.820, 10.14),
          55,
          t0.add(const Duration(minutes: 1)),
        ),
      ];
      final trips = TripSegmenter.build(
        vehicleId: vid,
        points: pts,
        config: TripSegmentationConfig.defaults.copyWith(
          minTripDuration: const Duration(minutes: 10),
          maxPointGapDuration: const Duration(hours: 4),
        ),
        thresholds: testRi,
      );
      expect(trips, isEmpty);
    });

    test('مسافة قصيرة جداً تُرفض', () {
      final t0 = utc(2024, 6, 1, 11);
      final pts = [
        testRoutePoint(const LatLng(36.80000001, 10.130000001), 10, t0),
        testRoutePoint(
          const LatLng(36.80000002, 10.130000002),
          10,
          t0.add(const Duration(minutes: 30)),
        ),
      ];
      expect(
        TripSegmenter.build(vehicleId: vid, points: pts, thresholds: testRi),
        isEmpty,
      );
    });

    test('tripPathDistanceKm قريب من مجموع Haversine', () {
      final pts = [
        testRoutePoint(const LatLng(0, 10), 5, utc(2024, 1, 1)),
        testRoutePoint(const LatLng(0, 11), 5, utc(2024, 1, 1, 0, 5)),
        testRoutePoint(const LatLng(1, 11), 5, utc(2024, 1, 1, 0, 10)),
      ];
      var manual = 0.0;
      for (var i = 1; i < pts.length; i++) {
        manual += _haversineKm(pts[i - 1].position, pts[i].position);
      }
      expect(tripPathDistanceKm(pts), closeTo(manual, 0.02));
    });

    test('ملخص الرحلة + أحداث التوقف/التجاوز داخل الرحلة', () {
      final t0 = utc(2024, 6, 2, 12);
      final moving = [
        testRoutePoint(const LatLng(10, 12), 30, t0.add(const Duration(minutes: 0))),
        testRoutePoint(const LatLng(10.04, 12), 30, t0.add(const Duration(minutes: 2))),
      ];
      final pauseStart = moving.last.fixTime.add(const Duration(minutes: 1));
      final pause = [
        for (var q = 0; q < 8; q++)
          testRoutePoint(
            LatLng(10.04 + 0.0001 * q, 12),
            0,
            pauseStart.add(Duration(minutes: q)),
          ),
      ];
      final resume = [
        testRoutePoint(
          const LatLng(10.10, 12.01),
          92,
          pause.last.fixTime.add(const Duration(minutes: 1)),
        ),
        testRoutePoint(
          const LatLng(10.20, 12.03),
          93,
          pause.last.fixTime.add(const Duration(minutes: 2)),
        ),
      ];
      final cfg = TripSegmentationConfig.defaults.copyWith(
        minTripDistanceKm: 0.001,
        minTripDuration: const Duration(seconds: 5),
        stopGapDuration: const Duration(minutes: 45),
        maxPointGapDuration: const Duration(days: 1),
      );

      final th = RouteIntelligenceThresholds(
        minStopDuration: const Duration(minutes: 4),
        overspeedThresholdKmh: 85,
        stopSpeedEnterKmh: 3,
        stopSpeedExitKmh: 5,
      );

      final trips = TripSegmenter.build(
        vehicleId: vid,
        points: [...moving, ...pause, ...resume],
        config: cfg,
        thresholds: th,
      );
      expect(trips.length, 1);
      final seg = trips.single;
      expect(seg.duration >= const Duration(minutes: 11), isTrue);
      expect(seg.stopCount, greaterThanOrEqualTo(1));
      expect(seg.overspeedCount, greaterThanOrEqualTo(1));
      expect(seg.avgSpeedKmh, greaterThan(0));
      expect(seg.maxSpeedKmh, greaterThanOrEqualTo(90));
    });
  });
}

/// أخف عتبات للاختبارات (أقصر مدّة توقف في التحليل).
final testRi = RouteIntelligenceThresholds(
  minStopDuration: const Duration(seconds: 30),
  overspeedThresholdKmh: 80,
);

/// عتبات تقسيم مريحة للاختبارات (مسافة دنيا منخفضة، فجوة نقاط واسعة).
final testSeg = TripSegmentationConfig.defaults.copyWith(
  minTripDistanceKm: 0.001,
  maxPointGapDuration: const Duration(days: 1),
);

double _haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2).toDouble() +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2).toDouble();
  final c = 2 * math.asin(math.sqrt(math.min(1.0, h)));
  return r * c;
}
