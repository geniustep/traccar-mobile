import 'package:flutter/foundation.dart';

/// Numeric thresholds for [RouteEventAnalyzer] stop/overspeed math.
///
/// Prefer passing [RouteIntelligenceThresholds] through the analyzer; this class
/// remains as the internal payload after [RouteIntelligenceThresholds.toAnalysisConfig].
@immutable
class RouteEventAnalysisConfig {
  const RouteEventAnalysisConfig({
    this.stopSpeedEnterKmh = 3.0,
    this.stopSpeedExitKmh = 5.0,
    this.minStopDuration = const Duration(minutes: 4),
    this.overspeedThresholdKmh = 80.0,
  });

  /// Below this speed (km/h) we enter a "stopped" segment.
  final double stopSpeedEnterKmh;

  /// Above this speed (km/h) we leave a "stopped" segment (hysteresis).
  final double stopSpeedExitKmh;

  /// Minimum duration to count as a parking / stop event.
  final Duration minStopDuration;

  /// Speed above this (km/h) counts as overspeed during contiguous runs.
  final double overspeedThresholdKmh;
}

/// A sustained stop / parking segment derived from route points.
@immutable
class RouteStopEvent {
  const RouteStopEvent({
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final DateTime startTime;
  final DateTime endTime;
  Duration get duration => endTime.difference(startTime);
  final double latitude;
  final double longitude;
  final String? address;
}

/// Peak of a contiguous overspeed run (max speed in that run).
@immutable
class RouteOverspeedEvent {
  const RouteOverspeedEvent({
    required this.time,
    required this.speed,
    required this.latitude,
    required this.longitude,
  });

  final DateTime time;
  final double speed;
  final double latitude;
  final double longitude;
}

/// Ignition transition at a point (only emitted when data looks reliable).
@immutable
class RouteIgnitionEvent {
  const RouteIgnitionEvent({
    required this.on,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  final bool on;
  final DateTime time;
  final double latitude;
  final double longitude;
}

/// Lightweight roll-up for UI / panels.
@immutable
class RouteEventSummary {
  const RouteEventSummary({
    required this.stopCount,
    required this.totalStopDuration,
    required this.overspeedCount,
    required this.maxSpeed,
    required this.ignitionTransitionCount,
  });

  final int stopCount;
  final Duration totalStopDuration;
  final int overspeedCount;
  final double maxSpeed;
  final int ignitionTransitionCount;
}

/// Full output of [RouteEventAnalyzer.analyze].
@immutable
class RouteEventAnalysisResult {
  const RouteEventAnalysisResult({
    required this.stops,
    required this.overspeeds,
    required this.ignitions,
    required this.summary,
    required this.ignitionDataLikelyPresent,
  });

  final List<RouteStopEvent> stops;
  final List<RouteOverspeedEvent> overspeeds;
  final List<RouteIgnitionEvent> ignitions;
  final RouteEventSummary summary;

  /// False when every point reports `ignition == false` and there are no transitions
  /// (typical when Traccar does not expose ignition in attributes).
  final bool ignitionDataLikelyPresent;

  static RouteEventAnalysisResult empty(double maxSpeed) =>
      RouteEventAnalysisResult(
        stops: const [],
        overspeeds: const [],
        ignitions: const [],
        summary: RouteEventSummary(
          stopCount: 0,
          totalStopDuration: Duration.zero,
          overspeedCount: 0,
          maxSpeed: maxSpeed,
          ignitionTransitionCount: 0,
        ),
        ignitionDataLikelyPresent: false,
      );

  /// Same analysis with replaced [stops] (e.g. Phase 7D stop addresses). Summary unchanged.
  RouteEventAnalysisResult withStops(List<RouteStopEvent> stops) =>
      RouteEventAnalysisResult(
        stops: stops,
        overspeeds: overspeeds,
        ignitions: ignitions,
        summary: summary,
        ignitionDataLikelyPresent: ignitionDataLikelyPresent,
      );
}
