import 'package:elmogps/features/fleet/presentation/fleet_vehicle_brief_provider.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_card_widget_test.dart' show wrapVehicleCardTest;

void main() {
  testWidgets('fleet vehicle card smart layout golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final stopped = VehicleEntity(
      id: '1',
      name: 'Camion 01',
      plateNumber: '12345-A-1',
      uniqueId: '8675309',
      type: 'truck',
      status: 'stopped',
      speed: 0,
      latitude: 35.75,
      longitude: -5.83,
      address: null,
      lastUpdate: DateTime(2026, 5, 18, 10, 30),
      ignition: false,
      batteryVoltage: 12.8,
      fuelLevel: null,
      driverName: 'No driver assigned',
      groupId: null,
    );

    await tester.pumpWidget(
      wrapVehicleCardTest(
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            VehicleCard(
              vehicle: stopped,
              fleetBrief: const FleetVehicleBrief(
                driverLine: 'No driver assigned',
                maintenanceLine: 'No maintenance',
                hasMaintenanceOverdue: false,
                insuranceLine: '',
                techLine: '',
              ),
            ),
            const SizedBox(height: 10),
            VehicleCard(
              vehicle: VehicleEntity(
                id: '2',
                name: 'Van Express',
                plateNumber: 'ABC-99',
                uniqueId: 'IMEI-999',
                type: 'van',
                status: 'stopped',
                speed: 0,
                latitude: 35.7,
                longitude: -5.8,
                address: 'Tanger, Zone Industrielle',
                lastUpdate: DateTime(2026, 5, 18, 12, 5),
                ignition: false,
                batteryVoltage: 13.1,
                fuelLevel: null,
                driverName: 'Karim',
                groupId: null,
              ),
            ),
          ],
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('goldens/fleet_vehicle_cards_smart.png'),
    );
  });
}
