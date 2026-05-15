import 'dart:math' as math;

import '../../reports/presentation/providers/reports_providers.dart';
import '../data/datasources/route_datasource.dart';
import 'trip_segment_models.dart';

bool _validLatLng(double lat, double lng) =>
    lat.abs() > 1e-6 || lng.abs() > 1e-6;

/// Haversine distance in km along route points, skipping invalid legs.
double tripPathDistanceKm(List<RoutePoint> points) {
  if (points.length < 2) return 0;
  const earthKm = 6371.0;
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1].position;
    final b = points[i].position;
    if (!_validLatLng(a.latitude, a.longitude) ||
        !_validLatLng(b.latitude, b.longitude)) {
      continue;
    }
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(dLng / 2), 2).toDouble();
    final c = 2 * math.asin(math.sqrt(math.min(1.0, h)));
    total += earthKm * c;
  }
  return total;
}

/// Average speed from distance / duration when duration is meaningful; otherwise
/// arithmetic mean of sample speeds.
double tripAverageSpeedKmh(
  List<RoutePoint> points, {
  required double distanceKm,
  required Duration duration,
}) {
  if (points.isEmpty) return 0;
  if (duration.inSeconds >= 60 && distanceKm > 0) {
    final h = duration.inSeconds / 3600.0;
    return distanceKm / h;
  }
  return points.map((p) => p.speed).reduce((a, b) => a + b) / points.length;
}

/// [ReportFilterParams] for fetching / replaying this trip window in UTC.
///
/// [startTime]/[endTime] must use the same timezone semantics as [RoutePoint.fixTime]
/// for the active trace (typically local device time from parsing).
ReportFilterParams reportFilterParamsForTrip({
  required String vehicleId,
  required DateTime startTime,
  required DateTime endTime,
  TripSegmentationConfig config = TripSegmentationConfig.defaults,
}) {
  final b = config.bufferForReportParams;
  return ReportFilterParams(
    vehicleId: vehicleId,
    from: startTime.toUtc().subtract(b),
    to: endTime.toUtc().add(b),
  );
}

/// Compact duration for list cards (locale-neutral; prefer [trip_formatters.dart] + l10n in UI).
String formatTripDurationCompact(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  final s = d.inSeconds.remainder(60);
  return '${s}s';
}

/// Formats distance with one decimal for list display.
String formatTripDistanceKmValue(double km) => km.toStringAsFixed(1);
