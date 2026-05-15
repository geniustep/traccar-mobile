/// Pluggable reverse lookup for stop coordinates (Phase 7D).
///
/// Default app binding uses [NoOpStopReverseGeocoder] — no outbound API.
/// Replace via [stopReverseGeocoderProvider] when a backend or SDK is wired.
abstract class StopReverseGeocoder {
  const StopReverseGeocoder();

  /// Returns a short human-readable line, or null if unavailable.
  Future<String?> reverseGeocode(double latitude, double longitude);
}

/// Resolves immediately with null — avoids blocking and adds no dependencies.
class NoOpStopReverseGeocoder extends StopReverseGeocoder {
  const NoOpStopReverseGeocoder();

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) =>
      Future.value(null);
}
