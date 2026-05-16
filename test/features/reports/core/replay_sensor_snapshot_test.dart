import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_point_snapshot.dart';
import 'package:elmogps/features/reports/core/replay_sensor_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/core/route_point_fixtures.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = AppLocalizations(const Locale('en'));
  });

  RoutePoint pointWith(Map<String, dynamic> attrs, {bool ignition = false}) =>
      testRoutePoint(
        const LatLng(36.8, 10.18),
        40,
        utc(2026, 5, 15, 10),
        ignition: ignition,
        attributes: attrs,
      );

  group('RoutePointAttributesMapper', () {
    test('empty attributes yields no rows', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({}),
      );
      expect(snap.isEmpty, isTrue);
    });

    test('fuel percentage 0-100', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'fuel': 72}),
      );
      expect(snap.rows.single.displayValue, '72%');
    });

    test('invalid fuel not shown', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'fuel': 500}),
      );
      expect(snap.isEmpty, isTrue);
    });

    test('battery voltage from power', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'power': 12.4}),
      );
      expect(snap.rows.single.displayValue, '12.4 V');
    });

    test('battery percentage from batteryLevel', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'batteryLevel': 85}),
      );
      expect(snap.rows.single.displayValue, '85%');
    });

    test('GSM rssi dBm', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'rssi': -65}),
      );
      expect(snap.rows.single.displayValue, '-65 dBm');
    });

    test('satellites count', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'sat': 9}),
      );
      expect(snap.rows.single.displayValue, '9');
    });

    test('accuracy in meters', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'accuracy': 8.2}),
      );
      expect(snap.rows.single.displayValue, '8.2 m');
    });

    test('driver name text', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'driverName': 'Ahmed'}),
      );
      expect(snap.rows.single.displayValue, 'Ahmed');
    });

    test('driverId numeric only not shown', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'driver': '12345'}),
      );
      expect(snap.isEmpty, isTrue);
    });

    test('unknown attributes not auto displayed', () {
      final snap = RoutePointAttributesMapper.fromRoutePoint(
        pointWith({'customOdometer': 99999, 'io123': true}),
      );
      expect(snap.isEmpty, isTrue);
    });
  });

  group('ReplaySensorIgnition', () {
    test('direct ignition field used for display', () {
      final p = pointWith({'ignition': false}, ignition: true);
      expect(ReplaySensorIgnition.resolveForDisplay(p), isTrue);
    });
  });

  group('ReplayPointSnapshotBuilder sensors', () {
    test('snapshot includes sensor rows when present', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: pointWith({'fuel': 50}),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.hasSensorRows, isTrue);
      expect(snap.sensorRows.first.displayValue, '50%');
    });

    test('snapshot has no fake sensor values', () {
      final snap = ReplayPointSnapshotBuilder.fromRoutePoint(
        point: pointWith({}),
        l10n: l10n,
        progress: 0,
      );
      expect(snap.hasSensorRows, isFalse);
    });
  });
}
