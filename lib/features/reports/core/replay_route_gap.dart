import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/data/datasources/route_datasource.dart';

/// Minimum time between consecutive GPS fixes before a [ReplayRouteGap] is reported.
const Duration replayGapThreshold = Duration(minutes: 10);

/// A period with no GPS data between two fixes on a replay route.
@immutable
class ReplayRouteGap {
  const ReplayRouteGap({
    required this.indexBefore,
    required this.indexAfter,
    required this.gapStartTime,
    required this.gapEndTime,
    required this.duration,
    required this.markerPosition,
  });

  /// Index in the time-sorted route list of the last point before the gap.
  final int indexBefore;

  /// Index in the time-sorted route list of the first point after the gap.
  final int indexAfter;

  /// [fixTime] of the last point before the gap.
  final DateTime gapStartTime;

  /// [fixTime] of the first point after the gap.
  final DateTime gapEndTime;

  final Duration duration;

  /// Map marker position (midpoint between the two fixes when valid).
  final LatLng markerPosition;
}

/// Detects temporal gaps on the **full** route (not decimated playback points).
abstract final class ReplayRouteGapDetector {
  ReplayRouteGapDetector._();

  static List<RoutePoint> sortByFixTime(List<RoutePoint> points) {
    if (points.length < 2) return List<RoutePoint>.from(points);
    final sorted = List<RoutePoint>.from(points)
      ..sort((a, b) => a.fixTime.compareTo(b.fixTime));
    return sorted;
  }

  /// Returns gaps where the delta between consecutive sorted fixes is **greater than**
  /// [threshold] (default [replayGapThreshold]).
  static List<ReplayRouteGap> detectGaps(
    List<RoutePoint> points, {
    Duration threshold = replayGapThreshold,
  }) {
    if (points.length < 2) return const [];

    final sorted = sortByFixTime(points);
    final gaps = <ReplayRouteGap>[];

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final next = sorted[i];
      final dt = next.fixTime.difference(prev.fixTime);
      if (dt <= Duration.zero) continue;
      if (dt > threshold) {
        gaps.add(
          ReplayRouteGap(
            indexBefore: i - 1,
            indexAfter: i,
            gapStartTime: prev.fixTime,
            gapEndTime: next.fixTime,
            duration: dt,
            markerPosition: _midpoint(prev.position, next.position),
          ),
        );
      }
    }
    return gaps;
  }

  /// Splits a sorted route into continuous runs separated by [gaps].
  ///
  /// Each run is suitable for decimation / speed-coloured polyline drawing without
  /// bridging missing data.
  static List<List<RoutePoint>> splitIntoContinuousRuns(
    List<RoutePoint> sortedPoints,
    List<ReplayRouteGap> gaps,
  ) {
    if (sortedPoints.isEmpty) return const [];
    if (gaps.isEmpty) {
      return sortedPoints.length >= 2 ? [sortedPoints] : const [];
    }

    final runs = <List<RoutePoint>>[];
    var runStart = 0;

    for (final g in gaps) {
      final endInclusive = g.indexBefore;
      if (endInclusive >= runStart && endInclusive + 1 > runStart) {
        final slice = sortedPoints.sublist(runStart, endInclusive + 1);
        if (slice.length >= 2) runs.add(slice);
      }
      runStart = g.indexAfter;
    }

    if (runStart < sortedPoints.length) {
      final slice = sortedPoints.sublist(runStart);
      if (slice.length >= 2) runs.add(slice);
    }

    return runs;
  }

  static LatLng _midpoint(LatLng a, LatLng b) => LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );

  /// Largest gap duration, or zero when [gaps] is empty.
  static Duration maxGapDuration(List<ReplayRouteGap> gaps) {
    if (gaps.isEmpty) return Duration.zero;
    var max = gaps.first.duration;
    for (var i = 1; i < gaps.length; i++) {
      if (gaps[i].duration > max) max = gaps[i].duration;
    }
    return max;
  }
}
