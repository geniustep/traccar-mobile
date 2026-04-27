import '../api/api_config.dart';

/// Legacy shim — delegates to [ApiConfig] so that both old and new code
/// share one source of truth: [ApiEnvironment] / [EnvironmentConfig].
///
/// All new code should use [ApiConfig] directly.
/// This class is retained only for backward compatibility until all callers
/// have been migrated.
@Deprecated('Use ApiConfig directly. This class will be removed.')
class AppConfig {
  const AppConfig._();

  static String get baseUrl => ApiConfig.baseUrl;
  static String get socketUrl => ApiConfig.socketUrl;
  static String get googleMapsKey => ApiConfig.googleMapsKey;
  static Duration get connectTimeout => ApiConfig.connectTimeout;
  static Duration get receiveTimeout => ApiConfig.receiveTimeout;

  /// Kept for compatibility with [DioClient] constructor.
  static AppConfig get current => const AppConfig._();
}
