import 'package:flutter/foundation.dart';

import '../../../map/core/route_event_analyzer.dart';
import '../../../map/core/route_intelligence_thresholds.dart';
import '../../../reports/core/replay_motion_helper.dart';
import '../../../reports/core/replay_route_gap.dart';
import 'multi_vehicle_replay_model.dart';

/// Speed (km/h) at or above which a fix counts as moving (aligned with R7 cards).
const double multiReplayMovingSpeedKmh = 5.0;

/// Per-vehicle KPIs derived from loaded route points only (Phase R8).
@immutable
class MultiReplayKpi {
  const MultiReplayKpi({
    required this.vehicleId,
    required this.vehicleName,
    required this.colorIndex,
    required this.hasEnoughData,
    this.totalDistanceMeters,
    this.movingDuration = Duration.zero,
    this.stoppedDuration = Duration.zero,
    this.maxSpeedKmh,
    this.averageMovingSpeedKmh,
    this.stopsCount = 0,
    this.overspeedCount = 0,
    this.firstPointTime,
    this.lastPointTime,
    this.firstMovingTime,
  });

  final String vehicleId;
  final String vehicleName;
  final int colorIndex;
  final bool hasEnoughData;

  /// Approximate GPS path length (Haversine); excludes gaps and invalid segments.
  final double? totalDistanceMeters;

  final Duration movingDuration;
  final Duration stoppedDuration;
  final double? maxSpeedKmh;

  /// Mean speed during movement (distance / moving time), not mean of all fixes.
  final double? averageMovingSpeedKmh;

  final int stopsCount;
  final int overspeedCount;
  final DateTime? firstPointTime;
  final DateTime? lastPointTime;

  /// First fix at or above [multiReplayMovingSpeedKmh].
  final DateTime? firstMovingTime;

  double? get totalDistanceKm =>
      totalDistanceMeters == null ? null : totalDistanceMeters! / 1000;
}

/// Short comparison insight between vehicles.
@immutable
class MultiReplayComparisonInsight {
  const MultiReplayComparisonInsight({
    required this.kind,
    required this.vehicleId,
    required this.vehicleName,
    this.detail,
  });

  final MultiReplayInsightKind kind;
  final String vehicleId;
  final String vehicleName;

  /// Optional formatted value (distance, speed, etc.).
  final String? detail;
}

enum MultiReplayInsightKind {
  longestDistance,
  longestStoppedTime,
  highestMaxSpeed,
  mostOverspeeds,
  firstMovement,
  earliestRouteEnd,
}

/// All KPIs + insights for a multi-replay session.
@immutable
class MultiReplayComparisonSummary {
  const MultiReplayComparisonSummary({
    required this.kpisByVehicleId,
    this.insights = const [],
  });

  final Map<String, MultiReplayKpi> kpisByVehicleId;
  final List<MultiReplayComparisonInsight> insights;

  List<MultiReplayKpi> get kpis => kpisByVehicleId.values.toList();

  List<MultiReplayKpi> withEnoughData() =>
      kpis.where((k) => k.hasEnoughData).toList();
}

/// Computes route-based KPIs for multi-vehicle replay (Phase R8).
abstract final class MultiReplayKpiCalculator {
  MultiReplayKpiCalculator._();

  static MultiReplayComparisonSummary buildSummary(
    List<MultiVehicleReplayTrack> tracks, {
    RouteIntelligenceThresholds thresholds =
        RouteIntelligenceThresholds.defaults,
  }) {
    final kpis = <String, MultiReplayKpi>{};
    for (final t in tracks) {
      kpis[t.vehicleId] = computeForTrack(t, thresholds: thresholds);
    }
    return MultiReplayComparisonSummary(
      kpisByVehicleId: kpis,
      insights: _buildInsights(kpis.values.toList()),
    );
  }

