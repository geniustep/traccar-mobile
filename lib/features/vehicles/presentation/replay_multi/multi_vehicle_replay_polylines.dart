import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../map/core/route_polyline_builder.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../../../reports/core/replay_route_gap.dart';
import 'multi_vehicle_replay_model.dart';

/// Builds map polylines for multi-vehicle replay (Phase R7).
abstract final class MultiVehicleReplayPolylines {
  MultiVehicleReplayPolylines._();

  static Set<Polyline> build({
    required List<MultiVehicleReplayTrack> tracks,
    required bool Function(String vehicleId) isVisible,
    bool useSpeedColors = false,
  }) {
    final polys = <Polyline>{};
    for (final track in tracks) {
      if (!isVisible(track.vehicleId)) continue;
      if (track.mapPoints.length < 2 && track.allPoints.length < 2) continue;

      if (useSpeedColors) {
        polys.addAll(_speedColoredForTrack(track));
      } else {
        polys.addAll(_solidColoredForTrack(track));
      }
    }
    return polys;
  }

  static Iterable<Polyline> _solidColoredForTrack(MultiVehicleReplayTrack track) {
    final runs = _continuousRuns(track);
    final lines = <Polyline>[];
    var seg = 0;
    for (final run in runs) {
      final pts = _mapPointsInRun(track, run);
      if (pts.length < 2) continue;
      lines.add(
        Polyline(
          polylineId: PolylineId('mv_${track.vehicleId}_$seg'),
          points: pts.map((p) => p.position).toList(),
          color: track.color,
          width: 4,
          geodesic: true,
        ),
      );
      seg++;
    }
    return lines;
  }

  static Set<Polyline> _speedColoredForTrack(MultiVehicleReplayTrack track) {
    final runs = _continuousRuns(track);
    final polys = <Polyline>{};
    var seg = 0;
    for (final run in runs) {
      if (run.length < 2) continue;
      polys.addAll(
        RoutePolylineBuilder.buildReplaySpeedColoredPolylinesRespectingGaps(
          allPoints: run,
          gaps: const [],
          idPrefix: 'mv_${track.vehicleId}_$seg',
        ),
      );
      seg++;
    }
    return polys;
  }

  static List<List<RoutePoint>> _continuousRuns(MultiVehicleReplayTrack track) {
    if (track.allPoints.length < 2) return const [];
    final sorted = ReplayRouteGapDetector.sortByFixTime(track.allPoints);
    final gaps = ReplayRouteGapDetector.detectGaps(sorted);
    return ReplayRouteGapDetector.splitIntoContinuousRuns(sorted, gaps);
  }

  static List<RoutePoint> _mapPointsInRun(
    MultiVehicleReplayTrack track,
    List<RoutePoint> run,
  ) {
    if (run.isEmpty) return const [];
    final start = run.first.fixTime;
    final end = run.last.fixTime;
    return track.mapPoints
        .where(
          (p) =>
              !p.fixTime.isBefore(start) &&
              !p.fixTime.isAfter(end),
        )
        .toList();
  }
}
