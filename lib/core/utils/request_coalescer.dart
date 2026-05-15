import '../logging/app_logger.dart';

/// In-flight request deduplication.
///
/// When the same logical request (identified by [key]) is already running,
/// subsequent callers receive the same [Future] instead of firing a new
/// network call.  A short TTL cache keeps the last successful result for
/// [cacheTtl] so that near-simultaneous invalidations of multiple providers
/// within the same refresh cycle share data without extra HTTP round-trips.
///
/// Phase 5: Added [normalizeReportKey] to prevent near-identical timestamps
/// from creating duplicate cache keys during the same refresh cycle.
class RequestCoalescer {
  RequestCoalescer({this.cacheTtl = const Duration(seconds: 5)});

  final Duration cacheTtl;

  final Map<String, Future<dynamic>> _inFlight = {};
  final Map<String, _CacheEntry> _cache = {};

  /// Returns a cached or in-flight result, or starts [fetcher].
  ///
  /// [key] should uniquely identify the logical request (e.g. endpoint + params).
  Future<T> coalesce<T>(String key, Future<T> Function() fetcher) async {
    final normalizedKey = normalizeReportKey(key);

    // 1. Fresh cache hit
    final cached = _cache[normalizedKey];
    if (cached != null && !cached.isExpired) {
      AppLogger.dashboard('[Coalescer] cache hit: $normalizedKey');
      return cached.data as T;
    }

    // 2. In-flight dedup
    if (_inFlight.containsKey(normalizedKey)) {
      AppLogger.dashboard('[Coalescer] joined in-flight: $normalizedKey');
      return await _inFlight[normalizedKey]! as T;
    }

    // 3. New request — store the Future itself so all callers share it.
    AppLogger.dashboard('[Coalescer] new request: $normalizedKey');

    final future = fetcher().then<T>((result) {
      _cache[normalizedKey] = _CacheEntry(
        data: result,
        createdAt: DateTime.now(),
        ttl: cacheTtl,
      );
      return result;
    }).whenComplete(() {
      _inFlight.remove(normalizedKey);
    });

    _inFlight[normalizedKey] = future;
    return await future;
  }

  /// Evicts all cached entries (call at the start of a new manual refresh).
  void invalidateAll() {
    _cache.clear();
    AppLogger.dashboard('[Coalescer] all cache invalidated');
  }

  /// Evicts a single cached entry.
  void invalidate(String key) {
    _cache.remove(normalizeReportKey(key));
  }

  /// Normalizes report cache keys to prevent tiny timestamp differences
  /// from creating duplicate entries within the same refresh cycle.
  ///
  /// Keys like `reports_events|2026-05-14T00:00:00.000Z|2026-05-14T11:51:27.734540Z`
  /// and `reports_events|2026-05-14T00:00:00.000Z|2026-05-14T11:51:26.878901Z`
  /// are collapsed into the same key by rounding the "to" timestamp to the
  /// nearest minute.
  static String normalizeReportKey(String key) {
    if (!key.startsWith('reports_')) return key;

    final parts = key.split('|');
    if (parts.length != 3) return key;

    // Normalize the "to" timestamp — round to minute boundary
    final toStr = parts[2];
    final toDate = DateTime.tryParse(toStr);
    if (toDate == null) return key;

    // Round to minute — eliminates sub-minute differences in the same cycle
    final rounded = DateTime.utc(
      toDate.year,
      toDate.month,
      toDate.day,
      toDate.hour,
      toDate.minute,
    );

    return '${parts[0]}|${parts[1]}|${rounded.toIso8601String()}';
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.createdAt, required this.ttl});

  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}
