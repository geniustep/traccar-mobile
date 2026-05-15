import 'package:elmogps/features/reports/presentation/providers/reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportsEntryParams', () {
    test('creation preserves all fields', () {
      final from = DateTime(2026, 5, 14, 8, 0);
      final to = DateTime(2026, 5, 14, 18, 0);
      final params = ReportsEntryParams(
        vehicleId: '42',
        vehicleName: 'Truck A',
        period: ReportPeriod.today,
        from: from,
        to: to,
        tabIndex: 2,
      );

      expect(params.vehicleId, '42');
      expect(params.vehicleName, 'Truck A');
      expect(params.period, ReportPeriod.today);
      expect(params.from, from);
      expect(params.to, to);
      expect(params.tabIndex, 2);
    });

    test('tabIndex defaults to 0', () {
      final params = ReportsEntryParams(
        vehicleId: '1',
        vehicleName: 'V',
        period: ReportPeriod.yesterday,
        from: DateTime.now(),
        to: DateTime.now(),
      );
      expect(params.tabIndex, 0);
    });
  });

  group('ReportPeriod', () {
    test('all enum values have a labelFr', () {
      for (final p in ReportPeriod.values) {
        expect(p.labelFr, isNotEmpty);
      }
    });

    test('values count is 5', () {
      expect(ReportPeriod.values.length, 5);
    });
  });

  group('ReportFilterState', () {
    test('initial sets today period and canGenerate is false', () {
      final state = ReportFilterState.initial();
      expect(state.period, ReportPeriod.today);
      expect(state.canGenerate, isFalse);
      expect(state.hasGenerated, isFalse);
      expect(state.vehicleId, isNull);
    });

    test('canGenerate is true when vehicleId is set', () {
      final state = ReportFilterState.initial().copyWith(vehicleId: '42');
      expect(state.canGenerate, isTrue);
    });

    test('params returns null when vehicleId is missing', () {
      final state = ReportFilterState.initial();
      expect(state.params, isNull);
    });

    test('params returns ReportFilterParams when vehicleId is set', () {
      final state = ReportFilterState.initial().copyWith(vehicleId: '42');
      final params = state.params;
      expect(params, isNotNull);
      expect(params!.vehicleId, '42');
      expect(params.from.isUtc, isTrue);
      expect(params.to.isUtc, isTrue);
    });
  });

  group('ReportFilterNotifier', () {
    test('setVehicle updates vehicleId and name', () {
      final notifier = ReportFilterNotifier();
      notifier.setVehicle('7', 'Bus B');
      expect(notifier.debugState.vehicleId, '7');
      expect(notifier.debugState.vehicleName, 'Bus B');
    });

    test('setPeriod updates from/to correctly for today', () {
      final notifier = ReportFilterNotifier();
      notifier.setPeriod(ReportPeriod.today);
      final state = notifier.debugState;
      final now = DateTime.now();
      expect(state.from.year, now.year);
      expect(state.from.month, now.month);
      expect(state.from.day, now.day);
      expect(state.from.hour, 0);
    });

    test('setPeriod yesterday sets previous day', () {
      final notifier = ReportFilterNotifier();
      notifier.setPeriod(ReportPeriod.yesterday);
      final state = notifier.debugState;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(state.from.day, yesterday.day);
      expect(state.to.hour, 23);
      expect(state.to.minute, 59);
    });

    test('generate sets hasGenerated', () {
      final notifier = ReportFilterNotifier();
      expect(notifier.debugState.hasGenerated, isFalse);
      notifier.generate();
      expect(notifier.debugState.hasGenerated, isTrue);
    });

    test('setFrom auto-corrects to if from > to', () {
      final notifier = ReportFilterNotifier();
      final futureDate = DateTime.now().add(const Duration(hours: 48));
      notifier.setFrom(futureDate);
      final state = notifier.debugState;
      expect(state.period, ReportPeriod.custom);
      expect(state.from, futureDate);
      expect(state.to.isAfter(futureDate), isTrue);
    });
  });

  group('ReportFilterParams', () {
    test('equality works correctly', () {
      final from = DateTime.utc(2026, 5, 14);
      final to = DateTime.utc(2026, 5, 15);
      final a = ReportFilterParams(vehicleId: '1', from: from, to: to);
      final b = ReportFilterParams(vehicleId: '1', from: from, to: to);
      final c = ReportFilterParams(vehicleId: '2', from: from, to: to);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
