import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/models/traccar_position.dart';
import 'package:elmogps/features/map/core/vehicle_live_merger.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';

VehicleEntity _vehicle({
  required String id,
  DateTime? lastUpdate,
  double lat = 33.5,
  double lon = -7.6,
}) =>
    VehicleEntity(
      id: id,
      name: 'Test',
      plateNumber: '1',
      type: 'car',
      status: 'stopped',
      speed: 0,
      latitude: lat,
      longitude: lon,
      address: null,
      lastUpdate: lastUpdate,
      ignition: false,
      batteryVoltage: null,
      fuelLevel: null,
      driverName: null,
      groupId: null,
    );

TraccarPosition _pos(int deviceId, DateTime fixTime) => TraccarPosition(
      id: 1,
      deviceId: deviceId,
      latitude: 34.0,
      longitude: -7.0,
      fixTime: fixTime,
      serverTime: fixTime,
      speed: 10,
      valid: true,
    );

void main() {
  group('VehicleLiveMerger.mergeIfPresent', () {
    test('applies newer socket fix', () {
      final base = _vehicle(
        id: '7',
        lastUpdate: DateTime.utc(2026, 5, 16, 10),
        lat: 33.0,
        lon: -7.0,
      );
      final live = _pos(7, DateTime.utc(2026, 5, 16, 12));
      final merged = VehicleLiveMerger.mergeIfPresent(base, {7: live});
      expect(merged.latitude, 34.0);
      expect(merged.longitude, -7.0);
    });

    test('ignores older socket fix than REST lastUpdate', () {
      final base = _vehicle(
        id: '7',
        lastUpdate: DateTime.utc(2026, 5, 16, 13),
        lat: 33.5,
        lon: -7.6,
      );
      final live = _pos(7, DateTime.utc(2026, 5, 16, 10));
      final merged = VehicleLiveMerger.mergeIfPresent(base, {7: live});
      expect(merged.latitude, 33.5);
      expect(merged.longitude, -7.6);
    });
  });
}
