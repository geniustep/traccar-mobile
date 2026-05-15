import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/replay_route_gap.dart';
import '../../../map/core/route_event_timeline_models.dart';

/// Bottom sheet listing detected replay data gaps (Phase R1).
class ReplayGapsSheet extends StatelessWidget {
  const ReplayGapsSheet({
    super.key,
    required this.gaps,
    required this.timelineItems,
    this.onGapTap,
  });

  final List<ReplayRouteGap> gaps;
  final List<RouteEventTimelineItem> timelineItems;
  final ValueChanged<RouteEventTimelineItem>? onGapTap;

  static Future<void> show(
    BuildContext context, {
    required List<ReplayRouteGap> gaps,
    required List<RouteEventTimelineItem> timelineItems,
    ValueChanged<RouteEventTimelineItem>? onGapTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => ReplayGapsSheet(
        gaps: gaps,
        timelineItems: timelineItems,
        onGapTap: onGapTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hm = DateFormat.Hm();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.replayGapsSheetTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: gaps.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final g = gaps[i];
                final item = i < timelineItems.length ? timelineItems[i] : null;
                return InkWell(
                  onTap: item == null || onGapTap == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onGapTap!(item);
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.replayMissingGpsData,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _row(
                          context,
                          l10n.replayGapStartLabel,
                          hm.format(g.gapStartTime.toLocal()),
                        ),
                        _row(
                          context,
                          l10n.replayGapEndLabel,
                          hm.format(g.gapEndTime.toLocal()),
                        ),
                        _row(
                          context,
                          l10n.replayGapDurationLabel,
                          formatRouteTimelineStopDurationCompact(g.duration),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
