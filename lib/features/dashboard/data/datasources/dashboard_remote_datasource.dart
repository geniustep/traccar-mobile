import '../../../../core/fleet/fleet_base_data_gate.dart';
import '../../../reports/data/fleet_reports_request_gate.dart';
import '../models/dashboard_summary_model.dart';
import '../models/insight_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._fleetReports, this._baseData);

  final FleetReportsRequestGate _fleetReports;
  final FleetBaseDataGate _baseData;

  void resetCoalescer() => _fleetReports.resetCache();

  Future<DashboardSummaryModel> getSummary({DateTime? refreshNow}) async {
    final now = refreshNow ?? DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);

    final baseResults = await Future.wait([
      _getDevices(),
      _getPositions(),
    ]);
    final devices = baseResults[0];
    final positions = baseResults[1];

    List<Map<String, dynamic>> trips = [];
    List<Map<String, dynamic>> events = [];

    if (devices.isNotEmpty) {
      final deviceIds = devices
          .map((d) => d['id'])
          .whereType<int>()
          .toList();

      final reportResults = await Future.wait([
        _fleetReports.fetchTripsRaw(
          deviceIds: deviceIds,
          fromUtc: todayStart,
          toUtc: now,
          trigger: 'dashboard_summary',
        ),
        _fleetReports.fetchEvents(
          deviceIds: deviceIds,
          fromUtc: todayStart,
          toUtc: now,
          trigger: 'dashboard_summary',
        ),
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

  Future<List<InsightModel>> getInsights({DateTime? refreshNow}) async {
    final now = refreshNow ?? DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);

    final devices = await _getDevices();
    if (devices.isEmpty) return [];

    final deviceIds = devices
        .map((d) => d['id'])
        .whereType<int>()
        .toList();
    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    final events = await _fleetReports.fetchEvents(
      deviceIds: deviceIds,
      fromUtc: todayStart,
      toUtc: now,
      trigger: 'dashboard_insights',
    );

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

  Future<List<Map<String, dynamic>>> _getDevices() => _baseData.fetchDevices();

  Future<List<Map<String, dynamic>>> _getPositions() =>
      _baseData.fetchPositions();

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
