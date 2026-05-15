import 'package:flutter/foundation.dart';

import '../data/datasources/route_datasource.dart';
import 'route_event_analyzer.dart';
import 'route_event_models.dart';
import 'route_intelligence_thresholds.dart';
import 'route_stop_address_enrichment.dart';
import 'trip_segment_models.dart';
import 'trip_segment_summary.dart';

/// Inclusive indices into the sorted route list consumed by [TripSegmenter].
@immutable
class TripIndexRange {
  const TripIndexRange(this.start, this.end);

  final int start;
  final int end;
}

/// Pure trip builder: splits ordered [RoutePoint]s and runs [RouteEventAnalyzer] per trip slice.
class TripSegmenter {
  TripSegmenter._();

  static List<TripSegment> build({
    required String vehicleId,
    required List<RoutePoint> points,
    TripSegmentationConfig config = TripSegmentationConfig.defaults,
    RouteIntelligenceThresholds? thresholds,
  }) {
    if (points.isEmpty) return const [];
    final sorted = [...points]..sort((a, b) => a.fixTime.compareTo(b.fixTime));

    final gapRanges =
        _splitByMaxPointGap(sorted, config.maxPointGapDuration); // contiguous runs
    var rawRanges = <TripIndexRange>[];
    for (final gap in gapRanges) {
      rawRanges.addAll(
        _movingRangesInSlice(sorted, gap, config),
      );
    }

    rawRanges = config.mergeNearbyTripsGap == null
        ? rawRanges
        : _mergeAdjacent(rawRanges, sorted, config.mergeNearbyTripsGap!);

    final th = thresholds ?? RouteIntelligenceThresholds.defaults;
    final out = <TripSegment>[];
    var displayIdx = 0;

    for (final range in rawRanges) {
      final slice = sorted.sublist(range.start, range.end + 1).toList(growable: false);
      if (!_passesTripFilters(slice, config)) continue;
      displayIdx++;

      final start = slice.first;
      final end = slice.last;
      final duration = end.fixTime.difference(start.fixTime);
      final km = tripPathDistanceKm(slice);
      final speeds = slice.map((p) => p.speed).toList();
      final maxSpd =
          speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a > b ? a : b);
      final avgSpd =
          tripAverageSpeedKmh(slice, distanceKm: km, duration: duration);

      var analysis = RouteEventAnalyzer.analyze(slice, thresholds: th);
      analysis = enrichRouteIntelStopsFromRoutePoints(analysis, slice);

      final sum = analysis.summary;
      final ign = _splitIgnitionCounts(analysis);

      final startAddr =
          start.address?.trim().isNotEmpty ?? false ? start.address?.trim() : null;
      final endAddr =
          end.address?.trim().isNotEmpty ?? false ? end.address?.trim() : null;

      final key =
          '${vehicleId}_${start.fixTime.toUtc().millisecondsSinceEpoch}_${end.fixTime.toUtc().millisecondsSinceEpoch}_i$displayIdx';

      out.add(
        TripSegment(
          selectionKey: key,
          vehicleId: vehicleId,
          index: displayIdx,
          startTime: start.fixTime,
          endTime: end.fixTime,
          duration: duration,
          startPosition: start.position,
          endPosition: end.position,
          distanceKm: km,
          maxSpeedKmh: maxSpd,
          avgSpeedKmh: avgSpd,
          stopCount: sum.stopCount,
          totalStopDuration: sum.totalStopDuration,
          overspeedCount: sum.overspeedCount,
          ignitionOnCount: ign.$1,
          ignitionOffCount: ign.$2,
          hasIgnitionData: analysis.ignitionDataLikelyPresent,
          startAddress: startAddr,
          endAddress: endAddr,
        ),
      );
    }

