import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/fleet/presentation/fleet_vehicle_brief_provider.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/providers/vehicles_provider.dart';
import 'package:elmogps/features/vehicles/presentation/utils/fleet_list_card_intel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleEntity _vehicle({
  String id = '1',
  String status = 'stopped',
  bool ignition = false,
  double speed = 0,
  DateTime? lastUpdate,
  String? driverName,
  String? address,
  double? batteryVoltage,
}) {
  return VehicleEntity(
    id: id,
    name: 'Van A',
    plateNumber: 'AA-123',
    uniqueId: 'IMEI-1',
    type: 'van',
    status: status,
    speed: speed,
    latitude: 0,
    longitude: 0,
    address: address,
    lastUpdate: lastUpdate,
    ignition: ignition,
    batteryVoltage: batteryVoltage,
    fuelLevel: null,
    driverName: driverName,
    groupId: null,
  );
}

void main() {
  final l10nFr = AppLocalizations(const Locale('fr'));

  group('FleetListCardIntel', () {
    test('stored placeholder driver name is rejected', () {
      expect(
        FleetListCardIntel.driverDisplayName(
          brief: null,
          vehicle: _vehicle(driverName: 'Conducteur non assigné'),
          l10n: l10nFr,
        ),
        isNull,
      );
    });

    test('driver absent returns null not placeholder', () {
      expect(
        FleetListCardIntel.driverDisplayName(
          brief: const FleetVehicleBrief(
            driverLine: '',
            maintenanceLine: '',
            hasMaintenanceOverdue: false,
            insuranceLine: '',
            techLine: '',
          ),
          vehicle: _vehicle(),
          l10n: l10nFr,
        ),
        isNull,
      );
    });

    test('driver name shown when assigned', () {
      expect(
        FleetListCardIntel.driverDisplayName(
          brief: const FleetVehicleBrief(
            driverLine: 'Karim',
            maintenanceLine: '',
            hasMaintenanceOverdue: false,
            insuranceLine: '',
            techLine: '',
          ),
          vehicle: _vehicle(),
          l10n: l10nFr,
        ),
        'Karim',
      );
    });

    test('no maintenance banner when lines empty', () {
      final v = _vehicle(lastUpdate: DateTime.now());
      const brief = FleetVehicleBrief(
        driverLine: '',
        maintenanceLine: '',
        hasMaintenanceOverdue: false,
        insuranceLine: '',
        techLine: '',
      );
      expect(FleetListCardIntel.hasUsefulMaintenance(brief, l10nFr), isFalse);
      expect(
        FleetListCardIntel.pickAlertBanner(
          v,
          brief,
          l10n: l10nFr,
          now: DateTime.now(),
        ),
        isNull,
      );
    });

    test('maintenance overdue produces banner', () {
      final v = _vehicle(lastUpdate: DateTime.now());
      const brief = FleetVehicleBrief(
        driverLine: '',
        maintenanceLine: 'Vidange — 5000 km',
        hasMaintenanceOverdue: true,
        insuranceLine: '',
        techLine: '',
      );
      final banner = FleetListCardIntel.pickAlertBanner(
        v,
        brief,
        l10n: l10nFr,
        now: DateTime.now(),
      );
      expect(banner, isNotNull);
      expect(banner!.text, contains('Vidange'));
    });

    test('unreliable address hidden', () {
      expect(
        FleetListCardIntel.isReliableAddress('unknown'),
        isFalse,
      );
      expect(
        FleetListCardIntel.lastPositionLine(
          _vehicle(address: 'unknown'),
          l10nFr,
        ),
        isNull,
      );
      expect(
        FleetListCardIntel.lastPositionLine(
          _vehicle(address: 'Tanger, Zone Industrielle'),
          l10nFr,
        ),
        isNotNull,
      );
    });

    test('summary includes stop duration when stopped', () {
      final now = DateTime(2026, 5, 18, 12, 0);
      final v = _vehicle(
        status: 'stopped',
        lastUpdate: now.subtract(const Duration(hours: 1, minutes: 12)),
      );
      final line = FleetListCardIntel.buildSummaryLine(
        vehicle: v,
        l10n: l10nFr,
        now: now,
      );
      expect(line, contains('1h 12m'));
      expect(line, contains('Arrêtée'));
    });

    test('low battery critical alert', () {
      final v = _vehicle(
        lastUpdate: DateTime.now(),
        batteryVoltage: 11.5,
      );
      final banner = FleetListCardIntel.pickAlertBanner(
        v,
        null,
        l10n: l10nFr,
        now: DateTime.now(),
      );
      expect(banner?.priority, FleetCardAlertPriority.critical);
    });

    test('last data footer only when lastUpdate present', () {
      expect(
        FleetListCardIntel.lastDataFooterLine(_vehicle(), l10nFr),
        isNull,
      );
      expect(
        FleetListCardIntel.lastDataFooterLine(
          _vehicle(lastUpdate: DateTime.now()),
          l10nFr,
          now: DateTime.now(),
        ),
        isNotNull,
      );
    });
  });

  group('fleetStatusFilterCounts', () {
    test('hides zero-count filters except All', () {
      final vehicles = [
        _vehicle(id: '1', status: 'moving'),
        _vehicle(id: '2', status: 'moving'),
      ];
      final counts = fleetStatusFilterCounts(vehicles);
      final visible = visibleFleetStatusFilters(counts);
      expect(visible, contains(null));
      expect(visible, contains('moving'));
      expect(visible, isNot(contains('stopped')));
      expect(visible, isNot(contains('idle')));
      expect(visible, isNot(contains('offline')));
    });
  });
}
