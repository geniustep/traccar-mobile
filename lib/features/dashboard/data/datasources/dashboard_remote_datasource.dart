import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/utils/request_coalescer.dart';
import '../models/dashboard_summary_model.dart';
import '../models/insight_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final TraccarClient _client;

  final RequestCoalescer _coalescer = RequestCoalescer();

  /// Invalidate cached data when a full manual refresh is requested.
  void resetCoalescer() => _coalescer.invalidateAll();

  /// Computes dashboard summary from Traccar data (no dedicated endpoint exists).
  ///
  /// Makes parallel calls with coalesced /devices and /positions to prevent
  /// duplicates when [getInsights] is also running in the same refresh cycle.
  Future<DashboardSummaryModel> getSummary({DateTime? refreshNow}) async {
    final now = refreshNow ?? DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final toIso = now.toIso8601String();
    final fromIso = todayStart.toIso8601String();

    // 1. Devices + positions in parallel (both coalesced)
    final baseResults = await Future.wait([
      _getDevicesCoalesced(),
      _getPositionsCoalesced(),
    ]);
    final devices = baseResults[0];
    final positions = baseResults[1];

    // 2. Reports only when there are devices
    List<Map<String, dynamic>> trips = [];
    List<Map<String, dynamic>> events = [];

    if (devices.isNotEmpty) {
      final deviceIds = devices
          .map((d) => d['id'])
          .whereType<int>()
          .toList();

      final tripsKey = 'reports_trips|$fromIso|$toIso';
      final eventsKey = 'reports_events|$fromIso|$toIso';

      final reportResults = await Future.wait([
        _coalescer.coalesce(tripsKey, () => _fetchRaw(
          TraccarEndpoints.reportTrips,
          params: {
            'from': fromIso,
            'to': toIso,
            'deviceId': deviceIds,
          },
        )),
        _coalescer.coalesce(eventsKey, () => _fetchRaw(
          TraccarEndpoints.reportEvents,
          params: {
            'from': fromIso,
            'to': toIso,
            'deviceId': deviceIds,
          },
        )),
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
  Future<List<InsightModel>> getInsights({DateTime? refreshNow}) async {
    final now = refreshNow ?? DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final toIso = now.toIso8601String();
    final fromIso = todayStart.toIso8601String();

    final devices = await _getDevicesCoalesced();
    if (devices.isEmpty) return [];

    final deviceIds = devices
        .map((d) => d['id'])
        .whereType<int>()
        .toList();
    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    final eventsKey = 'reports_events|$fromIso|$toIso';
    final events = await _coalescer.coalesce(eventsKey, () => _fetchRaw(
      TraccarEndpoints.reportEvents,
      params: {
        'from': fromIso,
        'to': toIso,
        'deviceId': deviceIds,
      },
    ));

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
        createdAt: now.toLocal(),
        vehicleId: dId?.toString(),
        deviceName: dId != null ? (nameMap[dId] ?? '') : null,
      );
    }).toList();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Coalesced /devices fetch — multiple callers in the same refresh cycle
  /// share a single HTTP call.
  Future<List<Map<String, dynamic>>> _getDevicesCoalesced() {
    return _coalescer.coalesce(
      'devices',
      () => _fetchRaw(TraccarEndpoints.devices),
    );
  }

  /// Coalesced /positions fetch — prevents duplicate requests when
  /// summary + other providers request positions simultaneously.
  Future<List<Map<String, dynamic>>> _getPositionsCoalesced() {
    return _coalescer.coalesce(
      'positions',
      () => _fetchRaw(TraccarEndpoints.positions),
    );
  }

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
