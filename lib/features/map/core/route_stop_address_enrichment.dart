import '../data/datasources/route_datasource.dart';
import 'route_event_models.dart';
import 'route_stop_address_resolver.dart';

bool _timeInStopWindow(DateTime t, DateTime start, DateTime end) =>
    !t.isBefore(start) && !t.isAfter(end);

String? _firstNonEmptyAddressInWindow(
  List<RoutePoint> points,
  DateTime start,
  DateTime end,
) {
  for (final p in points) {
    if (!_timeInStopWindow(p.fixTime, start, end)) continue;
    final a = p.address?.trim();
    if (a != null && a.isNotEmpty) return a;
  }
  return null;
}

/// Fills [RouteStopEvent.address] from [RoutePoint.address] inside each stop window.
/// Does not call the analyzer and does not geocode (Phase 7D — server data only).
List<RouteStopEvent> mergeStopAddressesFromRoutePoints(
  List<RouteStopEvent> stops,
  List<RoutePoint> points,
) {
  if (stops.isEmpty || points.isEmpty) return stops;

  return stops
      .map((s) {
        final existing = s.address?.trim();
        if (existing != null && existing.isNotEmpty) return s;
        final fromPts =
            _firstNonEmptyAddressInWindow(points, s.startTime, s.endTime);
        if (fromPts == null) return s;
        return RouteStopEvent(
          startTime: s.startTime,
          endTime: s.endTime,
          latitude: s.latitude,
          longitude: s.longitude,
          address: fromPts,
        );
      })
      .toList(growable: false);
}

/// Applies [mergeStopAddressesFromRoutePoints] to a full analysis result.
RouteEventAnalysisResult enrichRouteIntelStopsFromRoutePoints(
  RouteEventAnalysisResult analysis,
  List<RoutePoint> points,
) {
  if (analysis.stops.isEmpty) return analysis;
  final merged = mergeStopAddressesFromRoutePoints(analysis.stops, points);
  return analysis.withStops(merged);
}

List<RouteStopEvent> replaceStopAddressOnList(
  List<RouteStopEvent> stops,
  RouteStopEvent target,
  String address,
) {
  return [
    for (final e in stops)
      if (e.startTime == target.startTime &&
          e.endTime == target.endTime &&
          e.latitude == target.latitude &&
          e.longitude == target.longitude)
        RouteStopEvent(
          startTime: e.startTime,
          endTime: e.endTime,
          latitude: e.latitude,
          longitude: e.longitude,
          address: address,
        )
      else
        e,
  ];
}

/// Async geocode up to [maxGeocode] stops missing addresses; calls [apply] after each hit.
Future<void> prefetchStopAddressesSequential({
  required RouteStopAddressResolver resolver,
  required RouteEventAnalysisResult intel,
  required bool Function() isStale,
  required void Function(RouteEventAnalysisResult updated) apply,
  int maxGeocode = 20,
}) async {
  var current = intel;
  final candidates = current.stops
      .where((s) => s.address == null || s.address!.trim().isEmpty)
      .take(maxGeocode)
      .toList();

  for (final s in candidates) {
    if (isStale()) return;
    final addr = await resolver.resolveStop(s);
    if (addr == null || addr.isEmpty) continue;
    if (isStale()) return;
    final patched = replaceStopAddressOnList(current.stops, s, addr);
    current = current.withStops(patched);
    apply(current);
  }
}
