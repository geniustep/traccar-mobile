import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/daily_behavior_score_models.dart';
import '../utils/daily_behavior_score_formatters.dart';

/// Phase **9E** — compact read-only summary of **`DailyVehicleBehaviorScore`** above the trips list.
/// Optional **[onTap]** opens **Phase 9F** details sheet from the parent.
class DailyVehicleBehaviorScoreCard extends StatelessWidget {
  const DailyVehicleBehaviorScoreCard({
    super.key,
    required this.dailyScore,
    this.onTap,
  });

  final DailyVehicleBehaviorScore dailyScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    TextStyle muted() =>
        AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedOf(context), height: 1.25);

    TextStyle emphasis() =>
        AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryOf(context),
          height: 1.25,
          fontWeight: FontWeight.w600,
        );

    final summary = DailyBehaviorScoreUi.periodScoreSummaryLine(l10n, dailyScore);

    final bestLine = DailyBehaviorScoreUi.bestTripLine(l10n, dailyScore.bestTrip);
    final worstLine = DailyBehaviorScoreUi.worstTripLine(l10n, dailyScore.worstTrip);

    final radius = BorderRadius.circular(12);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.insights_rounded, size: 15, color: AppColors.accent.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.dailyScoreTitle,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMutedOf(context),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dailyScorePeriodTitle,
          style: muted().copyWith(fontSize: 9.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (dailyScore.isScorable && summary.isNotEmpty) ...[
          Text(
            summary,
            style: emphasis(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(DailyBehaviorScoreUi.periodStatsMidLine(l10n, dailyScore), style: muted()),
          const SizedBox(height: 5),
          Text(DailyBehaviorScoreUi.scorableTripRatioLine(l10n, dailyScore), style: muted()),
        ] else if (dailyScore.hasAnyTrips) ...[
          Text(l10n.dailyScoreNotScorable, style: emphasis()),
          const SizedBox(height: 4),
          Text(l10n.dailyScoreInsufficientData, style: muted()),
          const SizedBox(height: 6),
          Text(l10n.dailyScoreTripCount(dailyScore.totalTrips), style: muted()),
          const SizedBox(height: 5),
          Text(DailyBehaviorScoreUi.periodStatsMidLine(l10n, dailyScore), style: muted()),
        ] else ...[
          Text(l10n.dailyScoreNoTrips, style: muted()),
        ],
        if (dailyScore.isScorable) ...[
          if ((bestLine != null && bestLine.isNotEmpty) ||
              (worstLine != null && worstLine.isNotEmpty)) ...[
            const SizedBox(height: 8),
            if (bestLine != null)
              Text(
                bestLine,
                style: muted(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (bestLine != null && worstLine != null) const SizedBox(height: 3),
            if (worstLine != null)
              Text(
                worstLine,
                style: muted(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ],
        if (onTap != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.dailyScoreTapForDetails,
            style: muted().copyWith(fontSize: 10, fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.all(11),
      child: content,
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          borderRadius: radius,
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: padded,
      );
    }

    return Material(
      color: AppColors.accent.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: padded,
      ),
    );
  }
}
