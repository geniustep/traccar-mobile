import '../../../map/data/datasources/route_datasource.dart';
import 'multi_vehicle_replay_model.dart';

/// Built unified timeline from all vehicle tracks.
class MultiVehicleReplayTimeline {
  const MultiVehicleReplayTimeline({
    required this.timestamps,
    required this.tracksByVehicleId,
    required this.pointsByVehicleId,
  });

  /// Sorted unique event times across all vehicles.
  final List<DateTime> timestamps;

  final Map<String, MultiVehicleReplayTrack> tracksByVehicleId;

  /// Sorted points per vehicle (same order as [MultiVehicleReplayTrack.allPoints]).
  final Map<String, List<RoutePoint>> pointsByVehicleId;

  bool get isEmpty => timestamps.isEmpty;

  DateTime? get startTime => timestamps.isEmpty ? null : timestamps.first;

  DateTime? get endTime => timestamps.isEmpty ? null : timestamps.last;

  int get length => timestamps.length;

  /// Index for [time], clamped. Returns 0 when timeline is empty.
  int indexForTime(DateTime time) {
    if (timestamps.isEmpty) return 0;
    var lo = 0;
    var hi = timestamps.length - 1;
    if (time.isBefore(timestamps.first)) return 0;
    if (time.isAfter(timestamps.last) || time == timestamps.last) return hi;

    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (timestamps[mid].isAfter(time)) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    return lo;
  }

  DateTime? timeAtIndex(int index) {
    if (timestamps.isEmpty) return null;
    return timestamps[index.clamp(0, timestamps.length - 1)];
  }

  /// Latest point at or before [replayTime] for [vehicleId].
  static RoutePoint? pointAtOrBefore(
    List<RoutePoint> sortedPoints,
    DateTime replayTime,
  ) {
    if (sortedPoints.isEmpty) return null;
    if (replayTime.isBefore(sortedPoints.first.fixTime)) return null;

    var lo = 0;
    var hi = sortedPoints.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (sortedPoints[mid].fixTime.isAfter(replayTime)) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    if (sortedPoints[lo].fixTime.isAfter(replayTime)) return null;
    return sortedPoints[lo];
  }

  Map<String, RoutePoint?> markersAtTime(DateTime replayTime) {
    final result = <String, RoutePoint?>{};
    for (final entry in pointsByVehicleId.entries) {
      result[entry.key] = pointAtOrBefore(entry.value, replayTime);
    }
    return result;
  }

  Map<String, RoutePoint?> markersAtIndex(int index) {
    final t = timeAtIndex(index);
    if (t == null) return {};
    return markersAtTime(t);
  }
}

/// Pure helpers for validation and timeline construction.
abstract final class MultiVehicleReplayTimelineBuilder {
  MultiVehicleReplayTimelineBuilder._();

  /// Cap playback steps so x8 stays responsive with dense GPS data.
  static const int maxPlaybackTimestamps = 2000;

  static String? validateVehicleCount(int count) {
    if (count < MultiVehicleReplayLimits.minVehicles) {
      return 'too_few';
    }
    if (count > MultiVehicleReplayLimits.maxVehicles) {
      return 'too_many';
    }
    return null;
  }

  static bool isValidCount(int count) => validateVehicleCount(count) == null;

  static MultiVehicleReplayTimeline build(
    List<MultiVehicleReplayTrack> tracks,
  ) {
    final pointsByVehicleId = <String, List<RoutePoint>>{};
    final allTimes = <DateTime>{};

    for (final track in tracks) {
      final sorted = List<RoutePoint>.from(track.allPoints)
        ..sort((a, b) => a.fixTime.compareTo(b.fixTime));
      pointsByVehicleId[track.vehicleId] = sorted;
      for (final p in sorted) {
        allTimes.add(p.fixTime);
      }
    }

    final sortedTimes = allTimes.toList()..sort();
    final timestamps = decimateTimestamps(
      sortedTimes,
      maxCount: maxPlaybackTimestamps,
    );
    final byId = {for (final t in tracks) t.vehicleId: t};

    return MultiVehicleReplayTimeline(
      timestamps: timestamps,
      tracksByVehicleId: byId,
      pointsByVehicleId: pointsByVehicleId,
    );
  }

  /// Evenly samples sorted unique timestamps; keeps first and last.
  static List<DateTime> decimateTimestamps(
    List<DateTime> sorted, {
    int maxCount = maxPlaybackTimestamps,
  }) {
    if (sorted.length <= maxCount) return sorted;
    final result = <DateTime>[sorted.first];
    final inner = maxCount - 2;
    final step = (sorted.length - 2) / inner;
    for (var i = 1; i <= inner; i++) {
      result.add(sorted[(i * step).round().clamp(1, sorted.length - 2)]);
    }
    result.add(sorted.last);
    return result;
  }

  static List<RoutePoint> preparePoints(List<RoutePoint> raw) {
    final valid = raw
        .where(
          (p) => p.position.latitude != 0 || p.position.longitude != 0,
        )
        .toList()
      ..sort((a, b) => a.fixTime.compareTo(b.fixTime));
    return valid;
  }
}
