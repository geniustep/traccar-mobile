import 'package:flutter/foundation.dart';

/// Risk band derived from numeric score when [DriverBehaviorScore.isScorable].
enum DriverRiskLevel {
  excellent,
  good,
  moderate,
  highRisk,
  unknown,
}

/// Relative weight of a factor (for sorting / UI), not SI units.
enum DriverBehaviorFactorSeverity {
  info,
  low,
  medium,
  high,
}

/// Stable machine-readable factor identifier (maps to UI l10n later).
@immutable
class DriverBehaviorScoreFactor {
  const DriverBehaviorScoreFactor({
    required this.code,
    required this.type,
    required this.points,
    this.severity = DriverBehaviorFactorSeverity.info,
    this.description,
    this.count,
  });

  /// e.g. `overspeed`, `heavyOverspeed`, `cleanTrip`.
  final String code;

  /// Factor category; often same as [code].
  final String type;

  /// Penalty magnitude contributed before global caps (always ≥ 0).
  final double points;

  final DriverBehaviorFactorSeverity severity;

  /// Optional opaque note for tooling / debug — no user-visible copy in Core.
  final String? description;

  final int? count;
}

@immutable
class DriverBehaviorScoreBreakdown {
  const DriverBehaviorScoreBreakdown({
    required this.speedPenalty,
    required this.stopPenalty,
    required this.ignitionPenalty,
    required this.efficiencyPenalty,
    required this.shortTripPenalty,
    required this.confidencePenalty,
    required this.totalPenalty,
    required this.baseScore,
  });

  /// Overspeed (+ severe peaks when applicable).
  final double speedPenalty;

  /// Excessive stops / long dwell time proxy.
  final double stopPenalty;

  /// Ignition transitions noise (skipped when ignition unknown).
  final double ignitionPenalty;

  /// Mild low-average-speed + congestion heuristic.
  final double efficiencyPenalty;

  /// Reserved — usually 0; Phase 9A uses [confidencePenalty] + non-scorable path.
  final double shortTripPenalty;

  /// Confidence / fairness adjustments (normally 0 in 9A).
  final double confidencePenalty;

  /// Sum of capped category penalties before global [DriverBehaviorScoreConfig.maxTotalPenalty].
  final double totalPenalty;

  /// Starting score before penalties (normally 100).
  final double baseScore;
}

@immutable
class DriverBehaviorScore {
  const DriverBehaviorScore({
    required this.score,
    required this.riskLevel,
    required this.classificationCode,
    required this.breakdown,
    required this.factors,
    required this.isScorable,
  });

  /// Trip-level numeric score ∈ \[0, 100\].
  ///
  /// When [!isScorable], this implementation fixes **score = 0** and sets
  /// [riskLevel] to [DriverRiskLevel.unknown] (`docs/driver_behavior_score_overview.md`).
  final int score;

  final DriverRiskLevel riskLevel;

  /// Stable label for analytics / localization: `excellent`, `good`, etc.
  final String classificationCode;

  final DriverBehaviorScoreBreakdown breakdown;

  final List<DriverBehaviorScoreFactor> factors;

  final bool isScorable;
}
