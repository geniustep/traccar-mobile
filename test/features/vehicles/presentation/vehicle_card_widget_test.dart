import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/core/theme/app_theme.dart';
import 'package:elmogps/features/fleet/presentation/fleet_vehicle_brief_provider.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleEntity _vehicle({
  String status = 'stopped',
  String? driverName,
  DateTime? lastUpdate,
  String? address,
}) {
  return VehicleEntity(
    id: '42',
    name: 'Camion 01',
    plateNumber: '12345-A-1',
    uniqueId: '8675309',
    type: 'truck',
    status: status,
    speed: 0,
    latitude: 35.75,
    longitude: -5.83,
    address: address,
    lastUpdate: lastUpdate ?? DateTime(2026, 5, 18, 11, 48),
    ignition: false,
    batteryVoltage: 12.8,
    fuelLevel: null,
    driverName: driverName,
    groupId: null,
  );
}

Widget wrapVehicleCardTest(Widget child, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('ar'),
      Locale('fr'),
      Locale('es'),
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  group('VehicleCard fleet list UI', () {
    testWidgets('hides driver and maintenance placeholders', (tester) async {
      final v = _vehicle(driverName: 'No driver assigned');
      const brief = FleetVehicleBrief(
        driverLine: 'No driver assigned',
        maintenanceLine: 'No maintenance',
        hasMaintenanceOverdue: false,
        insuranceLine: '',
        techLine: '',
      );

      await tester.pumpWidget(
        wrapVehicleCardTest(
          VehicleCard(vehicle: v, fleetBrief: brief),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No driver assigned'), findsNothing);
      expect(find.textContaining('No maintenance'), findsNothing);
      expect(find.text('Speed'), findsNothing);
      expect(find.text('Ignition'), findsNothing);
    });

    testWidgets('shows smart summary and context lines', (tester) async {
      final v = _vehicle(
        driverName: 'Karim',
        lastUpdate: DateTime(2026, 5, 18, 10, 36),
        address: 'Tanger, Zone Industrielle',
      );

      await tester.pumpWidget(
        wrapVehicleCardTest(VehicleCard(vehicle: v), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('km/h'), findsOneWidget);
      expect(find.textContaining('Karim'), findsOneWidget);
      expect(find.textContaining('Tanger'), findsOneWidget);
      expect(find.textContaining('Last data'), findsOneWidget);
      expect(find.textContaining('Engine off'), findsWidgets);
    });

    testWidgets('shows maintenance banner only when real', (tester) async {
      const brief = FleetVehicleBrief(
        driverLine: '',
        maintenanceLine: 'Maintenance • Vidange — 5000 km',
        hasMaintenanceOverdue: true,
        insuranceLine: '',
        techLine: '',
      );

      await tester.pumpWidget(
        wrapVehicleCardTest(
          VehicleCard(
            vehicle: _vehicle(),
            fleetBrief: brief,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Vidange'), findsOneWidget);
    });
  });
}
