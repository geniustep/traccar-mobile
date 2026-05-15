import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/driver_behavior_score_models.dart';
import '../../core/trip_segment_models.dart';
import '../utils/driver_behavior_score_formatters.dart';

/// Phase 9C — modal with non-technical breakdown of a trip behavior score.
class TripBehaviorScoreDetailsSheet extends StatelessWidget {
  const TripBehaviorScoreDetailsSheet({
    super.key,
    required this.score,
    this.trip,
    this.tripTitle,
  });

  /// [trip] is optional context (e.g. to infer a default title from [TripSegment.index]).
  final DriverBehaviorScore score;
  final TripSegment? trip;
  final String? tripTitle;

  static Future<void> show(
    BuildContext context, {
    required DriverBehaviorScore score,
    TripSegment? trip,
    String? tripTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => TripBehaviorScoreDetailsSheet(
        score: score,
        trip: trip,
        tripTitle: tripTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final resolvedTitle = tripTitle ?? (trip != null ? l10n.tripTitle(trip!.index) : null);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.driverScoreDetailsTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            if (resolvedTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                resolvedTitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ..._body(context, l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, AppLocalizations l10n) {
    final muted = AppColors.textMutedOf(context);
    final secondary = AppColors.textSecondaryOf(context);

    if (!score.isScorable) {
      return [
        Text(
          l10n.driverScoreNotScorable,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.driverScoreTripScoredNo,
          style: TextStyle(fontSize: 12, color: secondary),
        ),
        const SizedBox(height: 12),
        Text(
          DriverBehaviorScoreUi.notScorableExplanation(l10n, score),
          style: TextStyle(fontSize: 13, height: 1.35, color: secondary),
        ),
      ];
    }

    final steady = DriverBehaviorScoreUi.isSteadyScorableTrip(score);
    final breakdownLines =
        DriverBehaviorScoreUi.scorablePenaltyBreakdownLines(l10n, score.breakdown);
    final factors = DriverBehaviorScoreUi.factorsForDetailsSheet(score);

    return [
      Text(
        l10n.driverScoreTripScoredYes,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
      ),
      const SizedBox(height: 8),
      Text(
        '${l10n.driverScoreLabel} ${score.score} · ${DriverBehaviorScoreUi.riskLevelLabel(l10n, score.riskLevel)}',
        style: AppTextStyles.headlineMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        DriverBehaviorScoreUi.riskReliabilityLine(l10n, score),
        style: TextStyle(fontSize: 12, height: 1.3, color: muted),
      ),
      const SizedBox(height: 14),
      Text(
        l10n.driverScoreBaseScore(
          DriverBehaviorScoreUi.formatPenaltyPoints(score.breakdown.baseScore),
        ),
        style: TextStyle(fontSize: 12, color: secondary),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.driverScoreTotalPenalty(
          DriverBehaviorScoreUi.formatPenaltyPoints(score.breakdown.totalPenalty),
        ),
        style: TextStyle(fontSize: 12, color: secondary),
      ),
      if (steady) ...[
        const SizedBox(height: 12),
        Text(
          l10n.driverScoreSteadyDriving,
          style: TextStyle(fontSize: 13, height: 1.35, color: secondary),
        ),
      ] else if (breakdownLines.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...breakdownLines.expand(
          (line) => [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(fontSize: 12, height: 1.3, color: secondary),
              ),
            ),
          ],
        ),
      ],
      if (!steady && factors.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          l10n.driverScoreFactorsTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: muted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        ...factors.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              DriverBehaviorScoreUi.factorDetailLine(l10n, f),
              style: TextStyle(fontSize: 12, height: 1.35, color: secondary),
            ),
          ),
        ),
      ],
    ];
  }
}
