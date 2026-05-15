import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../trips/data/models/trip_model.dart';

/// جلب رحلات وأحداث مدمجة لعدة أجهزة دفعة واحدة (نفس نمط لوحة التحكم الحالية).
class FleetIntelligenceRemoteDataSource {
  const FleetIntelligenceRemoteDataSource(this._client);

  final TraccarClient _client;

  Future<List<Map<String, dynamic>>> _fetchRaw(
    String path, {
    Map<String, dynamic>? params,
  }) async =>
      (await _client.get<List<Map<String, dynamic>>>(
        path,
        query: params,
        fromJson: (j) =>
            (j as List).whereType<Map<String, dynamic>>().toList(),
      )).getOrThrow();

  Future<({List<TripModel> trips, List<Map<String, dynamic>> events})>
      fetchTripsAndEvents({
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (deviceIds.isEmpty) {
      return (trips: <TripModel>[], events: <Map<String, dynamic>>[]);
    }
    final p = {
      'from': fromUtc.toIso8601String(),
      'to': toUtc.toIso8601String(),
      'deviceId': deviceIds,
    };
    final raw = await Future.wait([
      _fetchRaw(TraccarEndpoints.reportTrips, params: p),
      _fetchRaw(TraccarEndpoints.reportEvents, params: p),
    ]);
    final trips = raw[0].map(TripModel.fromJson).toList();
    return (trips: trips, events: raw[1]);
  }
}
