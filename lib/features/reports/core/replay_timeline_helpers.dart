import 'package:flutter/material.dart' show Locale;
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../map/core/route_event_models.dart';
import '../../map/core/route_event_timeline_models.dart';
import '../../map/data/datasources/route_datasource.dart';
import 'replay_event_deduplication.dart';
import 'replay_route_gap.dart';

/// Local date + time for the current replay position (UI-2).
String formatReplayCurrentPointDateTime(DateTime fixTime, Locale locale) {
  final local = fixTime.toLocal();
  final date = DateFormat('d MMM yyyy', locale.toString()).format(local);
  final time = DateFormat('HH:mm:ss', locale.toString()).format(local);
  return '$date · $time';
}

/// Full merged timeline for replay (analyzer + supplemental + external).
List<RouteEventTimelineItem> buildReplayMergedTimelineItems({
  required String analysisKey,
  required RouteEventAnalysisResult? analysis,
  required AppLocalizations l10n,
  List<RouteEventTimelineItem> supplementalTimelineItems = const [],
  List<RouteEventTimelineItem> externalTimelineItems = const [],
}) {
  final base = (analysis == null || analysisKey == '0')
      ? <RouteEventTimelineItem>[]
      : buildRouteEventTimelineItems(analysis, l10n);
  var merged = mergeRouteEventTimelineItems(base, supplementalTimelineItems);
  if (externalTimelineItems.isNotEmpty) {
    merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: merged,
      external: externalTimelineItems,
    );
  }
  return merged;
}

/// When [counts.alerts] dominate the timeline, collapsed replay should prefer
/// route intelligence rows over bulk backend alerts (filter stays [all]).
bool replayShouldDeprioritizeAlerts(
  RouteEventTimelineFilterCounts counts, {
  int alertThreshold = 10,
}) {
  if (counts.alerts < alertThreshold) return false;
  final routeEvents =
      counts.stops + counts.overspeed + counts.ignition + counts.dataGaps;
  return counts.alerts > routeEvents;
}

/// Route events first, alerts last — used for compact replay collapse only.
List<RouteEventTimelineItem> replayTimelineDisplayOrder(
  List<RouteEventTimelineItem> items, {
  required bool deprioritizeAlerts,
}) {
  if (!deprioritizeAlerts) return items;
  final primary = <RouteEventTimelineItem>[];
  final alerts = <RouteEventTimelineItem>[];
  for (final e in items) {
    if (e.kind == RouteTimelineEntryKind.externalEvent) {
      alerts.add(e);
    } else {
      primary.add(e);
    }
  }
  return [...primary, ...alerts];
}

/// Seek target for a timeline row during replay (Phase R3).
DateTime replayTimelineSeekTimeForItem(RouteEventTimelineItem item) {
  switch (item.kind) {
    case RouteTimelineEntryKind.dataGap:
      return item.stopEndTime ?? item.sortTime;
    case RouteTimelineEntryKind.routeStart:
    case RouteTimelineEntryKind.routeEnd:
    case RouteTimelineEntryKind.stop:
    case RouteTimelineEntryKind.overspeed:
    case RouteTimelineEntryKind.ignitionOn:
    case RouteTimelineEntryKind.ignitionOff:
    case RouteTimelineEntryKind.externalEvent:
      return item.sortTime;
  }
}

/// Start / end rows for replay timeline (Phase R3).
List<RouteEventTimelineItem> buildReplayBoundaryTimelineItems(
  List<RoutePoint> points,
  AppLocalizations l10n,
) {
  if (points.length < 2) return const [];
  final sorted = ReplayRouteGapDetector.sortByFixTime(points);
  final start = sorted.first;
  final end = sorted.last;
  final hm = DateFormat.Hm();

  final items = <RouteEventTimelineItem>[];

  if (routeEventTimelineValidPosition(start.position)) {
    items.add(
      RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'rs',
          anchorUtc: start.fixTime,
          lat: start.position.latitude,
          lng: start.position.longitude,
        ),
        kind: RouteTimelineEntryKind.routeStart,
        sortTime: start.fixTime,
        position: start.position,
        title: l10n.routeTimelineStart,
        primaryTimeLabel: hm.format(start.fixTime.toLocal()),
        detailLine: FormatUtils.speed(start.speed),
      ),
    );
  }

  if (routeEventTimelineValidPosition(end.position)) {
    items.add(
      RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 're',
          anchorUtc: end.fixTime,
          lat: end.position.latitude,
          lng: end.position.longitude,
        ),
        kind: RouteTimelineEntryKind.routeEnd,
        sortTime: end.fixTime,
        position: end.position,
        title: l10n.routeTimelineEnd,
        primaryTimeLabel: hm.format(end.fixTime.toLocal()),
        detailLine: FormatUtils.speed(end.speed),
      ),
    );
  }

  return items;
}

/// Merges replay-only supplemental rows (boundaries + gaps) for the timeline.
List<RouteEventTimelineItem> buildReplaySupplementalTimelineItems({
  required List<RoutePoint> allPoints,
  required List<ReplayRouteGap> gaps,
  required AppLocalizations l10n,
}) {
  final boundary = buildReplayBoundaryTimelineItems(allPoints, l10n);
  final gapRows = buildReplayGapTimelineItems(gaps, l10n);
  return mergeRouteEventTimelineItems(boundary, gapRows);
}

