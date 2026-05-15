import '../../../../core/network/traccar_client.dart';
import '../models/alert_model.dart';

/// Data source for the Backend `/alerts/` API.
///
/// This replaces the old Traccar `/reports/events` source.
/// All read/unread state is now owned by the Backend.
class AlertsRemoteDataSource {
  const AlertsRemoteDataSource(this._client);

  final TraccarClient _client;

  // ── Main Backend API ───────────────────────────────────────────────────────

  /// [GET /alerts/] — paginated list filtered by status.
  ///
  /// [status]: 'all' | 'read' | 'unread'
  Future<List<AlertModel>> getAlerts({
    String status = 'all',
    int limit = 50,
    int offset = 0,
    int? deviceId,
    String? type,
    String? severity,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != 'all') query['status'] = status;
    if (deviceId != null) query['deviceId'] = deviceId;
    if (type != null) query['type'] = type;
    if (severity != null) query['severity'] = severity;
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();

    final result = await _client.get<List<AlertModel>>(
      '/alerts/',
      query: query,
      fromJson: (json) {
        final list = _extractList(json);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AlertModel.fromBackendJson(e))
            .toList();
      },
    );

    return result.getOrThrow();
  }

  /// [GET /alerts/unread-count] — returns the server-side unread count.
  Future<int> getUnreadCount() async {
    final result = await _client.get<int>(
      '/alerts/unread-count',
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return (json['count'] as num?)?.toInt() ??
              (json['unreadCount'] as num?)?.toInt() ??
              0;
        }
        return (json as num?)?.toInt() ?? 0;
      },
    );
    return result.getOrThrow();
  }

  /// [GET /alerts/:id] — fetch a single alert by backend ID.
  Future<AlertModel> getAlertById(int id) async {
    final result = await _client.get<AlertModel>(
      '/alerts/$id',
      fromJson: (json) =>
          AlertModel.fromBackendJson(json as Map<String, dynamic>),
    );
    return result.getOrThrow();
  }

  /// [PATCH /alerts/:id/read] — marks a single alert as read on the backend.
  Future<void> markAlertRead(int id) async {
    final result = await _client.patch<dynamic>('/alerts/$id/read');
    result.getOrThrow();
  }

  /// [PATCH /alerts/read-all] — marks all (or those before [before]) as read.
  Future<void> markAllAlertsRead({DateTime? before}) async {
    final data = before != null
        ? <String, dynamic>{'before': before.toUtc().toIso8601String()}
        : null;
    final result = await _client.patch<dynamic>('/alerts/read-all', data: data);
    result.getOrThrow();
  }

  // ── Backward-compat thin wrappers ──────────────────────────────────────────

  /// Delegates to [getAlerts] for backward compatibility.
  Future<List<AlertModel>> getSmartAlerts() => getAlerts(limit: 30);

  /// Delegates to [getAlerts] filtered by deviceId.
  Future<List<AlertModel>> getVehicleAlerts(String vehicleId) async {
    final id = int.tryParse(vehicleId);
    if (id == null) return [];
    return getAlerts(deviceId: id);
  }

  /// Legacy no-op kept for backward compatibility.
  /// Use [markAlertRead] / [markAllAlertsRead] for new code.
  Future<void> markAsRead(String alertId) async {
    final id = int.tryParse(alertId);
    if (id != null) await markAlertRead(id);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Handles both array responses `[...]` and wrapped responses `{data: [...]}`.
  static List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['alerts'] ?? json['items'];
      if (data is List) return data;
    }
    return const [];
  }
}
