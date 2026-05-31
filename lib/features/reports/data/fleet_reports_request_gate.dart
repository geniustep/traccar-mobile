import '../../../core/api/traccar_endpoints.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/traccar_client.dart';
import '../../../core/utils/report_request_key.dart';
import '../../../core/utils/request_coalescer.dart';
import '../../trips/data/models/trip_model.dart';

/// Shared deduplication for multi-device Traccar report calls (dashboard, fleet).
class FleetReportsRequestGate {
  FleetReportsRequestGate(this._client, this._coalescer);

  final TraccarClient _client;
  final RequestCoalescer _coalescer;

  RequestCoalescer get coalescer => _coalescer;

  void resetCache() => _coalescer.invalidateAll();

  Future<List<Map<String, dynamic>>> fetchEvents({
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
    required String trigger,
  }) {
    return _runRawList(
      reportType: 'events',
      path: TraccarEndpoints.reportEvents,
      deviceIds: deviceIds,
      fromUtc: fromUtc,
      toUtc: toUtc,
      trigger: trigger,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTripsRaw({
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
    required String trigger,
  }) {
    return _runRawList(
      reportType: 'trips',
      path: TraccarEndpoints.reportTrips,
      deviceIds: deviceIds,
      fromUtc: fromUtc,
      toUtc: toUtc,
      trigger: trigger,
    );
  }

  Future<({List<TripModel> trips, List<Map<String, dynamic>> events})>
      fetchTripsAndEvents({
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
    required String trigger,
  }) async {
    final results = await Future.wait([
      fetchTripsRaw(
        deviceIds: deviceIds,
        fromUtc: fromUtc,
        toUtc: toUtc,
        trigger: trigger,
      ),
      fetchEvents(
        deviceIds: deviceIds,
        fromUtc: fromUtc,
        toUtc: toUtc,
        trigger: trigger,
      ),
    ]);
    final trips =
        results[0].map((j) => TripModel.fromJson(j)).toList();
    return (trips: trips, events: results[1]);
  }

  Future<List<Map<String, dynamic>>> _runRawList({
    required String reportType,
    required String path,
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
    required String trigger,
  }) {
    if (deviceIds.isEmpty) return Future.value([]);

    final fromN = ReportRequestKey.normalizeUtc(fromUtc);
    final toN = ReportRequestKey.normalizeUtc(toUtc);
    final normalizedKey = ReportRequestKey.build(
      reportType: reportType,
      deviceIds: deviceIds,
      from: fromN,
      to: toN,
    );
    final sortedIds = [...deviceIds]..sort();

    AppLogger.reports(
      'scheduled type=$reportType deviceIds=$sortedIds '
      'from=${fromN.toIso8601String()} to=${toN.toIso8601String()} '
      'trigger=$trigger normalizedKey=$normalizedKey',
      source: trigger,
    );

    return _coalescer.coalesce<List<Map<String, dynamic>>>(
      normalizedKey,
      () async {
        AppLogger.reports(
          'request start type=$reportType deviceIds=$sortedIds '
          'from=${fromN.toIso8601String()} to=${toN.toIso8601String()} '
          'trigger=$trigger normalizedKey=$normalizedKey',
          source: trigger,
        );
        final sw = Stopwatch()..start();
        try {
          final data = await _fetchRaw(
            path,
            from: fromN,
            to: toN,
            deviceIds: deviceIds,
          );
          sw.stop();
          AppLogger.reports(
            'request ok type=$reportType deviceIds=$sortedIds '
            'durationMs=${sw.elapsedMilliseconds} trigger=$trigger '
            'normalizedKey=$normalizedKey',
            durationMs: sw.elapsedMilliseconds,
            source: trigger,
          );
          return data;
        } catch (e, st) {
          sw.stop();
          AppLogger.reportsError(
            'request failed type=$reportType deviceIds=$sortedIds '
            'trigger=$trigger normalizedKey=$normalizedKey error=$e',
            source: trigger,
          );
          Error.throwWithStackTrace(e, st);
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRaw(
    String path, {
    required DateTime from,
    required DateTime to,
    required List<int> deviceIds,
  }) async =>
      (await _client.get<List<Map<String, dynamic>>>(
        path,
        query: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
          'deviceId': deviceIds,
        },
        fromJson: (j) =>
            (j as List).whereType<Map<String, dynamic>>().toList(),
      )).getOrThrow();
}
