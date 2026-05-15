import 'package:flutter/foundation.dart';

/// Lightweight tuning for [FleetIntelligenceMetricsCalculator] — Phase **10A** (Core).
@immutable
class FleetIntelligenceMetricsConfig {
  const FleetIntelligenceMetricsConfig({
    this.attentionScoreAtOrBelow = 55,
    this.minVehicleDistanceWeightKm = 1.0,
    this.moderateRiskOverspeedAttentionMin = 6,
  });

  /// Vehicles with **[DailyVehicleBehaviorScore.isScorable]** and
  /// **periodScore ≤ this** are flagged (**in addition** to band-based rules).
  final int attentionScoreAtOrBelow;

  /// Fleet-wide weighted average uses **max**(vehicle [totalDistanceKm], this floor)
  /// for each **scorable** vehicle.
  final double minVehicleDistanceWeightKm;

  /// When **[DriverRiskLevel.moderate]**, overspeed totals **≥ this** also flag attention.
  final int moderateRiskOverspeedAttentionMin;

  static const FleetIntelligenceMetricsConfig defaults =
      FleetIntelligenceMetricsConfig();

  FleetIntelligenceMetricsConfig normalized() {
    const d = FleetIntelligenceMetricsConfig.defaults;

    int nnBand(int x) {
      if (x < 0 || x > 100) return d.attentionScoreAtOrBelow;
      return x;
    }

    double nnWeight(double x) {
      if (!x.isFinite || x <= 0) return d.minVehicleDistanceWeightKm;
      return x;
    }

    var ovMin = moderateRiskOverspeedAttentionMin;
    if (ovMin < 0) ovMin = d.moderateRiskOverspeedAttentionMin;

    return FleetIntelligenceMetricsConfig(
      attentionScoreAtOrBelow: nnBand(attentionScoreAtOrBelow),
      minVehicleDistanceWeightKm:
          nnWeight(minVehicleDistanceWeightKm),
      moderateRiskOverspeedAttentionMin: ovMin,
    );
  }

  /// Optional fingerprint for caching layers outside Core.
  String get cacheKey {
    final n = normalized();
    return [
      '${n.attentionScoreAtOrBelow}',
      n.minVehicleDistanceWeightKm.toStringAsFixed(6),
      '${n.moderateRiskOverspeedAttentionMin}',
    ].join('#');
  }
}
