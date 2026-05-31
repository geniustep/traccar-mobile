import '../logging/app_logger.dart';
import 'report_request_key.dart';

/// In-flight request deduplication.
///
/// When the same logical request (identified by [key]) is already running,
/// subsequent callers receive the same [Future] instead of firing a new
/// network call.  A short TTL cache keeps the last successful result for
/// [cacheTtl] so that near-simultaneous invalidations of multiple providers
/// within the same refresh cycle share data without extra HTTP round-trips.
class RequestCoalescer {
  RequestCoalescer({this.cacheTtl = const Duration(seconds: 5)});

  final Duration cacheTtl;

  final Map<String, Future<dynamic>> _inFlight = {};
  final Map<String, _CacheEntry> _cache = {};

  /// Returns a cached or in-flight result, or starts [fetcher].
  ///
  /// [key] should uniquely identify the logical request (e.g. endpoint + params).
  Future<T> coalesce<T>(String key, Future<T> Function() fetcher) async {
    final normalizedKey = ReportRequestKey.normalizeKey(key);

    // 1. Fresh cache hit
    final cached = _cache[normalizedKey];
    if (cached != null && !cached.isExpired) {
      _logReportsDedup('cache hit', normalizedKey);
      return cached.data as T;
    }

    // 2. In-flight dedup
    if (_inFlight.containsKey(normalizedKey)) {
      _logReportsDedup('joined in-flight', normalizedKey);
      return await _inFlight[normalizedKey]! as T;
    }

    // 3. New request — store the Future itself so all callers share it.
    if (normalizedKey.startsWith('reports_')) {
      AppLogger.reports('new request normalizedKey=$normalizedKey');
    } else {
      AppLogger.dashboard('[Coalescer] new request: $normalizedKey');
    }

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
    _cache.remove(ReportRequestKey.normalizeKey(key));
  }

  static void _logReportsDedup(String action, String normalizedKey) {
    if (!normalizedKey.startsWith('reports_')) {
      AppLogger.dashboard('[Coalescer] $action: $normalizedKey');
      return;
    }
    AppLogger.reports('skipped duplicate $action normalizedKey=$normalizedKey');
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.createdAt, required this.ttl});

  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}
