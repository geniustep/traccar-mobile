import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/fleet_intelligence/presentation/utils/fleet_intelligence_formatters.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_calculator.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10nEn = AppLocalizations(const Locale('en'));

  group('FleetIntelUiFormatters', () {
    test('empty fleet metrics — headline not scorable / no zero score line', () {
      final m = FleetIntelligenceMetricsCalculator.calculate(vehicles: const []);
      final h = FleetIntelUiFormatters.fleetScoreHeadline(l10nEn, m);
      expect(m.isScorable, isFalse);
      expect(
        FleetIntelUiFormatters.avoidsZeroScoreHeadline(l10nEn, m, h),
        isTrue,
      );
      expect(h, l10nEn.driverScoreNotScorable);
    });

    test('vehicleLabel uses fallback when name missing', () {
      final m = FleetIntelligenceMetricsCalculator.calculate(
        vehicles: const [
          FleetVehicleTripInput(vehicleId: '42', trips: []),
        ],
      );
      final s = m.vehicleSummaries.single;
      expect(
        FleetIntelUiFormatters.vehicleLabel(l10nEn, s),
        l10nEn.fleetIntelVehicleFallback('42'),
      );
    });

    test('distance formatting uses trip km unit', () {
      expect(
        FleetIntelUiFormatters.formatFleetDistanceKm(l10nEn, 12.3),
        contains('12.3'),
      );
    });
  });
}
