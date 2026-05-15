import 'route_event_models.dart';
import 'route_stop_address_cache.dart';
import 'stop_reverse_geocoder.dart';

/// Resolves approximate stop labels: embedded [RouteStopEvent.address] first,
/// then in-memory cache, then [StopReverseGeocoder] (Phase 7D).
class RouteStopAddressResolver {
  RouteStopAddressResolver({required StopReverseGeocoder geocoder})
      : _geocoder = geocoder;

  final StopReverseGeocoder _geocoder;

  final Map<String, String?> _cache = {};

  void clear() => _cache.clear();

  String cacheKey(double latitude, double longitude) =>
      routeStopAddressCacheKey(latitude, longitude);

  /// Uses [stop.address] when non-empty; otherwise cache + geocoder.
  Future<String?> resolveStop(RouteStopEvent stop) async {
    final embedded = stop.address?.trim();
    final key = cacheKey(stop.latitude, stop.longitude);
    if (embedded != null && embedded.isNotEmpty) {
      _cache[key] = embedded;
      return embedded;
    }

    if (_cache.containsKey(key)) return _cache[key];

    try {
      final resolved =
          await _geocoder.reverseGeocode(stop.latitude, stop.longitude);
      final trimmed = resolved?.trim();
      final out =
          (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
      _cache[key] = out;
      return out;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }

  /// Lookup by coordinates only (no embedded server address).
  Future<String?> resolveLatLng(double latitude, double longitude) async =>
      resolveStop(
        RouteStopEvent(
          startTime: DateTime.utc(1970),
          endTime: DateTime.utc(1970),
          latitude: latitude,
          longitude: longitude,
        ),
      );
}
