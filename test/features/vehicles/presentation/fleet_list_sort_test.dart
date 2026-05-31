import 'package:elmogps/features/fleet/presentation/fleet_vehicle_brief_provider.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/utils/fleet_list_sort.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleEntity _v({
  required String id,
  required String name,
  String status = 'stopped',
  DateTime? lastUpdate,
  double? batteryVoltage,
}) {
  return VehicleEntity(
    id: id,
    name: name,
    plateNumber: '',
    type: 'car',
    status: status,
    speed: 0,
    latitude: 0,
    longitude: 0,
    address: null,
    lastUpdate: lastUpdate,
    ignition: false,
    batteryVoltage: batteryVoltage,
    fuelLevel: null,
    driverName: null,
    groupId: null,
  );
}

void main() {
  final now = DateTime(2026, 5, 18, 12, 0);

  group('FleetListSort', () {
    test('moving before long-offline even if offline has critical alert', () {
      final moving = _v(
        id: 'm',
        name: 'Moving',
        status: 'moving',
        lastUpdate: now.subtract(const Duration(minutes: 1)),
      );
      final longOffline = _v(
        id: 'o',
        name: 'Old offline',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 5)),
      );
      final sorted = FleetListSort.sorted([longOffline, moving], {}, now: now);
      expect(sorted.first.id, 'm');
      expect(sorted.last.id, 'o');
    });

    test('moving with critical alert before moving without alert', () {
      final plain = _v(
        id: '1',
        name: 'Plain moving',
        status: 'moving',
        lastUpdate: now,
      );
      final critical = _v(
        id: '2',
        name: 'Critical moving',
        status: 'moving',
        lastUpdate: now,
        batteryVoltage: 11.4,
      );
      final sorted = FleetListSort.sorted([plain, critical], {}, now: now);
      expect(sorted.first.id, '2');
    });

    test('stopped with maintenance before recent stopped without alert', () {
      final boxer = _v(
        id: 'boxer',
        name: 'BOXER',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 3)),
      );
      final clio = _v(
        id: 'clio',
        name: 'clio abdenbi',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 2)),
      );
      final briefs = {
        'boxer': const FleetVehicleBrief(
          driverLine: '',
          maintenanceLine: 'Vidange',
          hasMaintenanceOverdue: true,
          insuranceLine: '',
          techLine: '',
        ),
      };
      final sorted = FleetListSort.sorted(
        [clio, boxer],
        briefs,
        now: now,
      );
      expect(sorted.map((v) => v.name).toList(), ['BOXER', 'clio abdenbi']);
    });

    test('screenshot-like order: stopped maint, stopped recent, offline 4d, offline 5d',
        () {
      final boxer = _v(
        id: '1',
        name: 'BOXER',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 3)),
      );
      final clio = _v(
        id: '2',
        name: 'clio abdenbi',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 2)),
      );
      final samsung = _v(
        id: '3',
        name: 'samsung',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 4)),
      );
      final iphone = _v(
        id: '4',
        name: 'iphone',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 5)),
      );
      final briefs = {
        '1': const FleetVehicleBrief(
          driverLine: '',
          maintenanceLine: 'Maintenance',
          hasMaintenanceOverdue: true,
          insuranceLine: '',
          techLine: '',
        ),
      };
      final sorted = FleetListSort.sorted(
        [iphone, samsung, clio, boxer],
        briefs,
        now: now,
      );
      expect(
        sorted.map((v) => v.name).toList(),
        ['BOXER', 'clio abdenbi', 'samsung', 'iphone'],
      );
    });

    test('within offline group, more recent last data first', () {
      final fourDays = _v(
        id: 'a',
        name: 'samsung',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 4)),
      );
      final fiveDays = _v(
        id: 'b',
        name: 'iphone',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 5)),
      );
      final sorted = FleetListSort.sorted([fiveDays, fourDays], {}, now: now);
      expect(sorted.map((v) => v.name).toList(), ['samsung', 'iphone']);
    });

    test('recent stopped before long stopped', () {
      final recent = _v(
        id: 'r',
        name: 'Recent',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 10)),
      );
      final old = _v(
        id: 'o',
        name: 'Old stop',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(days: 2)),
      );
      final sorted = FleetListSort.sorted([old, recent], {}, now: now);
      expect(sorted.first.name, 'Recent');
    });

    test('moving before stopped without alerts', () {
      final stopped = _v(
        id: '1',
        name: 'Stopped',
        status: 'stopped',
        lastUpdate: now,
      );
      final moving = _v(
        id: '2',
        name: 'Moving',
        status: 'moving',
        lastUpdate: now,
      );
      final sorted = FleetListSort.sorted([stopped, moving], {}, now: now);
      expect(sorted.first.status, 'moving');
    });

    test('idle after stopped, before long offline', () {
      final idle = _v(
        id: 'i',
        name: 'Idle',
        status: 'idle',
        lastUpdate: now.subtract(const Duration(minutes: 5)),
      );
      final offline = _v(
        id: 'o',
        name: 'Offline',
        status: 'offline',
        lastUpdate: now.subtract(const Duration(days: 3)),
      );
      final sorted = FleetListSort.sorted([offline, idle], {}, now: now);
      expect(sorted.first.id, 'i');
    });

    test('tie-breaker uses newest lastUpdate within same rank', () {
      final a = _v(
        id: '1',
        name: 'A',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 10)),
      );
      final b = _v(
        id: '2',
        name: 'B',
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(minutes: 2)),
      );
      final sorted = FleetListSort.sorted([a, b], {}, now: now);
      expect(sorted.first.name, 'B');
    });
  });
}
