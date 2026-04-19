class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.socketUrl,
    required this.googleMapsKey,
    this.connectTimeoutMs = 15000,
    this.receiveTimeoutMs = 30000,
  });

  final String baseUrl;
  final String socketUrl;
  final String googleMapsKey;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  static const AppConfig development = AppConfig(
    baseUrl: 'https://api-dev.elmofleet.com/api',
    socketUrl: 'wss://api-dev.elmofleet.com/ws',
    googleMapsKey: '',
  );

  static const AppConfig production = AppConfig(
    baseUrl: 'https://api.elmofleet.com/api',
    socketUrl: 'wss://api.elmofleet.com/ws',
    googleMapsKey: '',
  );

  // Switch between environments via compile-time flag:
  // flutter run --dart-define=ENV=production
  static AppConfig get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' ? production : development;
  }
}
