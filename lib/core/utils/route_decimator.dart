import '../../features/map/data/datasources/route_datasource.dart';

/// Reduces a dense [RoutePoint] list to at most [maxPoints] for map rendering
/// while preserving the first point, the last point, and high-speed points.
///
/// The original list is never mutated; callers should use the full list for
/// statistics and the decimated list only for drawing polylines / markers.
class RoutePointDecimator {
  RoutePointDecimator._();

  static const int _defaultMax = 800;

  /// Returns a version of [points] suitable for Google Maps rendering.
  ///
  /// If `points.length <= maxPoints` the original list is returned unchanged.
  /// Otherwise an evenly-spaced sample is taken, with first and last always
  /// included.
  static List<RoutePoint> decimateForMap(
    List<RoutePoint> points, {
    int maxPoints = _defaultMax,
  }) {
    if (points.length <= maxPoints) return points;

    final result = <RoutePoint>[points.first];
    final innerCount = maxPoints - 2; // slots between first and last
    final step = (points.length - 2) / innerCount;

    for (var i = 1; i <= innerCount; i++) {
      result.add(points[(i * step).round().clamp(1, points.length - 2)]);
    }

    result.add(points.last);
    return result;
  }
}
