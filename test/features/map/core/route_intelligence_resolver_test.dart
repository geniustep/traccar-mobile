import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/features/map/core/route_intelligence_threshold_resolution.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds_resolver.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';

VehicleEntity _v(
  String id, {
  Map<String, dynamic>? deviceAttributes,
  String? groupId,
}) {
  return VehicleEntity(
    id: id,
    name: 'Test',
    plateNumber: 'T-1',
    type: 'car',
    status: 'offline',
    speed: 0,
    latitude: 0,
    longitude: 0,
    address: null,
    lastUpdate: null,
    ignition: false,
    batteryVoltage: null,
    fuelLevel: null,
    driverName: null,
    groupId: groupId,
    deviceAttributes: deviceAttributes ?? const {},
  );
}

void main() {
  group('resolveRouteIntelligenceThresholdsForVehicle', () {
    test('empty vehicle id → defaults', () {
      expect(
        resolveRouteIntelligenceThresholdsForVehicle(
          vehicleId: '',
          liveVehicle: _v('99'),
          fleet: [_v('99')],
        ),
        RouteIntelligenceThresholds.defaults,
      );
    });

    test('liveVehicle wins with attributes', () {
      final live = _v(
        '7',
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
        },
      );
      final fleet = [
        _v(
          '7',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 40,
          },
        ),
      ];
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '7',
        liveVehicle: live,
        fleet: fleet,
      );
      expect(r.overspeedThresholdKmh, 90);
    });

    test('no live → uses fleet match', () {
      final fleet = [
        _v(
          '3',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 77,
          },
        ),
      ];
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '3',
        liveVehicle: null,
        fleet: fleet,
      );
      expect(r.overspeedThresholdKmh, 77);
    });

    test('no live and vehicle missing from fleet → defaults', () {
      expect(
        resolveRouteIntelligenceThresholdsForVehicle(
          vehicleId: 'missing',
          liveVehicle: null,
          fleet: [_v('other')],
        ).overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
    });

    test('group supplies missing fields; device overrides group overspeed', () {
      final v = _v(
        '1',
        groupId: '10',
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
        },
      );
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '1',
        liveVehicle: v,
        fleet: null,
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 5,
        },
      );
      expect(r.overspeedThresholdKmh, 75);
      expect(r.minStopDuration, const Duration(minutes: 5));
    });

    test('device-only when groupAttrs null uses defaults remainder', () {
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '5',
        liveVehicle: _v(
          '5',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.detectStops: false,
          },
        ),
        fleet: null,
        groupAttributes: null,
      );
      expect(r.detectStops, false);
      expect(r.overspeedThresholdKmh,
          RouteIntelligenceThresholds.defaults.overspeedThresholdKmh);
    });

    test('group-only layer when device empty sparse', () {
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '6',
        liveVehicle: _v('6', deviceAttributes: const {}),
        fleet: null,
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: '88',
        },
      );
      expect(r.overspeedThresholdKmh, 88);
    });

    test('corrupted group attrs do not throw; device wins valid parts', () {
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '8',
        liveVehicle: _v(
          '8',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
          },
        ),
        fleet: null,
        groupAttributes: {
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 'xx',
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 'bad',
        },
      );
      expect(r.minStopDuration,
          RouteIntelligenceThresholds.defaults.minStopDuration);
      expect(r.overspeedThresholdKmh, 70);
    });

    test('empty vehicle id ignores user/local overlays', () {
      expect(
        resolveRouteIntelligenceThresholdsForVehicle(
          vehicleId: '',
          liveVehicle: _v('1'),
          fleet: [_v('1')],
          userAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 50,
          },
          localAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 40,
          },
        ),
        RouteIntelligenceThresholds.defaults,
      );
    });

    test('user overrides local; group overrides user for same field', () {
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '9',
        liveVehicle: _v('9', deviceAttributes: const {}),
        fleet: null,
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
        },
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
        },
      );
      expect(r.overspeedThresholdKmh, 70);
    });

    test('device overrides user and local', () {
      final r = resolveRouteIntelligenceThresholdsForVehicle(
        vehicleId: '10',
        liveVehicle: _v(
          '10',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 99,
          },
        ),
        fleet: null,
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
        },
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
        },
      );
      expect(r.overspeedThresholdKmh, 99);
    });
  });

  group('resolveRouteIntelligenceThresholdsForVehicleWithSources', () {
    test('empty vehicle id → defaults + all sources defaults', () {
      final res = resolveRouteIntelligenceThresholdsForVehicleWithSources(
        vehicleId: '',
        liveVehicle: _v('1'),
        fleet: [_v('1')],
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 50,
        },
      );
      expect(res.thresholds, RouteIntelligenceThresholds.defaults);
      expect(res.sources, RouteIntelligenceThresholdSources.allDefaults);
    });

    test('thresholds parity with resolveRouteIntelligenceThresholdsForVehicle', () {
      final v = _v(
        '1',
        groupId: '10',
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
        },
      );
      const group = {
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
        RouteIntelligenceAttributeKeys.minStopDurationMinutes: 5,
      };
      expect(
        resolveRouteIntelligenceThresholdsForVehicleWithSources(
          vehicleId: '1',
          liveVehicle: v,
          fleet: null,
          groupAttributes: group,
        ).thresholds,
        resolveRouteIntelligenceThresholdsForVehicle(
          vehicleId: '1',
          liveVehicle: v,
          fleet: null,
          groupAttributes: group,
        ),
      );
    });

    test('sources reflect winning layers', () {
      final v = _v(
        '2',
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 80,
        },
      );
      final res = resolveRouteIntelligenceThresholdsForVehicleWithSources(
        vehicleId: '2',
        liveVehicle: v,
        fleet: null,
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 9,
          RouteIntelligenceAttributeKeys.detectStops: false,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.detectIgnition: false,
        },
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 40,
        },
      );
      expect(
        res.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.device,
      );
      expect(
        res.sources.minStopDurationSource,
        RouteIntelligenceThresholdSource.group,
      );
      expect(
        res.sources.detectStopsSource,
        RouteIntelligenceThresholdSource.group,
      );
      expect(
        res.sources.detectIgnitionSource,
        RouteIntelligenceThresholdSource.user,
      );
    });
  });
}
