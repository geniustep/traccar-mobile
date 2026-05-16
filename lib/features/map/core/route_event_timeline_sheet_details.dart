import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import 'route_event_timeline_models.dart';

/// One labeled row for [RouteEventDetailsSheet] body.
@immutable
class RouteEventSheetRow {
  const RouteEventSheetRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// Pre-computed strings for the route event bottom sheet (no I/O, test-friendly).
@immutable
class RouteEventSheetPresentation {
  const RouteEventSheetPresentation({
    required this.pageTitle,
    required this.headline,
    required this.rows,
    required this.hasValidMapPosition,
    required this.showRecenterAction,
    this.addressLine,
  });

  final String pageTitle;
  final String headline;
  final List<RouteEventSheetRow> rows;
  final bool hasValidMapPosition;

  /// Optional stop address from central configuration when available.
  final String? addressLine;

  final bool showRecenterAction;
}

String _formatDateTime(DateTime utc) {
  final local = utc.toLocal();
  // Numeric pattern: no initializeDateFormatting (works in unit tests and app).
  return DateFormat('dd/MM/yyyy HH:mm:ss').format(local);
}

String _formatLatLng(LatLng p) =>
    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

/// Builds presentation for [RouteEventDetailsSheet] from [RouteEventTimelineItem].
RouteEventSheetPresentation buildRouteEventSheetPresentation(
  RouteEventTimelineItem item,
  AppLocalizations l10n,
) {
  final validPos = routeEventTimelineValidPosition(item.position);
  final coordLine = validPos ? _formatLatLng(item.position) : null;

  final rows = <RouteEventSheetRow>[];
  String headline;

  switch (item.kind) {
    case RouteTimelineEntryKind.stop:
      headline = l10n.routeEventDetailsStop;
      final start = item.stopStartTime;
      final end = item.stopEndTime;
      if (start != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.routeEventDetailsStartTime,
          value: _formatDateTime(start),
        ));
      }
      if (end != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.routeEventDetailsEndTime,
          value: _formatDateTime(end),
        ));
      }
      if (start != null && end != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.routeEventDetailsDuration,
          value: formatRouteTimelineStopDurationCompact(end.difference(start)),
        ));
      }
      break;
    case RouteTimelineEntryKind.overspeed:
      headline = l10n.routeEventDetailsOverspeed;
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      final kmh = item.overspeedMaxSpeedKmh;
      if (kmh != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.routeEventDetailsMaxSpeed,
          value: FormatUtils.speed(kmh),
        ));
      }
      break;
    case RouteTimelineEntryKind.ignitionOn:
      headline = l10n.routeEventDetailsIgnitionOn;
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      break;
    case RouteTimelineEntryKind.ignitionOff:
      headline = l10n.routeEventDetailsIgnitionOff;
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      break;
    case RouteTimelineEntryKind.routeStart:
      headline = l10n.routeTimelineStart;
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      break;
    case RouteTimelineEntryKind.routeEnd:
      headline = l10n.routeTimelineEnd;
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      break;
    case RouteTimelineEntryKind.dataGap:
      headline = l10n.replayMissingGpsData;
      final start = item.stopStartTime;
      final end = item.stopEndTime;
      if (start != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.replayGapStartLabel,
          value: _formatDateTime(start),
        ));
      }
      if (end != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.replayGapEndLabel,
          value: _formatDateTime(end),
        ));
      }
      if (start != null && end != null) {
        rows.add(RouteEventSheetRow(
          label: l10n.replayGapDurationLabel,
          value: formatRouteTimelineStopDurationCompact(end.difference(start)),
        ));
      }
      break;
    case RouteTimelineEntryKind.externalEvent:
      headline = item.title;
      rows.add(RouteEventSheetRow(
        label: l10n.replayEventDetailsType,
        value: l10n.replayExternalEvent,
      ));
      rows.add(RouteEventSheetRow(
        label: l10n.routeEventDetailsTime,
        value: _formatDateTime(item.sortTime),
      ));
      if (item.detailLine.trim().isNotEmpty &&
          item.detailLine != l10n.replayExternalEvent) {
        rows.add(RouteEventSheetRow(
          label: l10n.replayEventDetailsDescription,
          value: item.detailLine,
        ));
      }
      break;
  }

  if (validPos) {
    rows.add(RouteEventSheetRow(
      label: l10n.routeEventDetailsLocation,
      value: coordLine!,
    ));
  } else if (item.kind == RouteTimelineEntryKind.externalEvent) {
    rows.add(RouteEventSheetRow(
      label: l10n.routeEventDetailsLocation,
      value: l10n.replayExternalPositionUnavailable,
    ));
  }

  final addr = item.stopAddress?.trim();
  final addressLine =
      (item.kind == RouteTimelineEntryKind.stop &&
              addr != null &&
              addr.isNotEmpty)
          ? addr
          : null;

  return RouteEventSheetPresentation(
    pageTitle: l10n.routeEventDetailsTitle,
    headline: headline,
    rows: rows,
    hasValidMapPosition: validPos,
    addressLine: addressLine,
    showRecenterAction: validPos,
  );
}
