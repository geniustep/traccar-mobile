import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/presentation/utils/driver_behavior_score_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10nEn = AppLocalizations(const Locale('en'));
  final l10nFr = AppLocalizations(const Locale('fr'));

  group('DriverBehaviorScoreUi.riskLevelLabel', () {
    test('maps all risk levels to non-empty localized strings', () {
      for (final level in DriverRiskLevel.values) {
        final s = DriverBehaviorScoreUi.riskLevelLabel(l10nEn, level);
        expect(s, isNotEmpty);
        expect(s.toLowerCase(), isNot(contains('traccar')));
      }
    });

    test('FR high risk uses surveillance wording', () {
      expect(
        DriverBehaviorScoreUi.riskLevelLabel(l10nFr, DriverRiskLevel.highRisk),
        contains('surveill'),
      );
    });
  });

  group('DriverBehaviorScoreUi.tripScoreSummaryLine', () {
    test('excellent shows score and label', () {
      const score = DriverBehaviorScore(
        score: 92,
        riskLevel: DriverRiskLevel.excellent,
        classificationCode: 'excellent',
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: 0,
          stopPenalty: 0,
          ignitionPenalty: 0,
          efficiencyPenalty: 0,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: 0,
          baseScore: 100,
        ),
        factors: [],
        isScorable: true,
      );
      final line = DriverBehaviorScoreUi.tripScoreSummaryLine(l10nEn, score);
      expect(line, contains('92'));
      expect(line, contains(l10nEn.driverScoreExcellent));
      expect(line, isNot(contains('Not rated')));
    });

    test('not scorable never shows “Score 0” pattern for EN', () {
      const bad = DriverBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        classificationCode: 'unknown',
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: 0,
          stopPenalty: 0,
          ignitionPenalty: 0,
          efficiencyPenalty: 0,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: 0,
          baseScore: 100,
        ),
        factors: [
          DriverBehaviorScoreFactor(
            code: 'shortTrip',
            type: 'shortTrip',
            points: 0,
          ),
        ],
        isScorable: false,
      );
      final line = DriverBehaviorScoreUi.tripScoreSummaryLine(l10nEn, bad);
      expect(line, isNot(contains('${l10nEn.driverScoreLabel} 0')));
      expect(line, contains(l10nEn.driverScoreNotScorable));
    });

    test('invalid trip shows only not-rated line', () {
      const invalid = DriverBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        classificationCode: 'unknown',
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: 0,
          stopPenalty: 0,
          ignitionPenalty: 0,
          efficiencyPenalty: 0,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: 0,
          baseScore: 100,
        ),
        factors: [
          DriverBehaviorScoreFactor(
            code: 'invalidTrip',
            type: 'invalidTrip',
            points: 0,
          ),
        ],
        isScorable: false,
      );
      final line = DriverBehaviorScoreUi.tripScoreSummaryLine(l10nEn, invalid);
      expect(line, l10nEn.driverScoreNotScorable);
      expect(line, isNot(contains(l10nEn.driverScoreTripTooShort)));
    });

    test('moderate + good strings differ', () {
      final m = DriverBehaviorScoreUi.riskLevelLabel(
          l10nEn, DriverRiskLevel.moderate,);
      final g = DriverBehaviorScoreUi.riskLevelLabel(l10nEn, DriverRiskLevel.good);
      expect(m, isNot(equals(g)));
    });
  });

  group('DriverBehaviorScoreUi.factorLabel / factorDetailLine', () {
    test('overspeed maps to user-facing reason', () {
      const f = DriverBehaviorScoreFactor(
        code: 'overspeed',
        type: 'overspeed',
        points: 5,
      );
      expect(
        DriverBehaviorScoreUi.factorLabel(l10nEn, f),
        l10nEn.driverScoreReasonOverspeed,
      );
      expect(
        DriverBehaviorScoreUi.factorDetailLine(l10nEn, f),
        contains(l10nEn.driverScoreReasonOverspeed),
      );
      expect(
        DriverBehaviorScoreUi.factorDetailLine(l10nEn, f),
        contains('5'),
      );
      expect(
        DriverBehaviorScoreUi.factorDetailLine(l10nEn, f).toLowerCase(),
        isNot(contains('overspeed')),
      );
    });

    test('heavyOverspeed maps without raw code', () {
      const f = DriverBehaviorScoreFactor(
        code: 'heavyOverspeed',
        type: 'heavyOverspeed',
        points: 10,
        severity: DriverBehaviorFactorSeverity.high,
      );
      final line = DriverBehaviorScoreUi.factorDetailLine(l10nEn, f);
      expect(line, contains(l10nEn.driverScoreReasonHeavyOverspeed));
      expect(line.toLowerCase(), isNot(contains('heavyoverspeed')));
      expect(line, contains(l10nEn.driverScoreSeverityHigh));
    });
  });

  group('DriverBehaviorScoreUi.notScorableExplanation', () {
    test('shortTrip explains short route', () {
      const s = DriverBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        classificationCode: 'unknown',
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: 0,
          stopPenalty: 0,
          ignitionPenalty: 0,
          efficiencyPenalty: 0,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: 0,
          baseScore: 100,
        ),
        factors: [
          DriverBehaviorScoreFactor(
            code: 'shortTrip',
            type: 'shortTrip',
            points: 0,
          ),
        ],
        isScorable: false,
      );
      expect(
        DriverBehaviorScoreUi.notScorableExplanation(l10nEn, s),
        l10nEn.driverScoreReasonShortTrip,
      );
    });
  });

  group('DriverBehaviorScoreUi.cleanTrip & steady', () {
    test('cleanTrip factor line reads as positive copy', () {
      const f = DriverBehaviorScoreFactor(
        code: 'cleanTrip',
        type: 'cleanTrip',
        points: 0,
      );
      final line = DriverBehaviorScoreUi.factorDetailLine(l10nEn, f);
      expect(line, l10nEn.driverScoreReasonCleanTrip);
    });

    test('breakdown skips zero penalties', () {
      const b = DriverBehaviorScoreBreakdown(
        speedPenalty: 0,
        stopPenalty: 0,
        ignitionPenalty: 0,
        efficiencyPenalty: 0,
        shortTripPenalty: 0,
        confidencePenalty: 0,
        totalPenalty: 0,
        baseScore: 100,
      );
      expect(DriverBehaviorScoreUi.scorablePenaltyBreakdownLines(l10nEn, b), isEmpty);
      const b2 = DriverBehaviorScoreBreakdown(
        speedPenalty: 10,
        stopPenalty: 0,
        ignitionPenalty: 0,
        efficiencyPenalty: 0,
        shortTripPenalty: 0,
        confidencePenalty: 0,
        totalPenalty: 10,
        baseScore: 100,
      );
      final lines = DriverBehaviorScoreUi.scorablePenaltyBreakdownLines(l10nEn, b2);
      expect(lines.length, 1);
      expect(lines.single, contains('10'));
      expect(lines.single.toLowerCase(), isNot(contains('speedpenalty')));
    });

    test('steady scorable detects near-zero total penalty', () {
      const score = DriverBehaviorScore(
        score: 100,
        riskLevel: DriverRiskLevel.excellent,
        classificationCode: 'excellent',
        breakdown: DriverBehaviorScoreBreakdown(
          speedPenalty: 0,
          stopPenalty: 0,
          ignitionPenalty: 0,
          efficiencyPenalty: 0,
          shortTripPenalty: 0,
          confidencePenalty: 0,
          totalPenalty: 0,
          baseScore: 100,
        ),
        factors: [],
        isScorable: true,
      );
      expect(DriverBehaviorScoreUi.isSteadyScorableTrip(score), isTrue);
    });
  });
}
