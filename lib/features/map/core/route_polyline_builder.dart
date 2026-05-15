import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/route_decimator.dart';
import '../../reports/core/replay_route_gap.dart';
import '../data/datasources/route_datasource.dart';
import 'map_zoom_policy.dart';
import 'route_event_models.dart';
import 'route_event_timeline_models.dart';

/// Route intelligence map markers plus [itemByMarkerId] for tests and debugging.
@immutable
class RouteIntelligenceMarkerBundle {
  const RouteIntelligenceMarkerBundle({
    required this.markers,
    required this.itemByMarkerId,
  });

  final Set<Marker> markers;

  /// Same keys as [Marker.markerId] string values (one entry per marker).
  final Map<String, RouteEventTimelineItem> itemByMarkerId;
}

/// Route polylines + optional map markers shared between fleet "today" preview
/// and the detailed vehicle tracking screen.
class RoutePolylineBuilder {
  RoutePolylineBuilder._();

  static List<RoutePoint> decimate(List<RoutePoint> pts) =>
      RoutePointDecimator.decimateForMap(pts);

  /// Decimate with explicit cap (e.g. from [MapZoomPolicy.maxVisibleRoutePointsForDecimation]).
  static List<RoutePoint> decimateForMapWithMax(
    List<RoutePoint> pts, {
    required int maxPoints,
  }) =>
      RoutePointDecimator.decimateForMap(pts, maxPoints: maxPoints);

  /// Speed-coloured replay segments that **do not** connect across [gaps].
  ///
  /// Gap detection runs on the full [allPoints] list; each continuous run is
  /// decimated separately so subsampling cannot invent false gaps.
  static Set<Polyline> buildReplaySpeedColoredPolylinesRespectingGaps({
    required List<RoutePoint> allPoints,
    required List<ReplayRouteGap> gaps,
    String idPrefix = 'rpl',
  }) {
    if (allPoints.length < 2) return const {};
    final sorted = ReplayRouteGapDetector.sortByFixTime(allPoints);
    final runs = ReplayRouteGapDetector.splitIntoContinuousRuns(sorted, gaps);
    if (runs.isEmpty) return const {};

    final polys = <Polyline>{};
    var seg = 0;
    for (final run in runs) {
      final draw = decimate(run);
      for (var i = 0; i < draw.length - 1; i++) {
        polys.add(
          Polyline(
            polylineId: PolylineId('${idPrefix}_s${seg}_$i'),
            points: [draw[i].position, draw[i + 1].position],
            color: MapHelper.routeColorForSpeed(
              (draw[i].speed + draw[i + 1].speed) / 2,
            ),
            width: 5,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
      seg++;
    }
    return polys;
  }

  /// Map markers for missing GPS intervals on replay (Phase R1).
  static Set<Marker> buildReplayGapMarkers({
    required List<ReplayRouteGap> gaps,
    required AppLocalizations l10n,
    required String vehicleId,
    ValueChanged<RouteEventTimelineItem>? onMarkerTap,
    String? selectedEventKey,
  }) {
    if (gaps.isEmpty) return const {};
    final markers = <Marker>{};
    final consumeTap = onMarkerTap != null;

    for (var i = 0; i < gaps.length; i++) {
      final g = gaps[i];
      final item = routeEventTimelineItemForReplayGap(g, l10n);
      if (item == null) continue;
      final id = '${vehicleId}_replay_gap_$i';
      final selected =
          selectedEventKey != null && item.selectionKey == selectedEventKey;
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: g.markerPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet,
          ),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: consumeTap,
          zIndexInt: selected ? 4 : 3,
          onTap: onMarkerTap == null ? null : () => onMarkerTap(item),
          infoWindow: InfoWindow(
            title: l10n.replayMissingGpsData,
            snippet: formatRouteTimelineStopDurationCompact(g.duration),
          ),
        ),
      );
    }
    return markers;
  }

  /// Speed-coloured segments (tracking screen).
  static List<Polyline> buildSpeedColoredPolylines({
    required String vehicleId,
    required List<RoutePoint> pts,
  }) {
    if (pts.length < 2) return const [];
    return List.generate(pts.length - 1, (i) {
      final avg = (pts[i].speed + pts[i + 1].speed) / 2;
      return Polyline(
        polylineId: PolylineId('route_${vehicleId}_$i'),
        points: [pts[i].position, pts[i + 1].position],
        color: MapHelper.routeColorForSpeed(avg),
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );
    });
  }

  /// Light "today" trail for fleet map (single polyline, decimated input).
  static Set<Polyline> buildTodayPreview({
    required String vehicleId,
    required List<RoutePoint> pts,
    required Color color,
  }) {
    if (pts.length < 2) return const {};
    final dec = decimate(pts);
    return {
      Polyline(
        polylineId: PolylineId('today_$vehicleId'),
        points: dec.map((e) => e.position).toList(),
        width: 5,
        color: color,
      ),
    };
  }

