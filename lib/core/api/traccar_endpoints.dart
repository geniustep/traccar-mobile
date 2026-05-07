/// All Traccar REST API endpoints organised by domain.
/// Reference: https://www.traccar.org/api-reference/
class TraccarEndpoints {
  TraccarEndpoints._();

  // ── Session (Auth) ────────────────────────────────────────────────────────

  /// POST — create session (login with email + password form-data)
  static const String sessionCreate = '/session';

  /// DELETE — destroy current session (logout)
  static const String sessionDelete = '/session';

  /// GET — get current session info
  static const String sessionGet = '/session';

  // ── Users ─────────────────────────────────────────────────────────────────

  /// GET /users — list users (admin)
  static const String users = '/users';

  /// POST /users — create user
  static const String userCreate = '/users';

  /// GET /users/{id}
  static String userById(int id) => '/users/$id';

  /// PUT /users/{id}
  static String userUpdate(int id) => '/users/$id';

  /// DELETE /users/{id}
  static String userDelete(int id) => '/users/$id';

  // ── Devices ───────────────────────────────────────────────────────────────

  /// GET /devices — list devices (optionally filtered)
  static const String devices = '/devices';

  /// POST /devices — register device
  static const String deviceCreate = '/devices';

  /// GET /devices/{id}
  static String deviceById(int id) => '/devices/$id';

  /// PUT /devices/{id}
  static String deviceUpdate(int id) => '/devices/$id';

  /// DELETE /devices/{id}
  static String deviceDelete(int id) => '/devices/$id';

  /// GET /devices/count — total count
  static const String deviceCount = '/devices/count';

  /// PUT /devices/{id}/accumulator — reset accumulator
  static String deviceAccumulator(int id) => '/devices/$id/accumulator';

  // ── Positions ─────────────────────────────────────────────────────────────

  /// GET /positions — last known positions (can filter by deviceId, from, to)
  static const String positions = '/positions';

  // ── Events ────────────────────────────────────────────────────────────────

  /// GET /events/{id}
  static String eventById(int id) => '/events/$id';

  // ── Reports ───────────────────────────────────────────────────────────────

  /// GET /reports/route — route points between dates
  static const String reportRoute = '/reports/route';

  /// GET /reports/trips — trip summaries
  static const String reportTrips = '/reports/trips';

  /// GET /reports/stops — stop summaries
  static const String reportStops = '/reports/stops';

  /// GET /reports/summary — device summary over period
  static const String reportSummary = '/reports/summary';

  /// GET /reports/events — events list
  static const String reportEvents = '/reports/events';

  // ── Geofences ─────────────────────────────────────────────────────────────

  /// GET /geofences
  static const String geofences = '/geofences';

  /// POST /geofences
  static const String geofenceCreate = '/geofences';

  /// GET /geofences/{id}
  static String geofenceById(int id) => '/geofences/$id';

  /// PUT /geofences/{id}
  static String geofenceUpdate(int id) => '/geofences/$id';

  /// DELETE /geofences/{id}
  static String geofenceDelete(int id) => '/geofences/$id';

  // ── Notifications ─────────────────────────────────────────────────────────

  /// GET /notifications
  static const String notifications = '/notifications';

  /// POST /notifications
  static const String notificationCreate = '/notifications';

  /// GET /notifications/{id}
  static String notificationById(int id) => '/notifications/$id';

  /// PUT /notifications/{id}
  static String notificationUpdate(int id) => '/notifications/$id';

  /// DELETE /notifications/{id}
  static String notificationDelete(int id) => '/notifications/$id';

  /// GET /notifications/types — available notification types
  static const String notificationTypes = '/notifications/types';

  // ── Groups ────────────────────────────────────────────────────────────────

  /// GET /groups
  static const String groups = '/groups';

  /// POST /groups
  static const String groupCreate = '/groups';

  /// GET /groups/{id}
  static String groupById(int id) => '/groups/$id';

  /// PUT /groups/{id}
  static String groupUpdate(int id) => '/groups/$id';

  /// DELETE /groups/{id}
  static String groupDelete(int id) => '/groups/$id';

  // ── Attributes (computed) ─────────────────────────────────────────────────

  /// GET /attributes/computed
  static const String attributes = '/attributes/computed';

  /// POST /attributes/computed
  static const String attributeCreate = '/attributes/computed';

  /// GET /attributes/computed/{id}
  static String attributeById(int id) => '/attributes/computed/$id';

  /// PUT /attributes/computed/{id}
  static String attributeUpdate(int id) => '/attributes/computed/$id';

  /// DELETE /attributes/computed/{id}
  static String attributeDelete(int id) => '/attributes/computed/$id';

  // ── Drivers ───────────────────────────────────────────────────────────────

  /// GET /drivers
  static const String drivers = '/drivers';

  /// POST /drivers
  static const String driverCreate = '/drivers';

  /// GET /drivers/{id}
  static String driverById(int id) => '/drivers/$id';

  /// PUT /drivers/{id}
  static String driverUpdate(int id) => '/drivers/$id';

  /// DELETE /drivers/{id}
  static String driverDelete(int id) => '/drivers/$id';

  // ── Calendars ─────────────────────────────────────────────────────────────

  /// GET /calendars
  static const String calendars = '/calendars';

  // ── Commands ──────────────────────────────────────────────────────────────

  /// POST /commands/send — send command to device
  static const String commandSend = '/commands/send';

  /// GET /commands/types?deviceId=X — available command types for a device
  static const String commandTypes = '/commands/types';

  /// GET /commands — list saved commands (optionally by deviceId)
  static const String commands = '/commands';

  /// POST /commands — save a command
  static const String commandCreate = '/commands';

  /// GET /commands/{id}
  static String commandById(int id) => '/commands/$id';

  /// PUT /commands/{id}
  static String commandUpdate(int id) => '/commands/$id';

  /// DELETE /commands/{id}
  static String commandDelete(int id) => '/commands/$id';

  // ── Statistics ────────────────────────────────────────────────────────────

  /// GET /statistics — server statistics (admin)
  static const String statistics = '/statistics';

  // ── Server ────────────────────────────────────────────────────────────────

  /// GET /server — server info / preferences
  static const String server = '/server';

  /// PUT /server — update server preferences (admin)
  static const String serverUpdate = '/server';

  // ── Permissions ───────────────────────────────────────────────────────────

  /// POST /permissions — link entity to user
  static const String permissionCreate = '/permissions';

  /// DELETE /permissions — unlink entity from user
  static const String permissionDelete = '/permissions';
}
