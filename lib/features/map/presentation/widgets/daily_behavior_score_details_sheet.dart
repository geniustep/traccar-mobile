import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/daily_behavior_score_models.dart';
import '../../core/trip_segment_summary.dart';
import '../utils/daily_behavior_score_formatters.dart';
import '../utils/driver_behavior_score_formatters.dart';
import '../utils/trip_formatters.dart';

/// Phase **9F** — readable breakdown of **`DailyVehicleBehaviorScore`** (no Calculator changes).
class DailyBehaviorScoreDetailsSheet extends StatelessWidget {
  const DailyBehaviorScoreDetailsSheet({
    super.key,
    required this.dailyScore,
    this.periodTitle,
  });

  final DailyVehicleBehaviorScore dailyScore;
  final String? periodTitle;

  static Future<void> show(
    BuildContext context, {
    required DailyVehicleBehaviorScore dailyScore,
    String? periodTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DailyBehaviorScoreDetailsSheet(
        dailyScore: dailyScore,
        periodTitle: periodTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.dailyScoreDetailsTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            if (periodTitle != null && periodTitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                periodTitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ..._sheetBody(context, l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _sheetBody(BuildContext context, AppLocalizations l10n) {
    final secondary = TextStyle(fontSize: 13, height: 1.35, color: AppColors.textSecondaryOf(context));
    final muted = TextStyle(fontSize: 11, height: 1.35, color: AppColors.textMutedOf(context));

    final distanceVal = '${formatTripDistanceKmValue(dailyScore.totalDistanceKm)} ${l10n.tripKmUnit}';
    final durVal = formatTripDurationCompact(dailyScore.totalDuration);
    final stopDurVal = formatTripDurationCompact(dailyScore.totalStopDuration);

    List<Widget> commonStatsTail() => [
          _DetailRow(label: l10n.tripDistance, value: distanceVal),
          const SizedBox(height: 8),
          _DetailRow(label: l10n.dailyScoreTotalDuration, value: durVal),
          const SizedBox(height: 8),
          _DetailRow(
            label: l10n.routeEventFilterOverspeed,
            value: '${dailyScore.totalOverspeedEvents}',
          ),
          const SizedBox(height: 8),
          _DetailRow(label: l10n.routeEventFilterStops, value: '${dailyScore.totalStops}'),
          const SizedBox(height: 8),
          _DetailRow(label: l10n.dailyScoreTotalStopDuration, value: stopDurVal),
          const SizedBox(height: 8),
          _DetailRow(label: l10n.dailyScoreEvaluatedTrips, value: '${dailyScore.scorableTrips}'),
          const SizedBox(height: 8),
          _DetailRow(label: l10n.dailyScoreUnscoredTrips, value: '${dailyScore.unscorableTrips}'),
        ];

    final bestTrip = dailyScore.bestTrip;
    final worstTrip = dailyScore.worstTrip;

    if (!dailyScore.isScorable) {
      final out = <Widget>[
        Text(
          l10n.dailyScoreNotScorable,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.dailyScoreInsufficientData, style: secondary),
        const SizedBox(height: 14),
      ];

      if (dailyScore.hasAnyTrips) {
        out.add(_DetailRow(label: l10n.tripsTitle, value: '${dailyScore.totalTrips}'));
        out.add(const SizedBox(height: 12));
        if (dailyScore.scorableTrips == 0) {
          out.add(Text(l10n.dailyScoreNoEvaluatedTrips, style: muted));
          out.add(const SizedBox(height: 12));
        }
        out.addAll(commonStatsTail());
      } else {
        out.add(Text(l10n.dailyScoreNoTrips, style: secondary));
      }

      return out;
    }

    final out = <Widget>[
      Text(
        l10n.driverScoreTripScoredYes,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${l10n.driverScoreLabel} ${dailyScore.score} · '
        '${DriverBehaviorScoreUi.riskLevelLabel(l10n, dailyScore.riskLevel)}',
        style: AppTextStyles.headlineMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      const SizedBox(height: 14),
      _DetailRow(label: l10n.tripsTitle, value: '${dailyScore.totalTrips}'),
    ];

    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.dailyScoreEvaluatedTrips, value: '${dailyScore.scorableTrips}'));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.dailyScoreUnscoredTrips, value: '${dailyScore.unscorableTrips}'));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.tripDistance, value: distanceVal));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.dailyScoreTotalDuration, value: durVal));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(
      label: l10n.routeEventFilterOverspeed,
      value: '${dailyScore.totalOverspeedEvents}',
    ));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.routeEventFilterStops, value: '${dailyScore.totalStops}'));
    out.add(const SizedBox(height: 8));
    out.add(_DetailRow(label: l10n.dailyScoreTotalStopDuration, value: stopDurVal));

    if (bestTrip != null) {
      out.add(const SizedBox(height: 8));
      out.add(_DetailRow(
        label: l10n.dailyScoreBestTripLabel,
        value: TripUiFormatters.tripTitle(l10n, bestTrip.index),
      ));
    }
    if (worstTrip != null) {
      out.add(const SizedBox(height: 8));
      out.add(_DetailRow(
        label: l10n.dailyScoreWorstTripLabel,
        value: TripUiFormatters.tripTitle(l10n, worstTrip.index),
      ));
    }

    if (DailyBehaviorScoreUi.shouldShowUnscoredExcludedHint(dailyScore)) {
      out.addAll([
        const SizedBox(height: 14),
        Text(l10n.dailyScoreUnscoredExcludedHint, style: muted),
      ]);
    }

    return out;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryOf(context),
      height: 1.3,
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondaryOf(context),
      height: 1.3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: valueStyle,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
