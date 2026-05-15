import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/driver_behavior_score_models.dart';
import '../utils/driver_behavior_score_formatters.dart';

/// Compact single-line trip behavior score for list cards (Phase 9B).
/// Optional [onTap] opens details (Phase 9C).
class TripBehaviorScoreBadge extends StatelessWidget {
  const TripBehaviorScoreBadge({
    super.key,
    required this.score,
    this.onTap,
  });

  final DriverBehaviorScore score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = DriverBehaviorScoreUi.tripScoreSummaryLine(l10n, score);
    final color = score.isScorable
        ? AppColors.textSecondaryOf(context)
        : AppColors.textMutedOf(context);

    final text = Text(
      line,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
        decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
        decorationColor: color.withValues(alpha: 0.35),
      ),
    );

    if (onTap == null) return text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: text,
        ),
      ),
    );
  }
}
