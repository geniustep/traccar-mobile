import '../../map/core/route_event_timeline_models.dart';

/// When local analyzer and backend report the same event within this window,
/// the backend row replaces the local one (Phase R4).
const Duration replayEventDedupeWindow = Duration(seconds: 30);

String? _dedupeCategoryForTimelineKind(RouteTimelineEntryKind kind) {
  switch (kind) {
    case RouteTimelineEntryKind.stop:
      return 'stop';
    case RouteTimelineEntryKind.overspeed:
      return 'overspeed';
    case RouteTimelineEntryKind.ignitionOn:
    case RouteTimelineEntryKind.ignitionOff:
      return 'ignition';
    case RouteTimelineEntryKind.dataGap:
    case RouteTimelineEntryKind.routeStart:
    case RouteTimelineEntryKind.routeEnd:
    case RouteTimelineEntryKind.externalEvent:
      return null;
  }
}

/// Merges [external] into [localAndSupplemental], preferring backend on overlap.
List<RouteEventTimelineItem> mergeTimelineWithExternalEvents({
  required List<RouteEventTimelineItem> localAndSupplemental,
  required List<RouteEventTimelineItem> external,
}) {
  if (external.isEmpty) {
    return List<RouteEventTimelineItem>.from(localAndSupplemental);
  }

  final out = List<RouteEventTimelineItem>.from(localAndSupplemental);

  for (final ext in external) {
    final cat = _dedupeCategoryForTimelineKind(ext.kind);
    if (cat == null) {
      out.add(ext);
      continue;
    }

    final matchIndex = out.indexWhere((local) {
      final localCat = _dedupeCategoryForTimelineKind(local.kind);
      if (localCat != cat) return false;
      final delta = local.sortTime.difference(ext.sortTime).abs();
      return delta <= replayEventDedupeWindow;
    });

    if (matchIndex >= 0) {
      out[matchIndex] = ext;
    } else {
      out.add(ext);
    }
  }

  out.sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return out;
}
