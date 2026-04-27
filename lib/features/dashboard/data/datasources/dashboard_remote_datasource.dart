import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/dashboard_summary_model.dart';
import '../models/insight_model.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Computes dashboard summary from Traccar data (no dedicated endpoint exists).
  ///
  /// Makes three parallel calls:
  ///   1. `GET /devices`    — device statuses
  ///   2. `GET /positions`  — latest positions (for moving/idle/stopped)
  ///   3. `GET /reports/trips`  — today's trips (count + distance)
  ///   4. `GET /reports/events` — today's events (alert count)
  Future<DashboardSummaryModel> getSummary() async {
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);

    // 1. Devices + positions in parallel
    final baseResults = await Future.wait([
      _fetchRaw(TraccarEndpoints.devices),
      _fetchRaw(TraccarEndpoints.positions),
    ]);
    final devices = baseResults[0];
    final positions = baseResults[1];

    // 2. Reports only when there are devices (avoids 400 errors)
    List<Map<String, dynamic>> trips = [];
    List<Map<String, dynamic>> events = [];

    if (devices.isNotEmpty) {
      final deviceIds = devices
          .map((d) => d['id'])
          .whereType<int>()
          .toList();

      final reportResults = await Future.wait([
        _fetchRaw(TraccarEndpoints.reportTrips, params: {
          'from': todayStart.toIso8601String(),
          'to': now.toIso8601String(),
          'deviceId': deviceIds,
        }),
        _fetchRaw(TraccarEndpoints.reportEvents, params: {
          'from': todayStart.toIso8601String(),
          'to': now.toIso8601String(),
          'deviceId': deviceIds,
        }),
      ]);
      trips = reportResults[0];
      events = reportResults[1];
    }

    return DashboardSummaryModel.fromTraccar(
      devices: devices,
      positions: positions,
      trips: trips,
      events: events,
    );
  }

  /// Traccar has no insights endpoint.
  /// Derive insights from today's events (most frequent alert types).
  Future<List<InsightModel>> getInsights() async {
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);

    final devices = await _fetchRaw(TraccarEndpoints.devices);
    if (devices.isEmpty) return [];

    final deviceIds = devices
        .map((d) => d['id'])
        .whereType<int>()
        .toList();
    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    final events = await _fetchRaw(TraccarEndpoints.reportEvents, params: {
      'from': todayStart.toIso8601String(),
      'to': now.toIso8601String(),
      'deviceId': deviceIds,
    });

    // Group by type and create one insight per type
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final e in events) {
      final t = e['type'] as String? ?? 'unknown';
      (grouped[t] ??= []).add(e);
    }

    int idx = 0;
    return grouped.entries.map((entry) {
      final type = entry.key;
      final list = entry.value;
      final dId = list.first['deviceId'] as int?;
      return InsightModel(
        id: 'insight_${idx++}',
        type: type,
        title: _insightTitle(type),
        description: '${list.length} حدث اليوم',
        severity: _insightSeverity(type),
        icon: _insightIcon(type),
        createdAt: DateTime.now(),
        vehicleId: dId?.toString(),
        deviceName: dId != null ? (nameMap[dId] ?? '') : null,
      );
    }).toList();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

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

  static String _insightTitle(String type) {
    const map = {
      'deviceOverspeed': 'تجاوز السرعة',
      'geofenceExit': 'خروج من المنطقة',
      'geofenceEnter': 'دخول المنطقة',
      'alarm': 'إنذار',
      'deviceOffline': 'أجهزة غير متصلة',
      'deviceOnline': 'أجهزة متصلة',
    };
    return map[type] ?? type;
  }

  static String _insightSeverity(String type) {
    if (type == 'alarm' || type == 'deviceOverspeed') return 'high';
    if (type == 'geofenceExit') return 'medium';
    return 'info';
  }

  static String _insightIcon(String type) {
    const map = {
      'deviceOverspeed': 'speed',
      'geofenceExit': 'location_off',
      'geofenceEnter': 'location_on',
      'alarm': 'warning',
      'deviceOffline': 'signal_wifi_off',
      'deviceOnline': 'wifi',
    };
    return map[type] ?? 'info';
  }
}
