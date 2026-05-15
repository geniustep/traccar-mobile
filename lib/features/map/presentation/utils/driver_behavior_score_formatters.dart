import '../../../../core/l10n/app_localizations.dart';
import '../../core/driver_behavior_score_models.dart';

/// Phase 9B–9C — localized presentation helpers (no Calculator changes).
abstract final class DriverBehaviorScoreUi {
  DriverBehaviorScoreUi._();

  static String riskLevelLabel(AppLocalizations l10n, DriverRiskLevel level) =>
      switch (level) {
        DriverRiskLevel.excellent => l10n.driverScoreExcellent,
        DriverRiskLevel.good => l10n.driverScoreGood,
        DriverRiskLevel.moderate => l10n.driverScoreModerate,
        DriverRiskLevel.highRisk => l10n.driverScoreHighRisk,
        DriverRiskLevel.unknown => l10n.driverScoreUnknown,
      };

  /// One-line summary for list cards — never exposes numeric `0` as a rating when [!isScorable].
  static String tripScoreSummaryLine(AppLocalizations l10n, DriverBehaviorScore score) {
    if (!score.isScorable) {
      return tripNotScorableLine(l10n, score);
    }
    return '${l10n.driverScoreLabel} ${score.score} · ${riskLevelLabel(l10n, score.riskLevel)}';
  }

  static String tripNotScorableLine(AppLocalizations l10n, DriverBehaviorScore score) {
    final invalid =
        score.factors.any((f) => f.type == 'invalidTrip' || f.code == 'invalidTrip');
    if (invalid) {
      return l10n.driverScoreNotScorable;
    }
    return '${l10n.driverScoreNotScorable} · ${l10n.driverScoreTripTooShort}';
  }

  static bool _isInvalidTrip(DriverBehaviorScore score) =>
      score.factors.any((f) => f.code == 'invalidTrip');

  /// User-facing explanation when [!isScorable] (no raw codes).
  static String notScorableExplanation(AppLocalizations l10n, DriverBehaviorScore score) {
    if (_isInvalidTrip(score)) {
      return l10n.driverScoreNotReliableEnough;
    }
    return l10n.driverScoreReasonShortTrip;
  }

  static String riskReliabilityLine(AppLocalizations l10n, DriverBehaviorScore score) {
    if (!score.isScorable) return '';
    return l10n.driverScoreReliableEnough;
  }

  /// Maps internal factor [code] to a non-technical label (Phase 9C sheet).
  static String factorLabel(AppLocalizations l10n, DriverBehaviorScoreFactor factor) =>
      switch (factor.code) {
        'overspeed' => l10n.driverScoreReasonOverspeed,
        'heavyOverspeed' => l10n.driverScoreReasonHeavyOverspeed,
        'longStops' => l10n.driverScoreReasonLongStops,
        'excessiveStops' => l10n.driverScoreReasonExcessiveStops,
        'ignitionTransitions' => l10n.driverScoreReasonIgnitionTransitions,
        'lowFlow' => l10n.driverScoreReasonLowEfficiency,
        'cleanTrip' => l10n.driverScoreReasonCleanTrip,
        'shortTrip' => l10n.driverScoreReasonShortTrip,
        'invalidTrip' => l10n.driverScoreNotReliableEnough,
        _ => l10n.driverScoreFactorOther,
      };

  static String? _severitySuffix(
    AppLocalizations l10n,
    DriverBehaviorFactorSeverity severity,
  ) =>
      switch (severity) {
        DriverBehaviorFactorSeverity.info => null,
        DriverBehaviorFactorSeverity.low => l10n.driverScoreSeverityLow,
        DriverBehaviorFactorSeverity.medium => l10n.driverScoreSeverityMedium,
        DriverBehaviorFactorSeverity.high => l10n.driverScoreSeverityHigh,
      };

  /// One line per factor for the details sheet (localized; may include points & count).
  static String factorDetailLine(AppLocalizations l10n, DriverBehaviorScoreFactor factor) {
    var text = factorLabel(l10n, factor);
    final sev = _severitySuffix(l10n, factor.severity);
    if (sev != null) {
      text = '$text ($sev)';
    }
    if (factor.points > 1e-9) {
      text = '$text · −${formatPenaltyPoints(factor.points)}';
    }
    if (factor.count != null && factor.count! > 1) {
      text = '$text ${l10n.driverScoreFactorOccurrences(factor.count!)}';
    }
    return text;
  }

  static String formatPenaltyPoints(double value) {
    if (value <= 1e-9) return '0';
    final r = value.roundToDouble();
    if ((value - r).abs() < 1e-9) {
      return r.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  /// Non-zero breakdown rows only (for scorable trips).
  static List<String> scorablePenaltyBreakdownLines(
    AppLocalizations l10n,
    DriverBehaviorScoreBreakdown b,
  ) {
    final out = <String>[];
    void add(double v, String categoryTitle) {
      if (v <= 1e-9) return;
      out.add(
        l10n.driverScorePenaltyLine(categoryTitle, formatPenaltyPoints(v)),
      );
    }
    add(b.speedPenalty, l10n.driverScoreSpeedPenalty);
    add(b.stopPenalty, l10n.driverScoreStopPenalty);
    add(b.ignitionPenalty, l10n.driverScoreIgnitionPenalty);
    add(b.efficiencyPenalty, l10n.driverScoreEfficiencyPenalty);
    return out;
  }

  static bool isSteadyScorableTrip(DriverBehaviorScore score) =>
      score.isScorable && score.breakdown.totalPenalty < 1e-6;

  static List<DriverBehaviorScoreFactor> factorsForDetailsSheet(
    DriverBehaviorScore score,
  ) {
    if (!score.isScorable) return const [];
    return score.factors
        .where((f) => f.code != 'shortTrip' && f.code != 'invalidTrip')
        .toList()
      ..sort((a, b) {
        final c = b.points.compareTo(a.points);
        if (c != 0) return c;
        return a.code.compareTo(b.code);
      });
  }
}
