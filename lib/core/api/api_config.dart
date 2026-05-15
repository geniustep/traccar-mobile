import 'api_environment.dart';

/// Central API configuration built from the current environment.
class ApiConfig {
  ApiConfig._();

  static EnvironmentConfig get _env => ApiEnvironment.config;

  // ── Base URLs ─────────────────────────────────────────────────────────────

  /// Traccar REST base: direct Traccar e.g. `https://host/api`, or
  /// `https://api.elmogps.com` (no `/api` segment — nginx rewrites to `/api/...` upstream).
  static String get baseUrl => _env.traccarBaseUrl;

  /// WebSocket URL built safely from the configured socket URL.
  /// Guarantees `wss://` for HTTPS and never includes `:0`.
  static String get socketUrl {
    final uri = buildSocketUri(
      Uri.parse(_env.traccarBaseUrl),
      configuredSocketUrl: _env.traccarSocketUrl,
    );
    return uri.toString();
  }

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

  // ── WebSocket URI builder ─────────────────────────────────────────────────

  /// Builds a safe WebSocket [Uri] that:
  /// - Uses `wss` when the API base is `https`, `ws` for `http`.
  /// - Never includes port `:0` (omits port when null, 0, or default 443/80).
  /// - Appends an optional `?token=` query parameter.
  ///
  /// If [configuredSocketUrl] is provided and already valid, it is used as the
  /// base and only sanitized for port. Otherwise the URI is derived from
  /// [apiBaseUri] + [path].
  static Uri buildSocketUri(
    Uri apiBaseUri, {
    String? configuredSocketUrl,
    String path = '/socket',
    String? token,
  }) {
    final Uri source;
    if (configuredSocketUrl != null && configuredSocketUrl.isNotEmpty) {
      source = Uri.parse(configuredSocketUrl);
    } else {
      source = apiBaseUri;
    }

    final String scheme;
    if (source.scheme == 'wss' || source.scheme == 'ws') {
      scheme = source.scheme;
    } else {
      scheme = source.scheme == 'https' ? 'wss' : 'ws';
    }

    final effectivePath =
        (source.scheme == 'wss' || source.scheme == 'ws')
            ? source.path
            : path;

    final bool hasRealPort = source.hasPort &&
        source.port != 0 &&
        !_isDefaultPort(scheme, source.port);

    return Uri(
      scheme: scheme,
      host: source.host,
      port: hasRealPort ? source.port : null,
      path: effectivePath.isEmpty ? path : effectivePath,
      queryParameters: token != null ? {'token': token} : null,
    );
  }

  static bool _isDefaultPort(String scheme, int port) {
    if ((scheme == 'wss' || scheme == 'https') && port == 443) return true;
    if ((scheme == 'ws' || scheme == 'http') && port == 80) return true;
    return false;
  }
}
