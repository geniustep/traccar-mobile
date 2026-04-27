/// Traccar deployment environments.
/// Switch via: flutter run --dart-define=ENV=production
enum Environment { development, staging, production }

class ApiEnvironment {
  ApiEnvironment._();

  static Environment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return switch (env) {
      'production' => Environment.production,
      'staging' => Environment.staging,
      _ => Environment.development,
    };
  }

  static bool get isDevelopment => current == Environment.development;
  static bool get isProduction => current == Environment.production;

  static EnvironmentConfig get config => switch (current) {
        Environment.production => EnvironmentConfig.production,
        Environment.staging => EnvironmentConfig.staging,
        Environment.development => EnvironmentConfig.development,
      };
}

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.name,
    required this.traccarBaseUrl,
    required this.traccarSocketUrl,
    required this.googleMapsKey,
    this.enableLogging = false,
    this.connectTimeoutMs = 15000,
    this.receiveTimeoutMs = 30000,
    this.socketPingIntervalSeconds = 25,
    this.socketReconnectDelaySeconds = 5,
    this.maxSocketReconnectAttempts = 10,
  });

  final String name;
  final String traccarBaseUrl;
  final String traccarSocketUrl;
  final String googleMapsKey;
  final bool enableLogging;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int socketPingIntervalSeconds;
  final int socketReconnectDelaySeconds;
  final int maxSocketReconnectAttempts;

  static const EnvironmentConfig development = EnvironmentConfig(
    name: 'Development',
    // Android emulator → 10.0.2.2 = your PC's localhost
    // iOS simulator   → 127.0.0.1
    // Physical device → your PC's LAN IP (e.g. 192.168.1.x)
    // Traccar default port: 8082
    traccarBaseUrl: 'https://api.elmogps.com',
    traccarSocketUrl: 'wss://api.elmogps.com/socket',
    googleMapsKey: '',
    enableLogging: true,
    connectTimeoutMs: 30000,
    receiveTimeoutMs: 60000,
  );

  // api.elmogps.com (nginx 20-api.conf): public URLs have NO /api prefix; nginx
  // rewrites e.g. /devices → Traccar /api/devices. Do not use
  // https://.../api/devices in the client or the upstream becomes /api/api/... .
  // WebSocket: wss://api.elmogps.com/socket → /api/socket on Traccar.
  // Alternative full Traccar host: wss://traccar.elmogps.com/api/socket
  static const EnvironmentConfig staging = EnvironmentConfig(
    name: 'Staging',
    traccarBaseUrl: 'https://api.elmogps.com',
    traccarSocketUrl: 'wss://api.elmogps.com/socket',
    googleMapsKey: '',
    enableLogging: true,
  );

  static const EnvironmentConfig production = EnvironmentConfig(
    name: 'Production',
    traccarBaseUrl: 'https://api.elmogps.com',
    traccarSocketUrl: 'wss://api.elmogps.com/socket',
    googleMapsKey: '',
    enableLogging: false,
  );
}
