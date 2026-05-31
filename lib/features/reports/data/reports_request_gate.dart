import '../../../core/logging/app_logger.dart';
import '../../../core/utils/report_request_key.dart';
import '../../../core/utils/request_coalescer.dart';
import '../../../core/network/traccar_client.dart';
import '../../../core/api/traccar_endpoints.dart';

/// Deduplicates single-device Traccar report HTTP calls and logs request lifecycle.
class ReportsRequestGate {
  ReportsRequestGate(
    this._client,
    RequestCoalescer coalescer,
  ) : _coalescer = coalescer;

  final TraccarClient _client;
  final RequestCoalescer _coalescer;

  void resetCache() => _coalescer.invalidateAll();

  Future<T> run<T>({
    required String reportType,
    required String deviceId,
    required DateTime from,
    required DateTime to,
    required Future<T> Function(DateTime fromNorm, DateTime toNorm) fetcher,
    String trigger = 'provider',
  }) {
    final id = int.tryParse(deviceId);
    final deviceIds = id != null ? [id] : <int>[];
    final fromN = ReportRequestKey.normalizeUtc(from);
    final toN = ReportRequestKey.normalizeUtc(to);
    final normalizedKey = ReportRequestKey.build(
      reportType: reportType,
      deviceIds: deviceIds,
      from: fromN,
      to: toN,
    );

    AppLogger.reports(
      'scheduled type=$reportType deviceIds=[$deviceId] '
      'from=${fromN.toIso8601String()} to=${toN.toIso8601String()} '
      'trigger=$trigger normalizedKey=$normalizedKey',
      source: trigger,
    );

    return _coalescer.coalesce<T>(normalizedKey, () async {
      AppLogger.reports(
        'request start type=$reportType deviceIds=[$deviceId] '
        'from=${fromN.toIso8601String()} to=${toN.toIso8601String()} '
        'trigger=$trigger normalizedKey=$normalizedKey',
        source: trigger,
      );
      final sw = Stopwatch()..start();
      try {
        final result = await fetcher(fromN, toN);
        sw.stop();
        AppLogger.reports(
          'request ok type=$reportType deviceIds=[$deviceId] '
          'durationMs=${sw.elapsedMilliseconds} trigger=$trigger '
          'normalizedKey=$normalizedKey',
          durationMs: sw.elapsedMilliseconds,
          source: trigger,
        );
        return result;
      } catch (e, st) {
        sw.stop();
        AppLogger.reportsError(
          'request failed type=$reportType deviceIds=[$deviceId] '
          'trigger=$trigger normalizedKey=$normalizedKey error=$e',
          source: trigger,
        );
        Error.throwWithStackTrace(e, st);
      }
    });
  }

  Future<Map<int, String>> deviceNameMap({String trigger = 'reports_events'}) {
    return _coalescer.coalesce<Map<int, String>>(
      'reports_devices_name_map',
      () async {
        AppLogger.reports(
          'request start type=devices_list deviceIds=[all] trigger=$trigger',
          source: trigger,
        );
        final devices = (await _client.get<List<Map<String, dynamic>>>(
          TraccarEndpoints.devices,
          fromJson: (j) =>
              (j as List).whereType<Map<String, dynamic>>().toList(),
        )).getOrThrow();

        final map = <int, String>{
          for (final d in devices)
            if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
        };
        AppLogger.reports(
          'request ok type=devices_list count=${map.length} trigger=$trigger',
          source: trigger,
        );
        return map;
      },
    );
  }
}
