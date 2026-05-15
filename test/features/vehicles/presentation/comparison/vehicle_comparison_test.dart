import 'package:elmogps/features/vehicles/presentation/comparison/vehicle_comparison_formatters.dart';
import 'package:elmogps/features/vehicles/presentation/comparison/vehicle_comparison_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleComparisonFormatters', () {
    test('canCompare requires at least 2 vehicles', () {
      expect(VehicleComparisonFormatters.canCompare(0), isFalse);
      expect(VehicleComparisonFormatters.canCompare(1), isFalse);
      expect(VehicleComparisonFormatters.canCompare(2), isTrue);
      expect(VehicleComparisonFormatters.canCompare(5), isTrue);
    });

    test('missing metric displays empty value', () {
      expect(
        VehicleComparisonFormatters.formatDistanceKm(null),
        VehicleComparisonFormatters.emptyValue,
      );
      expect(
        VehicleComparisonFormatters.formatCount(null),
        VehicleComparisonFormatters.emptyValue,
      );
      expect(
        VehicleComparisonFormatters.formatSpeedKmh(null),
        VehicleComparisonFormatters.emptyValue,
      );
      expect(
        VehicleComparisonFormatters.formatDurationSeconds(null),
        VehicleComparisonFormatters.emptyValue,
      );
    });

    test('format distance speed and duration', () {
      expect(
        VehicleComparisonFormatters.formatDistanceKm(12.5),
        '12.5 km',
      );
      expect(
        VehicleComparisonFormatters.formatSpeedKmh(80),
        '80 km/h',
      );
      expect(
        VehicleComparisonFormatters.formatDurationSeconds(3660),
        '1h 1m',
      );
    });

    test('removeVehicle removes id and keeps order', () {
      const ids = ['a', 'b', 'c'];
      expect(
        VehicleComparisonFormatters.removeVehicle(ids, 'b'),
        ['a', 'c'],
      );
      expect(
        VehicleComparisonFormatters.removeVehicle(ids, 'x'),
        ids,
      );
    });
  });

  group('VehicleComparisonHighlights', () {
    final t1 = DateTime(2026, 5, 15, 8);
    final t2 = DateTime(2026, 5, 15, 12);

    final items = [
      VehicleComparisonItem(
        vehicleId: '1',
        name: 'Alpha',
        distanceKm: 10,
        alertsToday: 2,
        stopDurationSeconds: 100,
        lastUpdate: t1,
      ),
      VehicleComparisonItem(
        vehicleId: '2',
        name: 'Bravo',
        distanceKm: 25,
        alertsToday: 5,
        stopDurationSeconds: 300,
        lastUpdate: t2,
      ),
      VehicleComparisonItem(
        vehicleId: '3',
        name: 'Charlie',
        distanceKm: 5,
        alertsToday: 1,
        stopDurationSeconds: 50,
        lastUpdate: null,
      ),
    ];

    test('highest distance detection', () {
      final h = VehicleComparisonHighlights.fromItems(items);
      expect(h.highestDistanceVehicleId, '2');
    });

    test('highest alerts detection', () {
      final h = VehicleComparisonHighlights.fromItems(items);
      expect(h.highestAlertsVehicleId, '2');
    });

    test('highest stop duration and most recent update', () {
      final h = VehicleComparisonHighlights.fromItems(items);
      expect(h.highestStopDurationVehicleId, '2');
      expect(h.mostRecentUpdateVehicleId, '2');
    });

    test('no highlight when all values are zero', () {
      final h = VehicleComparisonHighlights.fromItems(const [
        VehicleComparisonItem(
          vehicleId: '1',
          name: 'A',
          distanceKm: 0,
          alertsToday: 0,
          stopDurationSeconds: 0,
        ),
        VehicleComparisonItem(
          vehicleId: '2',
          name: 'B',
          distanceKm: 0,
          alertsToday: 0,
          stopDurationSeconds: 0,
        ),
      ]);
      expect(h.highestDistanceVehicleId, isNull);
      expect(h.highestAlertsVehicleId, isNull);
      expect(h.highestStopDurationVehicleId, isNull);
    });
  });
}
