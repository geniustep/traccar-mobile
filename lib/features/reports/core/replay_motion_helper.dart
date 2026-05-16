import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/data/datasources/route_datasource.dart';
import 'replay_route_gap.dart';

/// Maximum plausible speed (km/h) for smooth segment animation (Phase R5).
const double replayMaxInterpolationSpeedKmh = 220;

/// Whether [p] has usable map coordinates for replay motion.
bool replayPointHasValidPosition(RoutePoint p) =>
    p.position.latitude.abs() > 1e-6 || p.position.longitude.abs() > 1e-6;

/// True when the open interval between [tA] and [tB] overlaps a known [ReplayRouteGap].
bool replaySegmentCrossesKnownGap(
  DateTime tA,
  DateTime tB,
  List<ReplayRouteGap> gaps,
) {
  if (gaps.isEmpty) return false;
  final lo = tA.isBefore(tB) ? tA : tB;
  final hi = tA.isBefore(tB) ? tB : tA;
  for (final g in gaps) {
    if (g.gapStartTime.isBefore(hi) && g.gapEndTime.isAfter(lo)) {
      return true;
    }
  }
  return false;
}

/// Haversine distance in metres between two coordinates.
double replayDistanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final dLat = _toRad(b.latitude - a.latitude);
  final dLng = _toRad(b.longitude - a.longitude);
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.sqrt(h));
}

double _toRad(double deg) => deg * math.pi / 180;

/// Whether visual interpolation is allowed between two consecutive replay fixes.
bool canInterpolateBetween(
  RoutePoint a,
  RoutePoint b, {
  List<ReplayRouteGap> knownGaps = const [],
  Duration maxTimeDelta = replayGapThreshold,
}) {
  if (!replayPointHasValidPosition(a) || !replayPointHasValidPosition(b)) {
    return false;
  }

  final dt = b.fixTime.difference(a.fixTime);
  if (dt <= Duration.zero) return false;
  if (dt > maxTimeDelta) return false;

  if (replaySegmentCrossesKnownGap(a.fixTime, b.fixTime, knownGaps)) {
    return false;
  }

  final hours = dt.inMilliseconds / 3600000.0;
  if (hours <= 0) return false;
  final kmh = (replayDistanceMeters(a.position, b.position) / 1000) / hours;
  if (kmh > replayMaxInterpolationSpeedKmh) return false;

  return true;
}

/// Linear blend between two route fixes (visual marker only — Phase R5).
RoutePoint interpolateRoutePoint(RoutePoint from, RoutePoint to, double t) {
  final clamped = t.clamp(0.0, 1.0);
  return RoutePoint(
    position: LatLng(
      from.position.latitude +
          (to.position.latitude - from.position.latitude) * clamped,
      from.position.longitude +
          (to.position.longitude - from.position.longitude) * clamped,
    ),
    speed: from.speed + (to.speed - from.speed) * clamped,
    course: _lerpAngle(from.course, to.course, clamped),
    fixTime: from.fixTime,
    ignition: clamped < 0.5 ? from.ignition : to.ignition,
    address: from.address,
  );
}

double _lerpAngle(double from, double to, double t) {
  var delta = (to - from) % 360;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return (from + delta * t) % 360;
}
