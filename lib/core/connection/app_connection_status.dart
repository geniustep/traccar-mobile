/// Represents the overall app-to-backend connection health.
///
/// This is independent of WebSocket / live sync — an app can be [online]
/// even when the live channel is degraded or disconnected.
enum AppConnectionStatus {
  /// Initial state: checking connectivity + backend reachability.
  checking,

  /// Backend is reachable and the session is valid.
  online,

  /// No internet connectivity on the device.
  offline,

  /// Internet exists but the backend does not respond (5xx / timeout).
  serverUnavailable,

  /// Backend responded with 401 — session or token expired.
  unauthorized,

  /// Catch-all for unexpected failures.
  error;

  bool get isOnline => this == online;

  bool get isOffline => this == offline;
}

/// Represents the state of the real-time data channel (WebSocket / polling).
///
/// Completely separate from [AppConnectionStatus]: the app can be [online]
/// while the live channel is [degraded] or [disconnected].
enum LiveSyncStatus {
  /// No live channel has been started yet.
  idle,

  /// WebSocket (or polling) is actively receiving data.
  connected,

  /// The live channel was previously connected, dropped, and a reconnect
  /// attempt is in progress right now.
  reconnecting,

  /// The app can reach the backend, but the live channel is slow or unstable
  /// (e.g. no live event for > 45 s while WebSocket reports connected).
  degraded,

  /// The live channel is not running. This does **not** imply the app is
  /// offline — REST calls may still succeed.
  disconnected;

  bool get isHealthy => this == connected;
}
