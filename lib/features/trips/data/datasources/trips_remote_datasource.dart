import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/trip_model.dart';

class TripsRemoteDataSource {
  const TripsRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches trips for a device (vehicleId = Traccar deviceId).
  ///
  /// Defaults to the last 30 days when [from]/[to] are not provided.
  Future<List<TripModel>> getVehicleTrips(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final now = DateTime.now().toUtc();
    final fromDate = (from ?? now.subtract(const Duration(days: 30))).toUtc();
    final toDate = (to ?? now).toUtc();

    return (await _client.get<List<TripModel>>(
      TraccarEndpoints.reportTrips,
      query: {
        'deviceId': int.tryParse(vehicleId) ?? vehicleId,
        'from': fromDate.toIso8601String(),
        'to': toDate.toIso8601String(),
      },
      fromJson: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(TripModel.fromJson)
          .toList(),
    )).getOrThrow();
  }

  /// Fetches a single trip by its composite identifier.
  /// Traccar doesn't have GET /trips/:id — we fetch the device trips
  /// and find the matching one by its generated id.
  Future<TripModel> getTrip(String id) async {
    // id format: "{deviceId}_{startTime}"
    final parts = id.split('_');
    if (parts.length >= 2) {
      final deviceId = parts[0];
      final trips = await getVehicleTrips(deviceId);
      return trips.firstWhere(
        (t) => t.id == id,
        orElse: () => trips.first,
      );
    }
    throw Exception('Invalid trip id: $id');
  }
}
