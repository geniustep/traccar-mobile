import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../reports/core/replay_route_gap.dart';
import 'route_event_models.dart';

/// Kind of unified row in [RouteEventTimeline].
enum RouteTimelineEntryKind {
  stop,
  overspeed,
  ignitionOn,
  ignitionOff,

  /// Missing GPS interval on replay (Phase R1).
  dataGap,

  /// Route departure (replay timeline — Phase R3).
  routeStart,

  /// Route arrival (replay timeline — Phase R3).
  routeEnd,

  /// Backend / report event (replay — Phase R4).
  externalEvent,
}

/// Flattened, time-sorted route event for the shared timeline widget.
@immutable
class RouteEventTimelineItem {
  const RouteEventTimelineItem({
    required this.selectionKey,
    required this.kind,
    required this.sortTime,
    required this.position,
    required this.title,
    required this.primaryTimeLabel,
    required this.detailLine,
    this.stopStartTime,
    this.stopEndTime,
    this.stopAddress,
    this.overspeedMaxSpeedKmh,
  });

  /// See [routeEventTimelineSelectionKey] — matches map intelligence markers.
  final String selectionKey;

  final RouteTimelineEntryKind kind;
  final DateTime sortTime;
  final LatLng position;
  final String title;
  final String primaryTimeLabel;
  final String detailLine;

  /// Populated for [RouteTimelineEntryKind.stop] by [buildRouteEventTimelineItems].
  final DateTime? stopStartTime;

  /// Populated for [RouteTimelineEntryKind.stop] by [buildRouteEventTimelineItems].
  final DateTime? stopEndTime;

  /// Optional reverse-geocoded label when the central system provides it.
  final String? stopAddress;

  /// Populated for [RouteTimelineEntryKind.overspeed] by [buildRouteEventTimelineItems].
  final double? overspeedMaxSpeedKmh;

  RouteEventTimelineItem copyWith({
    String? selectionKey,
    RouteTimelineEntryKind? kind,
    DateTime? sortTime,
    LatLng? position,
    String? title,
    String? primaryTimeLabel,
    String? detailLine,
    DateTime? stopStartTime,
    DateTime? stopEndTime,
    String? stopAddress,
    double? overspeedMaxSpeedKmh,
  }) {
    return RouteEventTimelineItem(
      selectionKey: selectionKey ?? this.selectionKey,
      kind: kind ?? this.kind,
      sortTime: sortTime ?? this.sortTime,
      position: position ?? this.position,
      title: title ?? this.title,
      primaryTimeLabel: primaryTimeLabel ?? this.primaryTimeLabel,
      detailLine: detailLine ?? this.detailLine,
      stopStartTime: stopStartTime ?? this.stopStartTime,
      stopEndTime: stopEndTime ?? this.stopEndTime,
      stopAddress: stopAddress ?? this.stopAddress,
      overspeedMaxSpeedKmh: overspeedMaxSpeedKmh ?? this.overspeedMaxSpeedKmh,
    );
  }
}

bool routeEventTimelineValidPosition(LatLng p) =>
    p.latitude.abs() > 1e-6 || p.longitude.abs() > 1e-6;

/// Shared id for timeline row + map marker for the same route event (Phase 7C).
///
/// [kindCode]: `s` stop, `o` overspeed, `i1` / `i0` ignition on/off.
String routeEventTimelineSelectionKey({
  required String kindCode,
  required DateTime anchorUtc,
  required double lat,
  required double lng,
}) {
  final t = anchorUtc.toUtc().millisecondsSinceEpoch;
  return 'rint_${kindCode}_${t}_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
}

/// Selection key for a stop event (matches [RouteEventTimelineItem.selectionKey] for stops).
String routeStopSelectionKey(RouteStopEvent s) => routeEventTimelineSelectionKey(
      kindCode: 's',
      anchorUtc: s.startTime,
      lat: s.latitude,
      lng: s.longitude,
    );

