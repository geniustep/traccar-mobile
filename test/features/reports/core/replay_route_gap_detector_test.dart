import 'package:elmogps/features/map/core/route_polyline_builder.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_route_gap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/core/route_point_fixtures.dart';

void main() {
  final t0 = utc(2024, 6, 1, 8);

  List<RoutePoint> twoPointsWithGap(Duration gap) {
    return [
      testRoutePoint(const LatLng(36.8, 10.13), 40, t0),
      testRoutePoint(
        const LatLng(36.81, 10.14),
        40,
        t0.add(gap),
      ),
    ];
  }

  group('ReplayRouteGapDetector', () {
    test('مسار بدون gaps → 0', () {
      final pts = <RoutePoint>[
        for (var i = 0; i < 5; i++)
          testRoutePoint(
            LatLng(36.8 + i * 0.001, 10.13),
            30,
            t0.add(Duration(minutes: i * 2)),
          ),
      ];
      expect(ReplayRouteGapDetector.detectGaps(pts), isEmpty);
    });

    test('فرق 5 دقائق لا يعتبر gap', () {
      expect(
        ReplayRouteGapDetector.detectGaps(
          twoPointsWithGap(const Duration(minutes: 5)),
        ),
        isEmpty,
      );
    });

    test('فرق 10 دقائق بالضبط لا يعتبر gap (greater than فقط)', () {
      expect(
        ReplayRouteGapDetector.detectGaps(
          twoPointsWithGap(const Duration(minutes: 10)),
        ),
        isEmpty,
      );
    });

    test('فرق 11 دقيقة يعتبر gap', () {
      final gaps = ReplayRouteGapDetector.detectGaps(
        twoPointsWithGap(const Duration(minutes: 11)),
      );
      expect(gaps.length, 1);
      expect(gaps.single.duration, const Duration(minutes: 11));
      expect(gaps.single.indexBefore, 0);
      expect(gaps.single.indexAfter, 1);
    });

    test('عدة gaps في نفس المسار', () {
      final pts = <RoutePoint>[
        testRoutePoint(const LatLng(36.8, 10.13), 30, t0),
        testRoutePoint(
          const LatLng(36.81, 10.13),
          30,
          t0.add(const Duration(minutes: 15)),
        ),
        testRoutePoint(
          const LatLng(36.82, 10.13),
          30,
          t0.add(const Duration(minutes: 20)),
        ),
        testRoutePoint(
          const LatLng(36.83, 10.13),
          30,
          t0.add(const Duration(minutes: 40)),
        ),
      ];
      expect(ReplayRouteGapDetector.detectGaps(pts).length, 2);
    });

    test('نقطة واحدة لا تنتج gap', () {
      expect(
        ReplayRouteGapDetector.detectGaps([
          testRoutePoint(const LatLng(36.8, 10.13), 0, t0),
        ]),
        isEmpty,
      );
    });

    test('نقاط غير مرتبة تُرتَّب قبل الكشف', () {
      final pts = [
        testRoutePoint(
          const LatLng(36.81, 10.13),
          30,
          t0.add(const Duration(minutes: 20)),
        ),
        testRoutePoint(const LatLng(36.8, 10.13), 30, t0),
      ];
      final gaps = ReplayRouteGapDetector.detectGaps(pts);
      expect(gaps.length, 1);
      expect(gaps.single.indexBefore, 0);
      expect(gaps.single.indexAfter, 1);
    });

    test('فرق زمني سلبي أو صفر يُتخطى', () {
      final pts = [
        testRoutePoint(const LatLng(36.8, 10.13), 30, t0),
        testRoutePoint(const LatLng(36.81, 10.13), 30, t0),
        testRoutePoint(
          const LatLng(36.82, 10.13),
          30,
          t0.subtract(const Duration(minutes: 1)),
        ),
      ];
      expect(ReplayRouteGapDetector.detectGaps(pts), isEmpty);
    });

    test('gap detection يعتمد على الوقت وليس ترتيب الفهرس الأصلي', () {
      final lateFirst = [
        testRoutePoint(
          const LatLng(36.81, 10.13),
          30,
          t0.add(const Duration(minutes: 20)),
        ),
        testRoutePoint(const LatLng(36.8, 10.13), 30, t0),
      ];
      final gaps = ReplayRouteGapDetector.detectGaps(lateFirst);
      expect(gaps.length, 1);
      expect(
        gaps.single.duration,
        const Duration(minutes: 20),
      );
    });

    test('segmentation لا تربط عبر gap', () {
      final pts = <RoutePoint>[
        testRoutePoint(const LatLng(36.8, 10.13), 40, t0),
        testRoutePoint(
          const LatLng(36.81, 10.13),
          40,
          t0.add(const Duration(minutes: 1)),
        ),
        testRoutePoint(
          const LatLng(36.9, 10.13),
          40,
          t0.add(const Duration(minutes: 20)),
        ),
        testRoutePoint(
          const LatLng(36.91, 10.13),
          40,
          t0.add(const Duration(minutes: 21)),
        ),
      ];
      final gaps = ReplayRouteGapDetector.detectGaps(pts);
      expect(gaps.length, 1);

      final sorted = ReplayRouteGapDetector.sortByFixTime(pts);
      final runs =
          ReplayRouteGapDetector.splitIntoContinuousRuns(sorted, gaps);
      expect(runs.length, 2);

      final polys = RoutePolylineBuilder.buildReplaySpeedColoredPolylinesRespectingGaps(
        allPoints: pts,
        gaps: gaps,
      );
      expect(polys.length, greaterThan(0));
      for (final p in polys) {
        expect(p.points.length, 2);
        final a = p.points.first;
        final b = p.points.last;
        final bridgesGap = (a.latitude == 36.81 && b.latitude == 36.9) ||
            (a.latitude == 36.9 && b.latitude == 36.81);
        expect(bridgesGap, isFalse);
      }
    });
  });
}
