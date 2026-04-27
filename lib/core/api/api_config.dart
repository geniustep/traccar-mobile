import 'api_environment.dart';

/// Central API configuration built from the current environment.
class ApiConfig {
  ApiConfig._();

  static EnvironmentConfig get _env => ApiEnvironment.config;

  // ── Base URLs ─────────────────────────────────────────────────────────────

  /// Traccar REST base: direct Traccar e.g. `https://host/api`, or
  /// `https://api.elmogps.com` (no `/api` segment — nginx rewrites to `/api/...` upstream).
  static String get baseUrl => _env.traccarBaseUrl;

  /// WebSocket: e.g. `wss://api.elmogps.com/socket` or `ws://10.0.2.2:8082/api/socket` in dev.
  static String get socketUrl => _env.traccarSocketUrl;

  /// Google Maps API key
  static String get googleMapsKey => _env.googleMapsKey;

  // ── Timeouts ──────────────────────────────────────────────────────────────

  static Duration get connectTimeout =>
      Duration(milliseconds: _env.connectTimeoutMs);

  static Duration get receiveTimeout =>
      Duration(milliseconds: _env.receiveTimeoutMs);

  // ── Socket settings ───────────────────────────────────────────────────────

  static Duration get socketPingInterval =>
      Duration(seconds: _env.socketPingIntervalSeconds);

  static Duration get socketReconnectDelay =>
      Duration(seconds: _env.socketReconnectDelaySeconds);

  static int get maxSocketReconnectAttempts =>
      _env.maxSocketReconnectAttempts;

  // ── Flags ─────────────────────────────────────────────────────────────────

  static bool get loggingEnabled => _env.enableLogging;

  static String get environmentName => _env.name;

  // ── Fixed HTTP headers sent with every request ────────────────────────────

  static Map<String, String> get defaultHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
