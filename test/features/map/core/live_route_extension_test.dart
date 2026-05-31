import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:elmogps/features/map/core/live_route_extension.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';

RoutePoint _pt(
  DateTime fix,
  double lat,
  double lon, {
  double speed = 10,
}) =>
    RoutePoint(
      position: LatLng(lat, lon),
      speed: speed,
      course: 0,
      fixTime: fix,
      ignition: true,
    );

VehicleEntity _vehicle({
  required DateTime lastUpdate,
  double lat = 35.47,
  double lon = -6.03,
  double speed = 20,
}) =>
    VehicleEntity(
      id: '11',
      name: 'V11',
      plateNumber: 'P',
      type: 'car',
      status: 'moving',
      speed: speed,
      latitude: lat,
      longitude: lon,
      address: null,
      lastUpdate: lastUpdate,
      ignition: true,
      batteryVoltage: null,
      fuelLevel: null,
      driverName: null,
      groupId: null,
    );

void main() {
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final t0 = dayStart.add(const Duration(hours: 8));
  final t1 = dayStart.add(const Duration(hours: 9));
  final t2 = dayStart.add(const Duration(hours: 10));

  group('LiveRouteExtension', () {
    test('newer live position extends combined polyline points', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0), _pt(t1, 35.1, -6.1)],
        rangeFrom: dayStart,
        rangeTo: now,
      );

      final ok = ext.tryAppendFromVehicle(
        vehicle: _vehicle(
          lastUpdate: now.subtract(const Duration(minutes: 1)),
          lat: 35.2,
          lon: -6.2,
        ),
        liveModeEnabled: true,
      );

      expect(ok, isTrue);
      expect(ext.combinedPoints.length, 3);
      expect(ext.combinedPoints.last.position.latitude, 35.2);
    });

    test('stale fixTime is not appended', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0), _pt(t2, 35.2, -6.2)],
        rangeFrom: dayStart,
        rangeTo: now,
      );

      final ok = ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: t1, lat: 35.15, lon: -6.15),
        liveModeEnabled: true,
      );

      expect(ok, isFalse);
      expect(ext.combinedPoints.length, 2);
    });

    test('duplicate position is not appended', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0), _pt(t1, 35.1, -6.1)],
        rangeFrom: dayStart,
        rangeTo: now,
      );

      final ok = ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: now.subtract(const Duration(minutes: 1)), lat: 35.1, lon: -6.1),
        liveModeEnabled: true,
      );

      expect(ok, isFalse);
      expect(ext.liveAppendCount, 0);
    });

    test('time range change clears live extension on reload', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0)],
        rangeFrom: dayStart,
        rangeTo: now,
      );
      ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: now.subtract(const Duration(minutes: 1)), lat: 35.2, lon: -6.2),
        liveModeEnabled: true,
      );
      expect(ext.liveAppendCount, 1);

      final pastTo = DateTime(2026, 5, 30, 23, 59);
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(DateTime(2026, 5, 30, 12), 34.0, -6.0)],
        rangeFrom: DateTime(2026, 5, 30),
        rangeTo: pastTo,
      );

      expect(ext.liveAppendCount, 0);
      expect(ext.combinedPoints.length, 1);
    });

    test('resetLiveExtension clears append buffer', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0)],
        rangeFrom: dayStart,
        rangeTo: now,
      );
      ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: now.subtract(const Duration(minutes: 1)), lat: 35.2, lon: -6.2),
        liveModeEnabled: true,
      );
      ext.resetLiveExtension(deviceId: '11', reason: 'manual_refresh');
      expect(ext.liveAppendCount, 0);
    });

    test('live_mode_disabled skips append', () {
      final ext = LiveRouteExtension(screen: 'Test');
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(t0, 35.0, -6.0)],
        rangeFrom: dayStart,
        rangeTo: now,
      );

      final ok = ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: now.subtract(const Duration(minutes: 1)), lat: 35.2, lon: -6.2),
        liveModeEnabled: false,
      );

      expect(ok, isFalse);
    });

    test('historical-only past window rejects live append', () {
      final ext = LiveRouteExtension(screen: 'Test');
      final from = DateTime(2026, 5, 20);
      final to = DateTime(2026, 5, 21, 23, 59);
      ext.loadHistorical(
        deviceId: '11',
        points: [_pt(from, 35.0, -6.0)],
        rangeFrom: from,
        rangeTo: to,
      );

      expect(
        LiveRouteExtension.allowsLiveExtension(
          rangeFrom: from,
          rangeTo: to,
          now: now,
        ),
        isFalse,
      );

      final ok = ext.tryAppendFromVehicle(
        vehicle: _vehicle(lastUpdate: now, lat: 35.2, lon: -6.2),
        liveModeEnabled: true,
      );
      expect(ok, isFalse);
    });
  });
}
