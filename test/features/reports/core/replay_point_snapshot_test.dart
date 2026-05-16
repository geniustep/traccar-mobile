import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_motion_helper.dart';
import 'package:elmogps/features/reports/core/replay_point_snapshot.dart';
import 'package:elmogps/features/reports/core/replay_route_gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/core/route_point_fixtures.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = AppLocalizations(const Locale('en'));
  });

  RoutePoint fullPoint({
    double speed = 42,
    bool ignition = true,
    String? address = 'Rue Example, Tunis',
    double course = 180,
  }) =>
      testRoutePoint(
        const LatLng(36.8065, 10.1815),
        speed,
        utc(2024, 6, 1, 10, 30, 15),
        course: course,
        ignition: ignition,
      ).copyWithAddress(address);

  group('ReplayPointSnapshotBuilder', () {
    test('نقطة كاملة تعرض الوقت والسرعة والإحداثيات', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(),
        l10n: l10n,
        progress: 0.42,
      );
      expect(snap.timeLabel, '10:30:15');
      expect(snap.speedLabel, contains('42'));
      expect(snap.progressPercent, 42);
      expect(snap.coordinatesLabel, contains('36.8065'));
      expect(snap.courseLabel, '180°');
    });

    test('بدون address لا يعرض عنوانًا', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(address: null),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.hasAddress, isFalse);
      expect(snap.address, isNull);
    });

    test('speed < 5 → Stopped', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(speed: 2),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.isMoving, isFalse);
      expect(snap.movementLabel, l10n.stopped);
    });

    test('speed >= 5 → Moving', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(speed: 5),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.isMoving, isTrue);
      expect(snap.movementLabel, l10n.moving);
    });

    test('ignition true مع showIgnition → Engine on', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(ignition: true),
        l10n: l10n,
        progress: 0,
        showIgnition: true,
      );
      expect(snap.ignitionOn, isTrue);
    });

    test('ignition false مع showIgnition → Engine off', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(ignition: false),
        l10n: l10n,
        progress: 0,
        showIgnition: true,
      );
      expect(snap.ignitionOn, isFalse);
    });

    test('بدون showIgnition لا يعرض ignition', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(ignition: true),
        l10n: l10n,
        progress: 0,
        showIgnition: false,
      );
      expect(snap.ignitionOn, isNull);
    });

    test('course موجود يعرض Direction', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: fullPoint(course: 90),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.courseLabel, '90°');
    });

    test('إحداثيات (0,0) لا تُعرض', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: testRoutePoint(
          const LatLng(0, 0),
          10,
          utc(2024, 1, 1),
        ),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.coordinatesLabel, isNull);
    });

    test('Snapshot من نقطة حقيقية لا يطابق نقطة interpolated', () {
      final t0 = utc(2024, 6, 1, 8);
      final t1 = t0.add(const Duration(minutes: 2));
      final a = testRoutePoint(const LatLng(36.8, 10.13), 40, t0);
      final b = testRoutePoint(const LatLng(36.81, 10.14), 50, t1);
      final visual = interpolateRoutePoint(a, b, 0.5);

      final snapReal = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: b,
        l10n: l10n,
        progress: 1,
      );
      final snapVisual = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: visual,
        l10n: l10n,
        progress: 1,
      );
      expect(snapReal.timeLabel, '08:02:00');
      expect(snapVisual.timeLabel, '08:00:00');
      expect(snapReal.speedLabel, isNot(snapVisual.speedLabel));
    });

    test('بعد فجوة بيانات عند أول نقطة لاحقة', () {
      final t0 = utc(2024, 6, 1, 8);
      final after = testRoutePoint(
        const LatLng(36.9, 10.2),
        30,
        t0.add(const Duration(minutes: 25)),
      );
      final gaps = [
        ReplayRouteGap(
          indexBefore: 0,
          indexAfter: 1,
          gapStartTime: t0,
          gapEndTime: after.fixTime,
          duration: const Duration(minutes: 25),
          markerPosition: const LatLng(36.85, 10.15),
        ),
      ];
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: after,
        l10n: l10n,
        progress: 0.5,
        gaps: gaps,
      );
      expect(snap.afterDataGap, isTrue);
    });
  });
}

extension on RoutePoint {
  RoutePoint copyWithAddress(String? address) => RoutePoint(
        position: position,
        speed: speed,
        course: course,
        fixTime: fixTime,
        ignition: ignition,
        address: address,
        attributes: attributes,
      );
}
