import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Phase 8A — tunable thresholds for splitting [RoutePoint] sequences into trips.
/// Independent from Route Intelligence analysis thresholds.
@immutable
class TripSegmentationConfig {
  const TripSegmentationConfig({
    this.movingSpeedKmh = 5.0,
    this.minTripDuration = const Duration(minutes: 3),
    this.minTripDistanceKm = 0.15,
    this.stopGapDuration = const Duration(minutes: 8),
    this.maxPointGapDuration = const Duration(minutes: 20),
    this.mergeNearbyTripsGap,
    this.bufferForReportParams = const Duration(seconds: 25),
    this.ignitionAssistMinSpeedKmh = 1.0,
  });

  /// Speed at or above ⇒ “moving” when classifying trip motion.
  final double movingSpeedKmh;

  /// Reject trips shorter than this wall-time span.
  final Duration minTripDuration;

  /// Reject trips whose path length is below this (km).
  final double minTripDistanceKm;

  /// While in a trip: accumulated stationary time ≥ this ends the trip after
  /// the last moving point before the long stop.
  final Duration stopGapDuration;

  /// If the gap between two consecutive points exceeds this, the trace is split:
  /// previous trip ends before the gap; a new segment starts after the gap.
  final Duration maxPointGapDuration;

  /// Optional: merge two neighbouring accepted trips when the quiet gap between
  /// them is shorter than this duration.
  final Duration? mergeNearbyTripsGap;

  /// Expands [ReportFilterParams] when opening map / replay so edge points stay included.
  final Duration bufferForReportParams;

  /// When [RoutePoint.ignition] is true and speed ≥ this, count as likely trip start
  /// even if speed is slightly below [movingSpeedKmh].
  final double ignitionAssistMinSpeedKmh;

  static const TripSegmentationConfig defaults = TripSegmentationConfig();

  String get cacheKey => [
        movingSpeedKmh.toStringAsFixed(2),
        minTripDuration.inSeconds,
        minTripDistanceKm.toStringAsFixed(3),
        stopGapDuration.inSeconds,
        maxPointGapDuration.inSeconds,
        mergeNearbyTripsGap?.inSeconds ?? -1,
        bufferForReportParams.inSeconds,
        ignitionAssistMinSpeedKmh.toStringAsFixed(2),
      ].join('|');

  TripSegmentationConfig copyWith({
    double? movingSpeedKmh,
    Duration? minTripDuration,
    double? minTripDistanceKm,
    Duration? stopGapDuration,
    Duration? maxPointGapDuration,
    Duration? mergeNearbyTripsGap,
    Duration? bufferForReportParams,
    double? ignitionAssistMinSpeedKmh,
  }) {
    return TripSegmentationConfig(
      movingSpeedKmh: movingSpeedKmh ?? this.movingSpeedKmh,
      minTripDuration: minTripDuration ?? this.minTripDuration,
      minTripDistanceKm: minTripDistanceKm ?? this.minTripDistanceKm,
      stopGapDuration: stopGapDuration ?? this.stopGapDuration,
      maxPointGapDuration: maxPointGapDuration ?? this.maxPointGapDuration,
      mergeNearbyTripsGap: mergeNearbyTripsGap ?? this.mergeNearbyTripsGap,
      bufferForReportParams: bufferForReportParams ?? this.bufferForReportParams,
      ignitionAssistMinSpeedKmh:
          ignitionAssistMinSpeedKmh ?? this.ignitionAssistMinSpeedKmh,
    );
  }
}

/// One detected trip with pre-computed roll-ups (incl. Route Intelligence per trip).
@immutable
class TripSegment {
  const TripSegment({
    required this.selectionKey,
    required this.vehicleId,
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.startPosition,
    required this.endPosition,
    required this.distanceKm,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.stopCount,
    required this.totalStopDuration,
    required this.overspeedCount,
    required this.ignitionOnCount,
    required this.ignitionOffCount,
    required this.hasIgnitionData,
    this.startAddress,
    this.endAddress,
  });

  final String selectionKey;
  final String vehicleId;

  /// 1-based index for display (“Trajet 1”).
  final int index;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  final LatLng startPosition;
  final LatLng endPosition;

  final double distanceKm;
  final double maxSpeedKmh;
  final double avgSpeedKmh;

  final int stopCount;
  final Duration totalStopDuration;
  final int overspeedCount;

  final int ignitionOnCount;
  final int ignitionOffCount;
  final bool hasIgnitionData;

  final String? startAddress;
  final String? endAddress;
}
