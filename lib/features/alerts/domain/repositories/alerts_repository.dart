import '../entities/alert.dart';

abstract interface class AlertsRepository {
  // ── Backend API (source of truth) ─────────────────────────────────────────

  /// Fetches paginated alerts from `GET /alerts/`.
  /// [status]: 'all' | 'read' | 'unread'
  Future<List<AlertEntity>> getAlerts({
    String status,
    int limit,
    int offset,
    int? deviceId,
  });

  /// Returns the server-side unread count from `GET /alerts/unread-count`.
  Future<int> getUnreadCount();

  /// Fetches a single alert from `GET /alerts/:id`.
  Future<AlertEntity> getAlertById(int id);

  /// Marks one alert as read via `PATCH /alerts/:id/read`.
  Future<void> markAlertRead(int id);

  /// Marks all alerts as read via `PATCH /alerts/read-all`.
  Future<void> markAllAlertsRead({DateTime? before});

  // ── Kept for backward compatibility ───────────────────────────────────────

  /// [Deprecated] Use [getAlerts] with a deviceId filter instead.
  Future<List<AlertEntity>> getSmartAlerts();

  /// Vehicle-specific alerts (delegates to [getAlerts] with deviceId filter).
  Future<List<AlertEntity>> getVehicleAlerts(String vehicleId);

  /// Legacy string-id mark-read (parses id and calls [markAlertRead]).
  Future<void> markAsRead(String alertId);
}
