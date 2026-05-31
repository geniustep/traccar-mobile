import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../models/summary_report_model.dart';
import '../models/stop_report_model.dart';
import '../models/event_report_model.dart';
import '../reports_request_gate.dart';

/// Handles all Traccar reports API calls for the reports feature.
class ReportsRemoteDataSource {
  ReportsRemoteDataSource(this._client, this._gate);

  final TraccarClient _client;
  final ReportsRequestGate _gate;

  Future<SummaryReportModel?> getSummary({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    String trigger = 'provider',
  }) async {
    return _gate.run(
      reportType: 'summary',
      deviceId: deviceId,
      from: from,
      to: to,
      trigger: trigger,
      fetcher: (fromN, toN) async {
        final results = (await _client.get<List<SummaryReportModel>>(
          TraccarEndpoints.reportSummary,
          query: _query(deviceId, fromN, toN),
          fromJson: (data) => (data as List)
              .whereType<Map<String, dynamic>>()
              .map(SummaryReportModel.fromJson)
              .toList(),
        )).getOrThrow();

        return results.isNotEmpty ? results.first : null;
      },
    );
  }

  Future<List<StopReportModel>> getStops({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    String trigger = 'provider',
  }) async {
    return _gate.run(
      reportType: 'stops',
      deviceId: deviceId,
      from: from,
      to: to,
      trigger: trigger,
      fetcher: (fromN, toN) async {
        return (await _client.get<List<StopReportModel>>(
          TraccarEndpoints.reportStops,
          query: _query(deviceId, fromN, toN),
          fromJson: (data) => (data as List)
              .whereType<Map<String, dynamic>>()
              .map(StopReportModel.fromJson)
              .toList(),
        )).getOrThrow();
      },
    );
  }

  Future<List<EventReportModel>> getEvents({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    List<String>? types,
    String trigger = 'provider',
  }) async {
    return _gate.run(
      reportType: 'events',
      deviceId: deviceId,
      from: from,
      to: to,
      trigger: trigger,
      fetcher: (fromN, toN) async {
        final nameMap = await _gate.deviceNameMap(trigger: trigger);

        final params = <String, dynamic>{
          ..._query(deviceId, fromN, toN),
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
      },
    );
  }

  Future<List<TripModel>> getTrips({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    String trigger = 'provider',
  }) async {
    return _gate.run(
      reportType: 'trips',
      deviceId: deviceId,
      from: from,
      to: to,
      trigger: trigger,
      fetcher: (fromN, toN) async {
        return (await _client.get<List<TripModel>>(
          TraccarEndpoints.reportTrips,
          query: _query(deviceId, fromN, toN),
          fromJson: (data) => (data as List)
              .whereType<Map<String, dynamic>>()
              .map(TripModel.fromJson)
              .toList(),
        )).getOrThrow();
      },
    );
  }

  Future<List<RoutePoint>> getRoute({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    String trigger = 'provider',
  }) async {
    return _gate.run(
      reportType: 'route',
      deviceId: deviceId,
      from: from,
      to: to,
      trigger: trigger,
      fetcher: (fromN, toN) async {
        final raw = (await _client.get<List<Map<String, dynamic>>>(
          TraccarEndpoints.reportRoute,
          query: _query(deviceId, fromN, toN),
          fromJson: (j) =>
              (j as List).whereType<Map<String, dynamic>>().toList(),
        )).getOrThrow();

        return raw.map(RoutePoint.fromJson).toList();
      },
    );
  }

  Map<String, dynamic> _query(
    String deviceId,
    DateTime from,
    DateTime to,
  ) =>
      {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };
}
