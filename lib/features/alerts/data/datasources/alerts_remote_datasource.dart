import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/alert_model.dart';

class AlertsRemoteDataSource {
  const AlertsRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches recent events from Traccar (= alerts).
  Future<List<AlertModel>> getAlerts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final events = await _fetchEvents(
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now(),
    );
    final start = (page - 1) * pageSize;
    final paged = events.skip(start).take(pageSize).toList();
    return paged;
  }

  /// Fetches critical events (SOS, alarm, overspeed).
  Future<List<AlertModel>> getSmartAlerts() async {
    final critical = ['alarm', 'deviceOverspeed'];
    return _fetchEvents(
      from: DateTime.now().subtract(const Duration(days: 7)),
      to: DateTime.now(),
      types: critical,
    );
  }

  /// Fetches events for a specific device (vehicleId = Traccar deviceId).
  Future<List<AlertModel>> getVehicleAlerts(String vehicleId) async {
    return _fetchEvents(
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now(),
      deviceId: int.tryParse(vehicleId),
    );
  }

  /// Mark as read is not natively supported by Traccar.
  /// This is a no-op; read state is managed locally in the app.
  Future<void> markAsRead(String alertId) async {}

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<List<AlertModel>> _fetchEvents({
    required DateTime from,
    required DateTime to,
    List<String>? types,
    int? deviceId,
  }) async {
    // 1. Fetch device name map for enrichment
    final devices = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.devices,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    // 2. Fetch events
    final params = <String, dynamic>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    };
    if (deviceId != null) params['deviceId'] = deviceId;
    if (types != null && types.isNotEmpty) params['type'] = types;

    final events = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportEvents,
      query: params,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return events.map((e) {
      final dId = e['deviceId'] as int?;
      return AlertModel.fromTraccarEvent(
        e,
        deviceName: dId != null ? (nameMap[dId] ?? '') : '',
      );
    }).toList();
  }
}
