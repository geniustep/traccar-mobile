import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Minimal [TripSegment] for calculator tests (بدون نقاط GPS خام).
TripSegment testTripSegmentForScore({
  String selectionKey = 't1',
  String vehicleId = 'v',
  int index = 1,
  double distanceKm = 10,
  Duration duration = const Duration(minutes: 30),
  double maxSpeedKmh = 60,
  double avgSpeedKmh = 35,
  int stopCount = 0,
  Duration totalStopDuration = Duration.zero,
  int overspeedCount = 0,
  int ignitionOnCount = 0,
  int ignitionOffCount = 0,
  bool hasIgnitionData = false,
  DateTime? startTime,
  DateTime? endTime,
}) {
  final start = startTime ?? DateTime.utc(2024, 1, 1, 8);
  final end = endTime ?? start.add(duration);
  return TripSegment(
    selectionKey: selectionKey,
    vehicleId: vehicleId,
    index: index,
    startTime: start,
    endTime: end,
    duration: end.difference(start),
    startPosition: const LatLng(36.8, 10.13),
    endPosition: const LatLng(36.9, 10.14),
    distanceKm: distanceKm,
    maxSpeedKmh: maxSpeedKmh,
    avgSpeedKmh: avgSpeedKmh,
    stopCount: stopCount,
    totalStopDuration: totalStopDuration,
    overspeedCount: overspeedCount,
    ignitionOnCount: ignitionOnCount,
    ignitionOffCount: ignitionOffCount,
    hasIgnitionData: hasIgnitionData,
  );
}