  static String _fmtTime(DateTime dt) =>
      DateFormat('HH:mm').format(dt.toLocal());

  static String _fmtStopDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// Stops / overspeed / ignition markers from [RouteEventAnalyzer] — gated by [MapZoomPolicy].
  ///
  /// When [onMarkerTap] is non-null, markers use [Marker.consumeTapEvents] and forward taps
  /// to the same [RouteEventTimelineItem] shape as the timeline (via [routeEventTimelineItemForStop], etc.).
  static RouteIntelligenceMarkerBundle buildRouteIntelligenceMarkerBundle({
    required RouteEventAnalysisResult? analysis,
    required AppLocalizations l10n,
    required MapZoomPolicy policy,
    required bool reportStyle,
    required String vehicleId,
    ValueChanged<RouteEventTimelineItem>? onMarkerTap,
    String? selectedEventKey,
  }) {
    if (analysis == null) {
      return RouteIntelligenceMarkerBundle(markers: {}, itemByMarkerId: {});
    }

    final markers = <Marker>{};
    final itemByMarkerId = <String, RouteEventTimelineItem>{};
    final consumeTap = onMarkerTap != null;

    final stopBudget = policy.routeEventStopMarkerBudget(reportStyle: reportStyle);
    if (stopBudget > 0 && analysis.stops.isNotEmpty) {
      final sorted = [...analysis.stops]
        ..sort((a, b) => b.duration.compareTo(a.duration));
      final n = math.min(stopBudget, sorted.length);
      for (var i = 0; i < n; i++) {
        final s = sorted[i];
        final item = routeEventTimelineItemForStop(s, l10n);
        if (item == null) continue;
        final id = '${vehicleId}_rint_stop_$i';
        itemByMarkerId[id] = item;
        final selected =
            selectedEventKey != null && item.selectionKey == selectedEventKey;
        markers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(s.latitude, s.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              selected
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueYellow,
            ),
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: consumeTap,
            zIndexInt: selected ? 2 : 1,
            onTap: onMarkerTap == null ? null : () => onMarkerTap(item),
            infoWindow: InfoWindow(
              title: l10n.reportsStops,
              snippet:
                  '${_fmtTime(s.startTime)}–${_fmtTime(s.endTime)} · ${_fmtStopDuration(s.duration)}',
            ),
          ),
        );
      }
    }

    final osBudget =
        policy.routeEventOverspeedMarkerBudget(reportStyle: reportStyle);
    if (osBudget > 0 && analysis.overspeeds.isNotEmpty) {
      final sorted = [...analysis.overspeeds]
        ..sort((a, b) => b.speed.compareTo(a.speed));
      final n = math.min(osBudget, sorted.length);
      for (var i = 0; i < n; i++) {
        final e = sorted[i];
        final item = routeEventTimelineItemForOverspeed(e, l10n);
        if (item == null) continue;
        final id = '${vehicleId}_rint_os_$i';
        itemByMarkerId[id] = item;
        final selected =
            selectedEventKey != null && item.selectionKey == selectedEventKey;
        markers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(e.latitude, e.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueRed,
            ),
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: consumeTap,
            zIndexInt: 2,
            onTap: onMarkerTap == null ? null : () => onMarkerTap(item),
            infoWindow: InfoWindow(
              title: l10n.overspeedEvents,
              snippet:
                  '${FormatUtils.speed(e.speed)} · ${_fmtTime(e.time)}',
            ),
          ),
        );
      }
    }

    if (analysis.ignitionDataLikelyPresent) {
      final igBudget =
          policy.routeEventIgnitionMarkerBudget(reportStyle: reportStyle);
      if (igBudget > 0 && analysis.ignitions.isNotEmpty) {
        final list = analysis.ignitions.length > igBudget
            ? analysis.ignitions.sublist(0, igBudget)
            : analysis.ignitions;
        for (var i = 0; i < list.length; i++) {
          final e = list[i];
          final item = routeEventTimelineItemForIgnition(e, l10n);
          if (item == null) continue;
          final id = '${vehicleId}_rint_ig_$i';
          itemByMarkerId[id] = item;
          final selected =
              selectedEventKey != null && item.selectionKey == selectedEventKey;
          markers.add(
            Marker(
              markerId: MarkerId(id),
              position: LatLng(e.latitude, e.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                selected
                    ? BitmapDescriptor.hueAzure
                    : (e.on
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueOrange),
              ),
              anchor: const Offset(0.5, 0.5),
              consumeTapEvents: consumeTap,
              zIndexInt: selected ? 2 : 1,
              onTap: onMarkerTap == null ? null : () => onMarkerTap(item),
              infoWindow: InfoWindow(
                title: e.on ? l10n.ignitionOnLabel : l10n.ignitionOffLabel,
                snippet: DateFormat('HH:mm:ss').format(e.time.toLocal()),
              ),
            ),
          );
        }
      }
    }

    return RouteIntelligenceMarkerBundle(
      markers: markers,
      itemByMarkerId: itemByMarkerId,
    );
  }

  static Set<Marker> buildRouteIntelligenceMarkers({
    required RouteEventAnalysisResult? analysis,
    required AppLocalizations l10n,
    required MapZoomPolicy policy,
    required bool reportStyle,
    required String vehicleId,
    ValueChanged<RouteEventTimelineItem>? onMarkerTap,
    String? selectedEventKey,
  }) {
    return buildRouteIntelligenceMarkerBundle(
      analysis: analysis,
      l10n: l10n,
      policy: policy,
      reportStyle: reportStyle,
      vehicleId: vehicleId,
      onMarkerTap: onMarkerTap,
      selectedEventKey: selectedEventKey,
    ).markers;
  }

  static Set<Marker> buildRouteMarkers(
    List<RoutePoint> pts,
    AppLocalizations l10n, {
    bool includeMaxSpeedMarker = true,
    /// When true, use [AppLocalizations.routeMaxSpeedShort] for the max-speed pin title (report maps).
    bool compactMaxSpeedTitle = false,
    /// Live vehicle on single-vehicle tracking: hides the red "arrival" pin when the last
    /// route point lies within [routeEndProximityMeters] of this position (same stop / idle,
    /// regardless of how old that fix is).
    LatLng? livePositionForRouteEndDedup,
    double routeEndProximityMeters = 120,
    /// When true, never draws the red arrival pin (e.g. today's route + live vehicle: the
    /// car marker already marks "now").
    bool omitRouteEndMarker = false,
  }) {
    if (pts.isEmpty) return {};

    final markers = <Marker>{};

    final start = pts.first;
    markers.add(
      Marker(
        markerId: const MarkerId('route_start'),
        position: start.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 2,
        infoWindow: InfoWindow(
          title: l10n.routeDeparture,
          snippet:
              '${_fmtTime(start.fixTime)} · ${FormatUtils.speed(start.speed)}'
              ' · ${start.ignition ? l10n.ignitionOnLabel : l10n.ignitionOffLabel}',
        ),
      ),
    );

    if (pts.length > 1 && !omitRouteEndMarker) {
      final end = pts.last;
      var showEnd = true;
      final dedup = livePositionForRouteEndDedup;
      if (dedup != null &&
          MapHelper.distanceMeters(end.position, dedup) <
              routeEndProximityMeters) {
        showEnd = false;
      }
      if (showEnd) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_end'),
            position: end.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            anchor: const Offset(0.5, 1.0),
            zIndexInt: 2,
            infoWindow: InfoWindow(
              title: l10n.routeArrival,
              snippet:
                  '${_fmtTime(end.fixTime)} · ${FormatUtils.speed(end.speed)}'
                  ' · ${end.ignition ? l10n.ignitionOnLabel : l10n.ignitionOffLabel}',
            ),
          ),
        );
      }
    }

    if (pts.length > 1 && includeMaxSpeedMarker) {
      final maxPt = pts.reduce((a, b) => a.speed > b.speed ? a : b);
      if (maxPt.speed > 5) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_maxspeed'),
            position: maxPt.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            anchor: const Offset(0.5, 1.0),
            zIndexInt: 1,
            infoWindow: InfoWindow(
              title: compactMaxSpeedTitle
                  ? l10n.routeMaxSpeedShort
                  : l10n.routeMaxSpeedPoint,
              snippet:
                  '${FormatUtils.speed(maxPt.speed)} · ${_fmtTime(maxPt.fixTime)}',
            ),
          ),
        );
      }
    }

    return markers;
  }

  static Set<Marker> buildHourlyWaypoints(
    List<RoutePoint> pts, {
    bool enabled = true,
  }) {
    if (!enabled || pts.length < 2) return {};

    final startLocal = pts.first.fixTime.toLocal();
    final endLocal = pts.last.fixTime.toLocal();
    if (endLocal.difference(startLocal).inMinutes < 30) return {};

    final markers = <Marker>{};
    var count = 0;

    var target = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day,
      startLocal.hour + 1,
    );

    while (target.isBefore(endLocal) && count < 24) {
      RoutePoint? closest;
      var minDiff = const Duration(minutes: 40);
      for (final pt in pts) {
        final diff = pt.fixTime.toLocal().difference(target).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = pt;
        }
      }

      if (closest != null) {
        final label = DateFormat('HH:mm').format(target);
        final dayLabel = DateFormat('dd MMM').format(target);
        markers.add(
          Marker(
            markerId: MarkerId('twp_${target.toIso8601String()}'),
            position: closest.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
            alpha: 0.9,
            infoWindow: InfoWindow(
              title: '$label · $dayLabel',
              snippet: FormatUtils.speed(closest.speed),
            ),
          ),
        );
        count++;
      }
      target = target.add(const Duration(hours: 1));
    }

    return markers;
  }
}
