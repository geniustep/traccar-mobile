class AppConstants {
  AppConstants._();

  static const String appName = 'ELMO';
  static const String appVersion = '1.0.0';

  static const Duration mapRefreshInterval = Duration(seconds: 15);
  static const Duration dashboardRefreshInterval = Duration(seconds: 30);
  static const Duration tokenExpiryBuffer = Duration(minutes: 5);

  static const int maxRecentAlerts = 5;
  static const int defaultPageSize = 20;
  static const double defaultMapZoom = 12.0;
  static const double clusteringRadius = 60.0;

  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
}
