import 'package:elmogps/features/map/presentation/providers/map_vehicle_filter.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleEntity _vehicle({
  required String id,
  required String name,
  String status = 'moving',
  String plate = 'ABC-123',
  String? driverName,
}) {
  return VehicleEntity(
    id: id,
    name: name,
    plateNumber: plate,
    type: 'car',
    status: status,
    speed: status == 'moving' ? 30 : 0,
    latitude: 1,
    longitude: 2,
    address: null,
    lastUpdate: null,
    ignition: status != 'offline',
    batteryVoltage: null,
    fuelLevel: null,
    driverName: driverName,
    groupId: null,
  );
}

void main() {
  final fleet = [
    _vehicle(id: '1', name: 'Alpha', status: 'moving'),
    _vehicle(id: '2', name: 'Bravo', status: 'stopped', plate: 'XY-99'),
    _vehicle(
      id: '3',
      name: 'Charlie',
      status: 'offline',
      driverName: 'Sam Driver',
    ),
  ];

  group('applyVehicleMapFilter', () {
    test('empty filter returns all vehicles', () {
      final result = applyVehicleMapFilter(fleet, const VehicleMapFilterState());
      expect(result.length, 3);
    });

    test('selectedVehicleIds restricts list', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(selectedVehicleIds: {'1', '3'}),
      );
      expect(result.map((v) => v.id).toList(), ['1', '3']);
    });

    test('onlineOnly excludes offline vehicles', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(onlineOnly: true),
      );
      expect(result.map((v) => v.id).toList(), ['1', '2']);
    });

    test('movingOnly keeps moving vehicles', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(movingOnly: true),
      );
      expect(result.single.id, '1');
    });

    test('combined filters apply in sequence', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(
          selectedVehicleIds: {'1', '2', '3'},
          movingOnly: true,
          onlineOnly: true,
        ),
      );
      expect(result.single.id, '1');
    });

    test('searchQuery restricts visible fleet', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(searchQuery: 'alpha'),
      );
      expect(result.single.name, 'Alpha');
    });

    test('single vehicle selection state', () {
      const state = VehicleMapFilterState(selectedVehicleIds: {'2'});
      expect(state.selectedCount, 1);
      expect(state.isActive, isTrue);
      final result = applyVehicleMapFilter(fleet, state);
      expect(result.single.id, '2');
    });

    test('multiple vehicle selection state', () {
      const state = VehicleMapFilterState(selectedVehicleIds: {'1', '2'});
      expect(state.selectedCount, 2);
      final result = applyVehicleMapFilter(fleet, state);
      expect(result.map((v) => v.id).toSet(), {'1', '2'});
    });

    test('filter with no matching vehicles returns empty', () {
      final result = applyVehicleMapFilter(
        fleet,
        const VehicleMapFilterState(searchQuery: 'zzz'),
      );
      expect(result, isEmpty);
    });

    test('onlineOnly without ids is active but shows subset', () {
      const state = VehicleMapFilterState(onlineOnly: true);
      expect(state.selectedCount, 0);
      expect(state.isActive, isTrue);
    });
  });

  group('matchesVehicleSearchQuery', () {
    test('matches name plate uniqueId driver', () {
      expect(matchesVehicleSearchQuery(fleet[0], 'alph'), isTrue);
      expect(matchesVehicleSearchQuery(fleet[1], 'xy-99'), isTrue);
      expect(matchesVehicleSearchQuery(fleet[2], 'sam'), isTrue);
      expect(matchesVehicleSearchQuery(fleet[0], 'zzz'), isFalse);
    });
  });

  group('vehiclesForFilterSheetList', () {
    test('live search without selected ids restriction', () {
      final result = vehiclesForFilterSheetList(
        fleet,
        searchQuery: 'brav',
        onlineOnly: false,
        movingOnly: false,
      );
      expect(result.single.name, 'Bravo');
    });

    test('search with onlineOnly', () {
      final result = vehiclesForFilterSheetList(
        fleet,
        searchQuery: '',
        onlineOnly: true,
        movingOnly: false,
      );
      expect(result.length, 2);
    });
  });
}