    return out;
  }

  static (int on, int off) _splitIgnitionCounts(RouteEventAnalysisResult a) {
    if (!a.ignitionDataLikelyPresent) return (0, 0);
    var on = 0;
    var off = 0;
    for (final e in a.ignitions) {
      if (e.on) {
        on++;
      } else {
        off++;
      }
    }
    return (on, off);
  }

  /// Indices of contiguous stretches where neighbouring samples are closer than [maxGap].
  static List<TripIndexRange> _splitByMaxPointGap(
    List<RoutePoint> sorted,
    Duration maxGap,
  ) {
    if (sorted.isEmpty) return const [];
    final out = <TripIndexRange>[];
    var segStart = 0;
    for (var i = 1; i < sorted.length; i++) {
      final dt = sorted[i].fixTime.difference(sorted[i - 1].fixTime);
      if (dt > maxGap) {
        out.add(TripIndexRange(segStart, i - 1));
        segStart = i;
      }
    }
    out.add(TripIndexRange(segStart, sorted.length - 1));
    return out;
  }

  /// Moving-trip ranges inside inclusive global indices [gapStart, gapEnd].
  static List<TripIndexRange> _movingRangesInSlice(
    List<RoutePoint> sorted,
    TripIndexRange gap,
    TripSegmentationConfig config,
  ) {
    final ranges = <TripIndexRange>[];
    final lo = gap.start;
    final hi = gap.end;
    if (lo > hi) return ranges;

    int? tripStart;
    int? lastMoveIdx;
    var stationaryAccum = Duration.zero;

    bool moving(RoutePoint p) =>
        p.speed >= config.movingSpeedKmh ||
        (p.ignition && p.speed >= config.ignitionAssistMinSpeedKmh);

    void emit() {
      final ts = tripStart;
      final lm = lastMoveIdx;
      if (ts == null || lm == null) return;
      if (lm < ts) return;
      ranges.add(TripIndexRange(ts, lm));
    }

    for (var i = lo; i <= hi; i++) {
      final p = sorted[i];

      if (tripStart == null) {
        if (moving(p)) {
          tripStart = i;
          lastMoveIdx = i;
          stationaryAccum = Duration.zero;
        }
        continue;
      }

      final dtUp =
          i == lo ? Duration.zero : p.fixTime.difference(sorted[i - 1].fixTime);

      if (moving(p)) {
        stationaryAccum = Duration.zero;
        lastMoveIdx = i;
      } else {
        stationaryAccum += dtUp;
        if (stationaryAccum >= config.stopGapDuration && lastMoveIdx != null) {
          emit();
          tripStart = null;
          lastMoveIdx = null;
          stationaryAccum = Duration.zero;
          if (moving(p)) {
            tripStart = i;
            lastMoveIdx = i;
            stationaryAccum = Duration.zero;
          }
        }
      }
    }

    if (tripStart != null && lastMoveIdx != null) {
      emit();
    }

    return ranges;
  }

  static List<TripIndexRange> _mergeAdjacent(
    List<TripIndexRange> ranges,
    List<RoutePoint> sorted,
    Duration maxGap,
  ) {
    if (ranges.length < 2) return ranges;
    final out = <TripIndexRange>[ranges.first];
    for (var k = 1; k < ranges.length; k++) {
      final prev = out.last;
      final next = ranges[k];
      final tPrevEnd = sorted[prev.end].fixTime;
      final tNextStart = sorted[next.start].fixTime;
      final gap = tNextStart.difference(tPrevEnd);
      if (gap <= maxGap && next.start >= prev.start) {
        out[out.length - 1] = TripIndexRange(prev.start, next.end);
      } else {
        out.add(next);
      }
    }
    return out;
  }

  static bool _passesTripFilters(List<RoutePoint> slice, TripSegmentationConfig c) {
    if (slice.length < 2) return false;
    final dur = slice.last.fixTime.difference(slice.first.fixTime);
    if (dur < c.minTripDuration) return false;
    if (tripPathDistanceKm(slice) < c.minTripDistanceKm) return false;
    return true;
  }
}
