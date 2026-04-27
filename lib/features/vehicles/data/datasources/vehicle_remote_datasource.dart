import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/vehicle_model.dart';

class VehicleRemoteDataSource {
  const VehicleRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches all devices and merges with their latest positions.
  Future<List<VehicleModel>> getVehicles() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _fetchDevices(),
      _fetchPositions(),
    ]);

    final devices = results[0];
    final positions = results[1];

    // Index positions by deviceId for O(1) lookup
    final posMap = <int, Map<String, dynamic>>{
      for (final p in positions)
        if (p['deviceId'] is int) (p['deviceId'] as int): p,
    };

    return devices.map((d) {
      final pos = posMap[d['id'] as int?];
      return VehicleModel.fromTraccar(d, pos);
    }).toList();
  }

  /// Fetches a single device merged with its latest position.
  Future<VehicleModel> getVehicle(String id) async {
    final deviceId = int.parse(id);

    final deviceFuture = _client.get<Map<String, dynamic>>(
      TraccarEndpoints.deviceById(deviceId),
      fromJson: (j) => j as Map<String, dynamic>,
    );
    final positionsFuture = _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.positions,
      query: {'deviceId': deviceId},
      fromJson: (j) => (j as List)
          .whereType<Map<String, dynamic>>()
          .toList(),
    );

    final deviceResult = await deviceFuture;
    final positionsResult = await positionsFuture;

    final device = deviceResult.getOrThrow();
    final positions = positionsResult.getOrThrow();
    final pos = positions.isNotEmpty ? positions.first : null;

    return VehicleModel.fromTraccar(device, pos);
  }

  /// Live position — same as getVehicle (Traccar always returns latest).
  Future<VehicleModel> getVehicleLive(String id) => getVehicle(id);

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchDevices() async =>
      (await _client.get<List<Map<String, dynamic>>>(
        TraccarEndpoints.devices,
        fromJson: (j) =>
            (j as List).whereType<Map<String, dynamic>>().toList(),
      )).getOrThrow();

  Future<List<Map<String, dynamic>>> _fetchPositions() async =>
      (await _client.get<List<Map<String, dynamic>>>(
        TraccarEndpoints.positions,
        fromJson: (j) =>
            (j as List).whereType<Map<String, dynamic>>().toList(),
      )).getOrThrow();
}
