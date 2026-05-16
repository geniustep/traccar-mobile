import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../map/core/route_event_models.dart';
import '../../../map/core/route_event_timeline_models.dart';
import '../../../map/presentation/widgets/route_event_timeline.dart';
/// Full trip events list for Single Replay (UI-2 — map-first layout).
void showReplayEventsBottomSheet(
  BuildContext context, {
  required String routeIntelKey,
  required RouteEventAnalysisResult? routeIntel,
  required List<RouteEventTimelineItem> supplementalTimelineItems,
  required List<RouteEventTimelineItem> externalTimelineItems,
  required RouteEventTimelineFilter timelineFilter,
  required ValueChanged<RouteEventTimelineFilter> onTimelineFilterChanged,
  required ValueChanged<RouteEventTimelineItem> onTimelineItemTap,
  String? selectedTimelineItemKey,
}) {
  final l10n = AppLocalizations.of(context);
  final listHeight = MediaQuery.sizeOf(context).height * 0.52;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.routeEventsTimelineTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(ctx),
              ),
            ),
            const SizedBox(height: 10),
            RouteEventTimeline(
              analysisKey: routeIntelKey,
              analysis: routeIntel,
              supplementalTimelineItems: supplementalTimelineItems,
              externalTimelineItems: externalTimelineItems,
              showReplayEventSummary: true,
              compact: false,
              reportStyle: true,
              showEmptyState: true,
              collapsedItemLimit: 9999,
              listHeightOverride: listHeight,
              deprioritizeAlertsWhenCollapsed:
                  externalTimelineItems.length >= 10,
              selectedItemKey: selectedTimelineItemKey,
              filter: timelineFilter,
              onFilterChanged: onTimelineFilterChanged,
              onItemTap: (item) {
                Navigator.of(ctx).pop();
                onTimelineItemTap(item);
              },
            ),
          ],
        ),
      );
    },
  );
}
