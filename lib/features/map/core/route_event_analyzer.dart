import '../data/datasources/route_datasource.dart';
import 'route_event_models.dart';
import 'route_intelligence_thresholds.dart';

/// Derives stops, overspeed runs, and ignition transitions from ordered [RoutePoint]s.
///
/// Uses [RoutePoint.ignition] from Traccar `attributes` only; does not synthesize
/// ignition when the series is uniformly `false` with no transitions.
///
/// Pass [thresholds] to customize analysis; omit or null to use [RouteIntelligenceThresholds.defaults].
class RouteEventAnalyzer {
  RouteEventAnalyzer._();

  static RouteEventAnalysisResult analyze(
    List<RoutePoint> points, {
    RouteIntelligenceThresholds? thresholds,
  }) {
    final th = (thresholds ?? RouteIntelligenceThresholds.defaults).normalized();
    final cfg = th.toAnalysisConfig();

    if (points.isEmpty) {
      return RouteEventAnalysisResult.empty(0);
    }

    final maxSpeed = points.map((p) => p.speed).reduce(
          (a, b) => a > b ? a : b,
        );

    if (points.length < 2) {
      return RouteEventAnalysisResult.empty(maxSpeed);
    }

    final stops = th.detectStops ? _detectStops(points, cfg) : const <RouteStopEvent>[];
    final overspeeds =
        th.detectOverspeed ? _detectOverspeeds(points, cfg) : const <RouteOverspeedEvent>[];

    final (ignitions, ignitionLikely) = th.detectIgnition
        ? _detectIgnition(points)
        : (const <RouteIgnitionEvent>[], false);

    var totalStop = Duration.zero;
    for (final s in stops) {
      totalStop += s.duration;
    }

    final summary = RouteEventSummary(
      stopCount: stops.length,
      totalStopDuration: totalStop,
      overspeedCount: overspeeds.length,
      maxSpeed: maxSpeed,
      ignitionTransitionCount: ignitions.length,
    );

    return RouteEventAnalysisResult(
      stops: stops,
      overspeeds: overspeeds,
      ignitions: ignitions,
      summary: summary,
      ignitionDataLikelyPresent: ignitionLikely,
    );
  }

  static List<RouteStopEvent> _detectStops(
    List<RoutePoint> pts,
    RouteEventAnalysisConfig cfg,
  ) {
    final out = <RouteStopEvent>[];
    var inStop = false;
    DateTime? stopStart;
    int? stopStartIdx;

    void closeStop(int endIdx) {
      if (!inStop || stopStart == null || stopStartIdx == null) return;
      final ssIdx = stopStartIdx!;
      final end = pts[endIdx];
      final dur = end.fixTime.difference(stopStart!);
      if (dur >= cfg.minStopDuration) {
        final mid = (ssIdx + endIdx) >> 1;
        final m = pts[mid];
        out.add(
          RouteStopEvent(
            startTime: stopStart!,
            endTime: end.fixTime,
            latitude: m.position.latitude,
            longitude: m.position.longitude,
          ),
        );
      }
      inStop = false;
      stopStart = null;
      stopStartIdx = null;
    }

    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final v = p.speed;
      if (!inStop && v < cfg.stopSpeedEnterKmh) {
        inStop = true;
        stopStart = p.fixTime;
        stopStartIdx = i;
      } else if (inStop && v > cfg.stopSpeedExitKmh) {
        closeStop(i - 1);
      }
    }
    if (inStop && stopStartIdx != null) {
      closeStop(pts.length - 1);
    }
    return out;
  }

  static List<RouteOverspeedEvent> _detectOverspeeds(
    List<RoutePoint> pts,
    RouteEventAnalysisConfig cfg,
  ) {
    final out = <RouteOverspeedEvent>[];
    var inRun = false;
    RoutePoint? best;

    void flush() {
      if (!inRun || best == null) return;
      out.add(
        RouteOverspeedEvent(
          time: best!.fixTime,
          speed: best!.speed,
          latitude: best!.position.latitude,
          longitude: best!.position.longitude,
        ),
      );
      inRun = false;
      best = null;
    }

    for (final p in pts) {
      if (p.speed > cfg.overspeedThresholdKmh) {
        if (!inRun) {
          inRun = true;
          best = p;
        } else if (p.speed > best!.speed) {
          best = p;
        }
      } else {
        flush();
      }
    }
    flush();
    return out;
  }

  /// Returns (events, likelyRealData). No events when ignition never changes and stays false.
  static (List<RouteIgnitionEvent>, bool) _detectIgnition(List<RoutePoint> pts) {
    final events = <RouteIgnitionEvent>[];
    var anyTrue = false;
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      if (cur.ignition) anyTrue = true;
      if (prev.ignition != cur.ignition) {
        events.add(
          RouteIgnitionEvent(
            on: cur.ignition,
            time: cur.fixTime,
            latitude: cur.position.latitude,
            longitude: cur.position.longitude,
          ),
        );
      }
    }
    final likely = anyTrue || events.isNotEmpty;
    if (!anyTrue && events.isEmpty) {
      return (const [], false);
    }
    return (events, likely);
  }
}
