import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/analytics_model.dart';

class AnalyticsRemoteDataSource {
  const AnalyticsRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Builds weekly analytics from Traccar `GET /reports/summary` and `GET /reports/trips`.
  Future<AnalyticsModel> getWeeklyAnalytics() async {
    final now = DateTime.now().toUtc();
    final weekAgo = now.subtract(const Duration(days: 7));

    // 1. Get all device IDs
    final devices = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.devices,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    if (devices.isEmpty) return AnalyticsModel.empty();

    final deviceIds =
        devices.map((d) => d['id']).whereType<int>().toList();
    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    // 2. Fetch summary + trips + events in parallel
    final results = await Future.wait([
      _fetchRaw(TraccarEndpoints.reportSummary, params: {
        'from': weekAgo.toIso8601String(),
        'to': now.toIso8601String(),
        'deviceId': deviceIds,
      }),
      _fetchRaw(TraccarEndpoints.reportTrips, params: {
        'from': weekAgo.toIso8601String(),
        'to': now.toIso8601String(),
        'deviceId': deviceIds,
      }),
      _fetchRaw(TraccarEndpoints.reportEvents, params: {
        'from': weekAgo.toIso8601String(),
        'to': now.toIso8601String(),
        'deviceId': deviceIds,
        'type': ['deviceOverspeed', 'alarm'],
      }),
    ]);

    final summaries = results[0];
    final trips = results[1];
    final events = results[2];

    // ── Aggregates from summary ─────────────────────────────────────────────
    double totalDistance = 0;
    int totalEngineHoursMs = 0;
    double mostActiveDistance = 0;
    double leastEffDist = double.maxFinite;
    String mostActiveName = '--';
    String leastEffName = '--';

    for (final s in summaries) {
      final dist = (s['distance'] as num?)?.toDouble() ?? 0;
      final engineHours =
          (s['engineHours'] as num?)?.toInt() ?? 0;
      final dId = s['deviceId'] as int?;
      final name = dId != null ? (nameMap[dId] ?? '--') : '--';

      totalDistance += dist;
      totalEngineHoursMs += engineHours;

      if (dist > mostActiveDistance) {
        mostActiveDistance = dist;
        mostActiveName = name;
      }
      if (dist < leastEffDist && dist > 0) {
        leastEffDist = dist;
        leastEffName = name;
      }
    }

    final totalIdleMs = totalEngineHoursMs > 0
        ? (totalEngineHoursMs * 0.2).toInt()
        : 0;

    // ── Events ────────────────────────────────────────────────────────────
    final overspeedCount =
        events.where((e) => e['type'] == 'deviceOverspeed').length;
    final hardBrakingCount = events
        .where((e) =>
            e['type'] == 'alarm' &&
            (e['attributes'] as Map?)?['alarm'] == 'hardBraking')
        .length;

    // ── Daily breakdown from trips ─────────────────────────────────────────
    const dayNames = ['أحد', 'اثن', 'ثلث', 'أرب', 'خمس', 'جمع', 'سبت'];
    final dailyDist = <String, double>{};

    for (var i = 6; i >= 0; i--) {
      final day = now.toLocal().subtract(Duration(days: i));
      final label = dayNames[day.weekday % 7];
      dailyDist[label] = 0;
    }

    for (final t in trips) {
      final start = DateTime.tryParse(t['startTime'] as String? ?? '');
      if (start == null) continue;
      final label = dayNames[start.toLocal().weekday % 7];
      dailyDist[label] =
          (dailyDist[label] ?? 0) + ((t['distance'] as num?)?.toDouble() ?? 0);
    }

    final efficiencyScore = totalEngineHoursMs > 0 && totalDistance > 0
        ? (100.0 - (totalIdleMs / totalEngineHoursMs * 100.0)).clamp(0.0, 100.0)
        : 0.0;

    return AnalyticsModel(
      weeklyDistanceMeters: totalDistance,
      totalIdleSeconds: totalIdleMs ~/ 1000,
      overspeedCount: overspeedCount,
      hardBrakingCount: hardBrakingCount,
      mostActiveVehicle: mostActiveName,
      leastEfficientVehicle: leastEffName,
      topAlertCategory: overspeedCount > 0 ? 'تجاوز السرعة' : '--',
      weeklyTripCount: trips.length,
      fleetEfficiencyScore: efficiencyScore.toDouble(),
      dailyDistances: dailyDist.values.toList(),
      dailyLabels: dailyDist.keys.toList(),
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
}
