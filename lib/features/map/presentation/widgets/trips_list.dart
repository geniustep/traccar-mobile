import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/driver_behavior_score_models.dart';
import '../../core/trip_segment_models.dart';
import '../utils/trip_formatters.dart';
import 'trip_behavior_score_badge.dart';
import 'trip_behavior_score_details_sheet.dart';

/// Read-only scrollable summary of segmented trips for the tracking / report context.
class TripsListSection extends StatelessWidget {
  const TripsListSection({
    super.key,
    required this.trips,
    required this.scoresByTripKey,
    required this.onOpenMap,
    required this.onOpenReplay,
  });

  final List<TripSegment> trips;
  /// Precomputed beside [trips] (same memo key) — see [VehicleTrackingScreen] Phase 9B.
  final Map<String, DriverBehaviorScore> scoresByTripKey;
  final ValueChanged<TripSegment> onOpenMap;
  final ValueChanged<TripSegment> onOpenReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.alt_route_rounded,
                size: 16, color: AppColors.accent.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Text(
              l10n.tripsTitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (trips.isEmpty)
          Text(
            TripUiFormatters.tripsNone(l10n),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = trips[i];
              return _TripCard(
                trip: t,
                behaviorScore: scoresByTripKey[t.selectionKey],
                l10n: l10n,
                onOpenMap: () => onOpenMap(t),
                onOpenReplay: () => onOpenReplay(t),
              );
            },
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.behaviorScore,
    required this.l10n,
    required this.onOpenMap,
    required this.onOpenReplay,
  });

  final TripSegment trip;
  final DriverBehaviorScore? behaviorScore;
  final AppLocalizations l10n;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenReplay;

  @override
  Widget build(BuildContext context) {
    final ignition = TripUiFormatters.tripIgnitionLine(l10n, trip);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderOf(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TripUiFormatters.tripTitle(l10n, trip.index),
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            TripUiFormatters.tripTimeRangeHm(l10n, trip),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            TripUiFormatters.tripSubtitleLine(l10n, trip),
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          if (behaviorScore != null) ...[
            const SizedBox(height: 6),
            TripBehaviorScoreBadge(
              score: behaviorScore!,
              onTap: () => TripBehaviorScoreDetailsSheet.show(
                context,
                score: behaviorScore!,
                trip: trip,
                tripTitle: TripUiFormatters.tripTitle(l10n, trip.index),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            TripUiFormatters.tripMaxSpeedShort(l10n, trip),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMutedOf(context),
            ),
          ),
          if (ignition != null) ...[
            const SizedBox(height: 2),
            Text(
              ignition,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(l10n.tripViewOnMap),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppColors.borderOf(context)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenReplay,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                  label: Text(l10n.tripReplay),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
