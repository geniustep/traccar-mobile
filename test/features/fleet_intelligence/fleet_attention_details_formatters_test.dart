import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/fleet_intelligence/presentation/utils/fleet_attention_center_logic.dart';
import 'package:elmogps/features/fleet_intelligence/presentation/utils/fleet_attention_details_formatters.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_calculator.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_config.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../map/core/trip_behavior_score_fixtures.dart';

FleetVehicleIntelligenceSummary _calcSingleVehicle(
  List<Map<String, Object?>> tripSpecs,
  String vid,
) {
  final trips = tripSpecs
      .map((m) => testTripSegmentForScore(
            selectionKey: m['key'] as String,
            distanceKm: (m['km'] as num).toDouble(),
            overspeedCount: m['ov'] as int? ?? 0,
            maxSpeedKmh: (m['mx'] as num?)?.toDouble() ?? 60,
          ))
      .toList();
  final m = FleetIntelligenceMetricsCalculator.calculate(
    vehicles: [
      FleetVehicleTripInput(vehicleId: vid, vehicleName: vid, trips: trips),
    ],
    scoreConfig: DriverBehaviorScoreConfig.defaults,
    metricsConfig: FleetIntelligenceMetricsConfig.defaults,
  );
  return m.vehicleSummaries.single;
}

void main() {
  group('FleetAttentionDetailsFormatters', () {
    final l10n = AppLocalizations(const Locale('en'));

    test('reasonsBulleted adds bullet lines per reason', () {
      expect(
        FleetAttentionDetailsFormatters.reasonsBulleted(l10n, const [
          FleetAttentionReason.highRisk,
          FleetAttentionReason.manyOverspeed,
        ]),
        [
          '• ${l10n.fleetAttentionHighRisk}',
          '• ${l10n.fleetAttentionManyOverspeed}',
        ].join('\n'),
      );
    });

    test('reasonsInline joins labels with middot space', () {
      expect(
        FleetAttentionDetailsFormatters.reasonsInline(l10n, [
          FleetAttentionReason.inactive,
          FleetAttentionReason.insufficientData,
        ]),
        '${l10n.fleetAttentionInactive} · '
        '${l10n.fleetAttentionInsufficientData}',
      );
    });

    test('scoreLineIfScorable is null when period is not scorable', () {
      final s = _calcSingleVehicle([
        {'key': 'a', 'km': 0.04},
        {'key': 'b', 'km': 0.05},
      ], 'unscorable');
      expect(s.isPeriodScorable, isFalse);
      expect(
        FleetAttentionDetailsFormatters.scoreLineIfScorable(l10n, s),
        isNull,
      );
      expect(s.periodScore, isNull,
          reason: 'calculator clears score when unscorable — no phantom 0');
    });

    test('scoreLineIfScorable exposes score label when scorable', () {
      final s = _calcSingleVehicle([
        {'key': 't', 'km': 12.0, 'ov': 2},
      ], 'ok');
      expect(s.isPeriodScorable, isTrue);
      expect(s.periodScore, isNotNull);
      final line =
          FleetAttentionDetailsFormatters.scoreLineIfScorable(l10n, s)!;
      expect(line, contains(l10n.fleetAttentionScore));
      expect(line, contains('${s.periodScore}'));
    });

    test('statRows labels and distance match FleetIntel formatter', () {
      final s = _calcSingleVehicle([
        {'key': 'x', 'km': 14.35, 'ov': 1},
      ], 'metrics');
      final rows = FleetAttentionDetailsFormatters.statRows(l10n, s);
      expect(rows.map((e) => e.$1), [
        l10n.fleetAttentionTrips,
        l10n.fleetAttentionDistance,
        l10n.fleetAttentionOverspeed,
        l10n.fleetAttentionStops,
      ]);
      expect(rows.singleWhere((r) => r.$1 == l10n.fleetAttentionTrips).$2,
          '${s.totalTrips}',);
      expect(
        rows.singleWhere((r) => r.$1 == l10n.fleetAttentionDistance).$2,
        isNotEmpty,
      );
      expect(rows.singleWhere((r) => r.$1 == l10n.fleetAttentionOverspeed).$2,
          '${s.totalOverspeedEvents}',);
      expect(rows.singleWhere((r) => r.$1 == l10n.fleetAttentionStops).$2,
          '${s.totalStops}',);
    });
  });
}
