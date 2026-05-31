import '../api/traccar_endpoints.dart';
import '../network/traccar_client.dart';
import '../utils/request_coalescer.dart';

/// Central deduplicated access to fleet `GET /devices` and `GET /positions`.
///
/// Shares [RequestCoalescer] with [FleetReportsRequestGate] so dashboard,
/// vehicles list, and fleet snapshot reuse the same in-flight/cache keys.
class FleetBaseDataGate {
  FleetBaseDataGate(this._client, this._coalescer);

  final TraccarClient _client;
  final RequestCoalescer _coalescer;

  Future<List<Map<String, dynamic>>> fetchDevices() {
    return _coalescer.coalesce(
      'app_devices',
      () => _fetchList(TraccarEndpoints.devices),
    );
  }

  Future<List<Map<String, dynamic>>> fetchPositions() {
    return _coalescer.coalesce(
      'app_positions',
      () => _fetchList(TraccarEndpoints.positions),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchList(String path) async =>
      (await _client.get<List<Map<String, dynamic>>>(
        path,
        fromJson: (j) =>
            (j as List).whereType<Map<String, dynamic>>().toList(),
      )).getOrThrow();
}
