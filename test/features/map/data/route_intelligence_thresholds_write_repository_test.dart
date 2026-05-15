import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/core/error/app_exception.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/data/route_intelligence_attributes_patch.dart';
import 'package:elmogps/features/map/data/repositories/route_intelligence_thresholds_write_repository_impl.dart';
import 'package:elmogps/features/vehicles/data/datasources/vehicle_device_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVehicleDeviceGateway implements VehicleDeviceGateway {
  _FakeVehicleDeviceGateway(this.devices);

  final Map<int, Map<String, dynamic>> devices;
  int putCallCount = 0;
  Map<String, dynamic>? lastPutBody;

  Future<void> Function()? onGet;
  Future<void> Function()? onPut;

  @override
  Future<Map<String, dynamic>> getDeviceJson(int deviceId) async {
    if (onGet != null) await onGet!();
    final row = devices[deviceId];
    if (row == null) {
      throw const NotFoundException(message: 'Device not found.');
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> putDevice(Map<String, dynamic> deviceJson) async {
    if (onPut != null) await onPut!();
    putCallCount++;
    lastPutBody = Map<String, dynamic>.from(deviceJson);
    final id = deviceJson['id'] as int;
    devices[id] = Map<String, dynamic>.from(deviceJson);
  }
}

Map<String, dynamic> _deviceRow({
  required int id,
  Map<String, dynamic>? attributes,
}) {
  return <String, dynamic>{
    'id': id,
    'name': 'Unit $id',
    'uniqueId': 'u$id',
    'attributes': attributes == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(attributes),
  };
}

void main() {
  group('RouteIntelligenceThresholdsWriteRepositoryImpl saveVehicleThresholds', () {
    test('merges elmo.route.* only and preserves other attributes', () async {
      final gateway = _FakeVehicleDeviceGateway({
        1: _deviceRow(
          id: 1,
          attributes: {
            'driverName': 'Ali',
            'customNote': 'X',
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 50,
          },
        ),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.saveVehicleThresholds(
        vehicleId: '1',
        thresholds: const RouteIntelligenceThresholds(
          overspeedThresholdKmh: 90,
        ),
      );

      final attrs = gateway.devices[1]!['attributes'] as Map<String, dynamic>;
      expect(attrs['driverName'], 'Ali');
      expect(attrs['customNote'], 'X');
      expect(
        attrs[RouteIntelligenceAttributeKeys.overspeedThresholdKmh],
        90.0,
      );
      expect(
        attrs.keys.toSet().containsAll(RouteIntelligenceAttributeKeys.allKeys),
        isTrue,
      );
    });

    test('applies normalized() before persist', () async {
      final gateway = _FakeVehicleDeviceGateway({
        2: _deviceRow(id: 2, attributes: {}),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.saveVehicleThresholds(
        vehicleId: '2',
        thresholds: const RouteIntelligenceThresholds(
          stopSpeedEnterKmh: 10,
          stopSpeedExitKmh: 5,
          minStopDuration: Duration(minutes: 0),
        ),
      );

      final attrs = gateway.devices[2]!['attributes'] as Map<String, dynamic>;
      final parsed = RouteIntelligenceThresholds.fromAttributes(attrs);
      expect(parsed, equals(parsed.normalized()));
      expect(
        (attrs[RouteIntelligenceAttributeKeys.stopSpeedExitKmh] as num)
            .toDouble(),
        greaterThanOrEqualTo(
          (attrs[RouteIntelligenceAttributeKeys.stopSpeedEnterKmh] as num)
              .toDouble(),
        ),
      );
    });

    test('skips PUT when route layer is unchanged', () async {
      final n = const RouteIntelligenceThresholds().normalized();
      final existingAttrs = mergeRouteIntelligenceIntoAttributes(
        {'keep': 1},
        routeIntelThresholdsToAttributeMap(n),
      );

      final gateway = _FakeVehicleDeviceGateway({
        3: _deviceRow(id: 3, attributes: existingAttrs),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.saveVehicleThresholds(vehicleId: '3', thresholds: n);

      expect(gateway.putCallCount, 0);
    });
  });

  group('RouteIntelligenceThresholdsWriteRepositoryImpl clearVehicleThresholds', () {
    test('removes only RouteIntelligenceAttributeKeys.allKeys', () async {
      final gateway = _FakeVehicleDeviceGateway({
        4: _deviceRow(
          id: 4,
          attributes: {
            'driverName': 'Ali',
            'customNote': 'X',
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
          },
        ),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.clearVehicleThresholds(vehicleId: '4');

      final attrs = gateway.devices[4]!['attributes'] as Map<String, dynamic>;
      expect(attrs, {'driverName': 'Ali', 'customNote': 'X'});
    });

    test('no-op when no route keys (empty attributes)', () async {
      final gateway = _FakeVehicleDeviceGateway({
        5: _deviceRow(id: 5, attributes: {}),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.clearVehicleThresholds(vehicleId: '5');

      expect(gateway.putCallCount, 0);
    });

    test('no-op when attributes have no elmo.route.* keys', () async {
      final gateway = _FakeVehicleDeviceGateway({
        6: _deviceRow(
          id: 6,
          attributes: {'a': 1, 'b': 'z'},
        ),
      });
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      await repo.clearVehicleThresholds(vehicleId: '6');

      expect(gateway.putCallCount, 0);
    });
  });

  group('errors', () {
    test('invalid vehicle id', () async {
      final gateway = _FakeVehicleDeviceGateway({});
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      expect(
        () => repo.saveVehicleThresholds(
          vehicleId: '',
          thresholds: RouteIntelligenceThresholds.defaults,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.clearVehicleThresholds(vehicleId: 'x'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('propagates API failure from gateway', () async {
      final gateway = _FakeVehicleDeviceGateway({
        7: _deviceRow(id: 7, attributes: {}),
      });
      gateway.onGet = () async {
        throw const PermissionException();
      };
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      expect(
        () => repo.saveVehicleThresholds(
          vehicleId: '7',
          thresholds: RouteIntelligenceThresholds.defaults,
        ),
        throwsA(isA<PermissionException>()),
      );
    });

    test('group and user writes are unsupported', () async {
      final gateway = _FakeVehicleDeviceGateway({});
      final repo = RouteIntelligenceThresholdsWriteRepositoryImpl(gateway);

      expect(
        () => repo.saveGroupThresholds(
          groupId: 1,
          thresholds: RouteIntelligenceThresholds.defaults,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