/// Compact stop duration for timeline rows and detail sheets (no dependency on locale).
String formatRouteTimelineStopDurationCompact(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// One timeline row for a stop — shared by [buildRouteEventTimelineItems] and map markers.
RouteEventTimelineItem? routeEventTimelineItemForStop(
  RouteStopEvent s,
  AppLocalizations l10n,
) {
  final pos = LatLng(s.latitude, s.longitude);
  if (!routeEventTimelineValidPosition(pos)) return null;
  final hm = DateFormat.Hm();
  var detail =
      '${l10n.stopDurationLabel}: ${formatRouteTimelineStopDurationCompact(s.duration)}';
  final addr = s.address?.trim();
  if (addr != null && addr.isNotEmpty) {
    detail = '$detail · $addr';
  }
  return RouteEventTimelineItem(
    selectionKey: routeEventTimelineSelectionKey(
      kindCode: 's',
      anchorUtc: s.startTime,
      lat: s.latitude,
      lng: s.longitude,
    ),
    kind: RouteTimelineEntryKind.stop,
    sortTime: s.startTime,
    position: pos,
    title: l10n.reportsStops,
    primaryTimeLabel:
        '${hm.format(s.startTime.toLocal())}–${hm.format(s.endTime.toLocal())}',
    detailLine: detail,
    stopStartTime: s.startTime,
    stopEndTime: s.endTime,
    stopAddress: (addr != null && addr.isNotEmpty) ? addr : null,
  );
}

/// One timeline row for an overspeed peak.
RouteEventTimelineItem? routeEventTimelineItemForOverspeed(
  RouteOverspeedEvent o,
  AppLocalizations l10n,
) {
  final pos = LatLng(o.latitude, o.longitude);
  if (!routeEventTimelineValidPosition(pos)) return null;
  return RouteEventTimelineItem(
    selectionKey: routeEventTimelineSelectionKey(
      kindCode: 'o',
      anchorUtc: o.time,
      lat: o.latitude,
      lng: o.longitude,
    ),
    kind: RouteTimelineEntryKind.overspeed,
    sortTime: o.time,
    position: pos,
    title: l10n.overspeedEvents,
    primaryTimeLabel: DateFormat.Hms().format(o.time.toLocal()),
    detailLine: '${l10n.maxSpeedLabel}: ${FormatUtils.speed(o.speed)}',
    overspeedMaxSpeedKmh: o.speed,
  );
}

/// One timeline row for a replay data gap (missing GPS between fixes).
RouteEventTimelineItem? routeEventTimelineItemForReplayGap(
  ReplayRouteGap gap,
  AppLocalizations l10n,
) {
  final pos = gap.markerPosition;
  if (!routeEventTimelineValidPosition(pos)) return null;
  final hm = DateFormat.Hm();
  return RouteEventTimelineItem(
    selectionKey: routeEventTimelineSelectionKey(
      kindCode: 'g',
      anchorUtc: gap.gapEndTime,
      lat: pos.latitude,
      lng: pos.longitude,
    ),
    kind: RouteTimelineEntryKind.dataGap,
    sortTime: gap.gapEndTime,
    position: pos,
    title: l10n.replayMissingData,
    primaryTimeLabel:
        '${hm.format(gap.gapStartTime.toLocal())}–${hm.format(gap.gapEndTime.toLocal())}',
    detailLine:
        '${l10n.replayGapDurationLabel}: ${formatRouteTimelineStopDurationCompact(gap.duration)}',
    stopStartTime: gap.gapStartTime,
    stopEndTime: gap.gapEndTime,
  );
}

List<RouteEventTimelineItem> buildReplayGapTimelineItems(
  List<ReplayRouteGap> gaps,
  AppLocalizations l10n,
) {
  final items = <RouteEventTimelineItem>[];
  for (final g in gaps) {
    final item = routeEventTimelineItemForReplayGap(g, l10n);
    if (item != null) items.add(item);
  }
  items.sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return items;
}

/// Merges analyzer timeline rows with optional replay gap rows (sorted).
List<RouteEventTimelineItem> mergeRouteEventTimelineItems(
  List<RouteEventTimelineItem> base,
  List<RouteEventTimelineItem> supplemental,
) {
  if (supplemental.isEmpty) return base;
  if (base.isEmpty) return List<RouteEventTimelineItem>.from(supplemental);
  final merged = [...base, ...supplemental]
    ..sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return merged;
}

/// One timeline row for an ignition transition.
RouteEventTimelineItem? routeEventTimelineItemForIgnition(
  RouteIgnitionEvent e,
  AppLocalizations l10n,
) {
  final pos = LatLng(e.latitude, e.longitude);
  if (!routeEventTimelineValidPosition(pos)) return null;
  final on = e.on;
  return RouteEventTimelineItem(
    selectionKey: routeEventTimelineSelectionKey(
      kindCode: on ? 'i1' : 'i0',
      anchorUtc: e.time,
      lat: e.latitude,
      lng: e.longitude,
    ),
    kind: on ? RouteTimelineEntryKind.ignitionOn : RouteTimelineEntryKind.ignitionOff,
    sortTime: e.time,
    position: pos,
    title: on ? l10n.ignitionOnLabel : l10n.ignitionOffLabel,
    primaryTimeLabel: DateFormat.Hms().format(e.time.toLocal()),
    detailLine: on ? l10n.ignitionOnLabel : l10n.ignitionOffLabel,
  );
}

/// Builds display rows from analyzer output — no analyzer calls, passes [AppLocalizations] only.
List<RouteEventTimelineItem> buildRouteEventTimelineItems(
  RouteEventAnalysisResult analysis,
  AppLocalizations l10n,
) {
  final items = <RouteEventTimelineItem>[];

  for (final s in analysis.stops) {
    final item = routeEventTimelineItemForStop(s, l10n);
    if (item != null) items.add(item);
  }

  for (final o in analysis.overspeeds) {
    final item = routeEventTimelineItemForOverspeed(o, l10n);
    if (item != null) items.add(item);
  }

  if (analysis.ignitionDataLikelyPresent) {
    for (final e in analysis.ignitions) {
      final item = routeEventTimelineItemForIgnition(e, l10n);
      if (item != null) items.add(item);
    }
  }

  items.sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return items;
}

/// Phase 7E — timeline list filter (UI only; does not re-run [RouteEventAnalyzer]).
enum RouteEventTimelineFilter {
  all,
  stops,
  overspeed,
  ignition,

  /// Missing GPS gaps (replay — Phase R3).
  dataGaps,

  /// Backend alerts & non-analyzer events (replay — Phase R4).
  alerts,
}

bool routeEventTimelineItemMatchesFilter(
  RouteEventTimelineItem item,
  RouteEventTimelineFilter filter,
) {
  switch (filter) {
    case RouteEventTimelineFilter.all:
      return true;
    case RouteEventTimelineFilter.stops:
      return item.kind == RouteTimelineEntryKind.stop;
    case RouteEventTimelineFilter.overspeed:
      return item.kind == RouteTimelineEntryKind.overspeed;
    case RouteEventTimelineFilter.ignition:
      return item.kind == RouteTimelineEntryKind.ignitionOn ||
          item.kind == RouteTimelineEntryKind.ignitionOff;
    case RouteEventTimelineFilter.dataGaps:
      return item.kind == RouteTimelineEntryKind.dataGap;
    case RouteEventTimelineFilter.alerts:
      return item.kind == RouteTimelineEntryKind.externalEvent;
  }
}

bool routeEventTimelineItemIsReplayGap(RouteEventTimelineItem item) =>
    item.kind == RouteTimelineEntryKind.dataGap;

List<RouteEventTimelineItem> routeEventTimelineItemsFiltered(
  List<RouteEventTimelineItem> items,
  RouteEventTimelineFilter filter,
) {
  if (filter == RouteEventTimelineFilter.all) return items;
  return items
      .where((e) => routeEventTimelineItemMatchesFilter(e, filter))
      .toList(growable: false);
}

@immutable
class RouteEventTimelineFilterCounts {
  const RouteEventTimelineFilterCounts({
    required this.all,
    required this.stops,
    required this.overspeed,
    required this.ignition,
    required this.dataGaps,
    required this.alerts,
  });

  final int all;
  final int stops;
  final int overspeed;
  final int ignition;
  final int dataGaps;
  final int alerts;
}

RouteEventTimelineFilterCounts routeEventTimelineFilterCounts(
  List<RouteEventTimelineItem> items,
) {
  var stops = 0;
  var overspeed = 0;
  var ignition = 0;
  var dataGaps = 0;
  var alerts = 0;
  for (final i in items) {
    switch (i.kind) {
      case RouteTimelineEntryKind.stop:
        stops++;
        break;
      case RouteTimelineEntryKind.overspeed:
        overspeed++;
        break;
      case RouteTimelineEntryKind.ignitionOn:
      case RouteTimelineEntryKind.ignitionOff:
        ignition++;
        break;
      case RouteTimelineEntryKind.dataGap:
        dataGaps++;
        break;
      case RouteTimelineEntryKind.externalEvent:
        alerts++;
        break;
      case RouteTimelineEntryKind.routeStart:
      case RouteTimelineEntryKind.routeEnd:
        break;
    }
  }
  return RouteEventTimelineFilterCounts(
    all: items.length,
    stops: stops,
    overspeed: overspeed,
    ignition: ignition,
    dataGaps: dataGaps,
    alerts: alerts,
  );
}

/// Event counts for replay timeline summary (Phase R3).
@immutable
class RouteTimelineEventSummaryCounts {
  const RouteTimelineEventSummaryCounts({
    required this.stops,
    required this.overspeed,
    required this.ignition,
    required this.dataGaps,
  });

  final int stops;
  final int overspeed;
  final int ignition;
  final int dataGaps;

  bool get isEmpty =>
      stops == 0 && overspeed == 0 && ignition == 0 && dataGaps == 0;
}

RouteTimelineEventSummaryCounts routeTimelineEventSummaryCounts(
  List<RouteEventTimelineItem> items,
) {
  var stops = 0;
  var overspeed = 0;
  var ignition = 0;
  var dataGaps = 0;
  for (final i in items) {
    switch (i.kind) {
      case RouteTimelineEntryKind.stop:
        stops++;
        break;
      case RouteTimelineEntryKind.overspeed:
        overspeed++;
        break;
      case RouteTimelineEntryKind.ignitionOn:
      case RouteTimelineEntryKind.ignitionOff:
        ignition++;
        break;
      case RouteTimelineEntryKind.dataGap:
        dataGaps++;
        break;
      case RouteTimelineEntryKind.externalEvent:
        break;
      case RouteTimelineEntryKind.routeStart:
      case RouteTimelineEntryKind.routeEnd:
        break;
    }
  }
  return RouteTimelineEventSummaryCounts(
    stops: stops,
    overspeed: overspeed,
    ignition: ignition,
    dataGaps: dataGaps,
  );
}

/// One-line summary above replay timeline (Phase R3).
String? formatRouteTimelineSummaryLine(
  List<RouteEventTimelineItem> items,
  AppLocalizations l10n,
) {
  final c = routeTimelineEventSummaryCounts(items);
  if (c.isEmpty) return null;
  final parts = <String>[];
  if (c.stops > 0) {
    parts.add(l10n.replayTimelineSummaryStops(c.stops));
  }
  if (c.overspeed > 0) {
    parts.add(l10n.replayTimelineSummaryOverspeed(c.overspeed));
  }
  if (c.dataGaps > 0) {
    parts.add(l10n.replayTimelineSummaryDataGaps(c.dataGaps));
  }
  if (c.ignition > 0) {
    parts.add(l10n.replayTimelineSummaryIgnition(c.ignition));
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
