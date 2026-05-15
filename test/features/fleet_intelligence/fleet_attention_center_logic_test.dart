import 'dart:math' as math;

import 'package:elmogps/features/fleet_intelligence/presentation/utils/fleet_attention_center_logic.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_config.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_calculator.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_config.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../map/core/trip_behavior_score_fixtures.dart';

FleetIntelligenceMetrics _calc(List<FleetVehicleTripInput> inputs,
    {FleetIntelligenceMetricsConfig? metricsConfig}) {
  return FleetIntelligenceMetricsCalculator.calculate(
    vehicles: inputs,
    scoreConfig: DriverBehaviorScoreConfig.defaults,
    metricsConfig: metricsConfig ?? FleetIntelligenceMetricsConfig.defaults,
  );
}

void main() {
  group('FleetAttentionCenterLogic', () {
    test('manyOverspeed reason when overspeed count high', () {
      final trip = testTripSegmentForScore(
        overspeedCount: 24,
        distanceKm: 30,
      );
      final m = _calc([
        FleetVehicleTripInput(
          vehicleId: 'x',
          vehicleName: 'X',
          trips: [trip],
        ),
      ]);
      final s = m.vehicleSummaries.single;
      final reasons = FleetAttentionCenterLogic.reasonsForVehicle(
        s,
        const FleetIntelligenceMetricsConfig(),
      );
      expect(
        reasons.where((r) => r == FleetAttentionReason.manyOverspeed),
        isNotEmpty,
      );
    });

    test('inactive reason for vehicles with no trips', () {
      final m = _calc([
        const FleetVehicleTripInput(vehicleId: 'z', trips: []),
      ]);
      final s = m.vehicleSummaries.single;
      expect(s.totalTrips, 0);
      final reasons = FleetAttentionCenterLogic.reasonsForVehicle(
        s,
        const FleetIntelligenceMetricsConfig(),
      );
      expect(reasons.contains(FleetAttentionReason.inactive), isTrue);
    });

    test('insufficientData for unknown unscorable with trips present', () {
      final t1 =
          testTripSegmentForScore(selectionKey: 'a', distanceKm: 0.04);
      final t2 =
          testTripSegmentForScore(selectionKey: 'b', distanceKm: 0.05);
      final m = _calc([
        FleetVehicleTripInput(vehicleId: 'u', trips: [t1, t2]),
      ]);
      final s = m.vehicleSummaries.single;
      expect(s.isPeriodScorable, isFalse);
      expect(s.totalTrips, greaterThan(0));
      final reasons = FleetAttentionCenterLogic.reasonsForVehicle(s, FleetIntelligenceMetricsConfig.defaults);
      expect(
          reasons.any((x) => x == FleetAttentionReason.insufficientData),
          isTrue,);
    });

    test('severe overspeed fixture maps to risk attention signals', () {
      final highRiskTrip = testTripSegmentForScore(
        selectionKey: 'hr',
        distanceKm: 15,
        overspeedCount: 12,
        maxSpeedKmh: 135,
      );
      final m = _calc([
        FleetVehicleTripInput(
          vehicleId: 'risky',
          vehicleName: 'R',
          trips: [highRiskTrip],
        ),
      ]);
      final s =
          m.vehicleSummaries.firstWhere((e) => e.vehicleId == 'risky');
      expect(s.needsAttention, isTrue,
          reason: 'Core calculator should flag this fixture.');
      final reasons =
          FleetAttentionCenterLogic.reasonsForVehicle(s, FleetIntelligenceMetricsConfig.defaults);
      expect(
        reasons.contains(FleetAttentionReason.highRisk) ||
            reasons.contains(FleetAttentionReason.manyOverspeed),
        isTrue,
      );
    });

    test('buildItems respects limit when many summaries qualify', () {
      final moderateOverspeedTrip = testTripSegmentForScore(
        selectionKey: 'mo',
        distanceKm: 15,
        overspeedCount: 8,
        maxSpeedKmh: 95,
      );
      final vehicles = List.generate(
        12,
        (i) => FleetVehicleTripInput(
          vehicleId: '$i',
          vehicleName: 'V$i',
          trips: [moderateOverspeedTrip],
        ),
      );
      final m = _calc(vehicles);
      final items = FleetAttentionCenterLogic.buildItems(
        summaries: m.vehicleSummaries,
        limit: 4,
      );
      expect(items.length, 4);
    });

    test('lowScore surfaces when period score is inside attention band', () {
      final trip = testTripSegmentForScore(selectionKey: 'sc', distanceKm: 14);
      final baseline = FleetIntelligenceMetricsCalculator.calculate(
        vehicles: [
          FleetVehicleTripInput(vehicleId: 'ls', trips: [trip]),
        ],
      );
      final ps = baseline.vehicleSummaries.single.periodScore;
      expect(ps, isNotNull);

      final cfg = FleetIntelligenceMetricsConfig(
        attentionScoreAtOrBelow: math.min(100, ps! + 10),
      );
      final m = FleetIntelligenceMetricsCalculator.calculate(
        vehicles: [
          FleetVehicleTripInput(vehicleId: 'ls', trips: [trip]),
        ],
        metricsConfig: cfg,
      );
      final s = m.vehicleSummaries.single;
      expect(s.isPeriodScorable, isTrue);
      expect(
        s.periodScore! <= cfg.normalized().attentionScoreAtOrBelow,
        isTrue,
      );
      final reasons = FleetAttentionCenterLogic.reasonsForVehicle(s, cfg);
      expect(reasons.contains(FleetAttentionReason.lowScore), isTrue);
    });
  });
}
