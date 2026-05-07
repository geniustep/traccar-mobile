import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../models/summary_report_model.dart';
import '../models/stop_report_model.dart';
import '../models/event_report_model.dart';

/// Handles all Traccar reports API calls for the reports feature.
///
/// All date parameters must be UTC-converted before being passed here;
/// this datasource forwards them as-is to Traccar.
class ReportsRemoteDataSource {
  const ReportsRemoteDataSource(this._client);

  final TraccarClient _client;

  // ── Summary ────────────────────────────────────────────────────────────────

  /// `GET /reports/summary` — fleet summary for one device over a time range.
  Future<SummaryReportModel?> getSummary({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final results = (await _client.get<List<SummaryReportModel>>(
      TraccarEndpoints.reportSummary,
      query: {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      fromJson: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(SummaryReportModel.fromJson)
          .toList(),
    )).getOrThrow();

    return results.isNotEmpty ? results.first : null;
  }

  // ── Stops ──────────────────────────────────────────────────────────────────

  /// `GET /reports/stops` — list of stops for a device over a time range.
  Future<List<StopReportModel>> getStops({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return (await _client.get<List<StopReportModel>>(
      TraccarEndpoints.reportStops,
      query: {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      fromJson: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(StopReportModel.fromJson)
          .toList(),
    )).getOrThrow();
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  /// `GET /reports/events` — list of events for a device over a time range.
  ///
  /// Device names are resolved by fetching the device list once and injecting
  /// into each event (same pattern as [AlertsRemoteDataSource]).
  Future<List<EventReportModel>> getEvents({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    List<String>? types,
  }) async {
    final devId = int.tryParse(deviceId);

    // Fetch device name map for enrichment
    final devices = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.devices,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    final params = <String, dynamic>{
      'deviceId': devId ?? deviceId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    };
    if (types != null && types.isNotEmpty) params['type'] = types;

    final events = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportEvents,
      query: params,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return events.map((e) {
      final dId = (e['deviceId'] as num?)?.toInt();
      return EventReportModel.fromJson(
        e,
        deviceName: dId != null ? (nameMap[dId] ?? '') : '',
      );
    }).toList();
  }

  // ── Trips ──────────────────────────────────────────────────────────────────

  /// `GET /reports/trips` — trip list for a device over a time range.
  Future<List<TripModel>> getTrips({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return (await _client.get<List<TripModel>>(
      TraccarEndpoints.reportTrips,
      query: {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      fromJson: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(TripModel.fromJson)
          .toList(),
    )).getOrThrow();
  }

  // ── Route ──────────────────────────────────────────────────────────────────

  /// `GET /reports/route` — GPS route points for a device over a time range.
  Future<List<RoutePoint>> getRoute({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportRoute,
      query: {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return raw.map(RoutePoint.fromJson).toList();
  }
}