  static MultiReplayKpi computeForTrack(
    MultiVehicleReplayTrack track, {
    RouteIntelligenceThresholds thresholds =
        RouteIntelligenceThresholds.defaults,
  }) {
    final points = ReplayRouteGapDetector.sortByFixTime(track.allPoints);
    if (points.isEmpty) {
      return MultiReplayKpi(
        vehicleId: track.vehicleId,
        vehicleName: track.name,
        colorIndex: track.colorIndex,
        hasEnoughData: false,
      );
    }

    final gaps = ReplayRouteGapDetector.detectGaps(points);
    final valid = points.where(replayPointHasValidPosition).toList();

    if (valid.length < 2) {
      final only = valid.isNotEmpty ? valid.first : points.first;
      final maxSp = valid.isEmpty
          ? null
          : valid.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
      return MultiReplayKpi(
        vehicleId: track.vehicleId,
        vehicleName: track.name,
        colorIndex: track.colorIndex,
        hasEnoughData: false,
        maxSpeedKmh: maxSp,
        firstPointTime: only.fixTime,
        lastPointTime: only.fixTime,
        firstMovingTime:
            only.speed >= multiReplayMovingSpeedKmh ? only.fixTime : null,
      );
    }

    var distanceM = 0.0;
    var moving = Duration.zero;
    var stopped = Duration.zero;
    double? maxSpeed;
    DateTime? firstMoving;

    for (var i = 1; i < valid.length; i++) {
      final a = valid[i - 1];
      final b = valid[i];
      final dt = b.fixTime.difference(a.fixTime);
      if (dt <= Duration.zero) continue;
      if (dt > replayGapThreshold) continue;
      if (replaySegmentCrossesKnownGap(a.fixTime, b.fixTime, gaps)) continue;

      if (canInterpolateBetween(a, b, knownGaps: gaps)) {
        distanceM += replayDistanceMeters(a.position, b.position);
      }

      if (a.speed >= multiReplayMovingSpeedKmh) {
        moving += dt;
        firstMoving ??= a.fixTime;
      } else {
        stopped += dt;
      }

      for (final p in [a, b]) {
        if (maxSpeed == null || p.speed > maxSpeed) {
          maxSpeed = p.speed;
        }
      }
    }

    if (firstMoving == null) {
      for (final p in valid) {
        if (p.speed >= multiReplayMovingSpeedKmh) {
          firstMoving = p.fixTime;
          break;
        }
      }
    }

    double? avgMoving;
    if (moving > Duration.zero && distanceM > 0) {
      final hours = moving.inMilliseconds / 3600000.0;
      if (hours > 0) {
        avgMoving = (distanceM / 1000) / hours;
      }
    }

    final th = thresholds.normalized();
    final analysis = RouteEventAnalyzer.analyze(points, thresholds: th);

    return MultiReplayKpi(
      vehicleId: track.vehicleId,
      vehicleName: track.name,
      colorIndex: track.colorIndex,
      hasEnoughData: true,
      totalDistanceMeters: distanceM > 0 ? distanceM : null,
      movingDuration: moving,
      stoppedDuration: stopped,
      maxSpeedKmh: maxSpeed,
      averageMovingSpeedKmh: avgMoving,
      stopsCount: analysis.summary.stopCount,
      overspeedCount: analysis.summary.overspeedCount,
      firstPointTime: valid.first.fixTime,
      lastPointTime: valid.last.fixTime,
      firstMovingTime: firstMoving,
    );
  }

  static List<MultiReplayComparisonInsight> _buildInsights(
    List<MultiReplayKpi> kpis,
  ) {
    final eligible = kpis.where((k) => k.hasEnoughData).toList();
    if (eligible.length < 2) return const [];

    final out = <MultiReplayComparisonInsight>[];

    void pickMaxNum(
      MultiReplayInsightKind kind,
      double? Function(MultiReplayKpi k) value,
      String? Function(MultiReplayKpi k) detail,
    ) {
      MultiReplayKpi? best;
      double? bestVal;
      for (final k in eligible) {
        final v = value(k);
        if (v == null) continue;
        if (bestVal == null || v > bestVal) {
          bestVal = v;
          best = k;
        }
      }
      if (best != null) {
        out.add(
          MultiReplayComparisonInsight(
            kind: kind,
            vehicleId: best.vehicleId,
            vehicleName: best.vehicleName,
            detail: detail(best),
          ),
        );
      }
    }

    pickMaxNum(
      MultiReplayInsightKind.longestDistance,
      (k) => k.totalDistanceKm,
      (k) => k.totalDistanceKm?.toStringAsFixed(1),
    );

    pickMaxNum(
      MultiReplayInsightKind.longestStoppedTime,
      (k) => k.stoppedDuration.inSeconds.toDouble(),
      (k) => '${k.stoppedDuration.inSeconds}',
    );

    pickMaxNum(
      MultiReplayInsightKind.highestMaxSpeed,
      (k) => k.maxSpeedKmh,
      (k) => k.maxSpeedKmh?.round().toString(),
    );

    pickMaxNum(
      MultiReplayInsightKind.mostOverspeeds,
      (k) => k.overspeedCount.toDouble(),
      (k) => '${k.overspeedCount}',
    );

    MultiReplayKpi? earliestMove;
    DateTime? earliestMoveAt;
    for (final k in eligible) {
      final t = k.firstMovingTime ?? k.firstPointTime;
      if (t == null) continue;
      if (earliestMoveAt == null || t.isBefore(earliestMoveAt)) {
        earliestMoveAt = t;
        earliestMove = k;
      }
    }
    if (earliestMove != null) {
      out.add(
        MultiReplayComparisonInsight(
          kind: MultiReplayInsightKind.firstMovement,
          vehicleId: earliestMove.vehicleId,
          vehicleName: earliestMove.vehicleName,
        ),
      );
    }

    MultiReplayKpi? earliestEnd;
    DateTime? earliestEndAt;
    for (final k in eligible) {
      final t = k.lastPointTime;
      if (t == null) continue;
      if (earliestEndAt == null || t.isBefore(earliestEndAt)) {
        earliestEndAt = t;
        earliestEnd = k;
      }
    }
    if (earliestEnd != null && eligible.any((k) {
          final t = k.lastPointTime;
          return t != null && t != earliestEndAt;
        })) {
      out.add(
        MultiReplayComparisonInsight(
          kind: MultiReplayInsightKind.earliestRouteEnd,
          vehicleId: earliestEnd.vehicleId,
          vehicleName: earliestEnd.vehicleName,
        ),
      );
    }

    return out;
  }
}
