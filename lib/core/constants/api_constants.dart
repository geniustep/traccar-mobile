class ApiConstants {
  ApiConstants._();

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardInsights = '/dashboard/insights';

  // Vehicles
  static const String vehicles = '/vehicles';
  static String vehicleById(String id) => '/vehicles/$id';
  static String vehicleLive(String id) => '/vehicles/$id/live';
  static String vehicleTrips(String id) => '/vehicles/$id/trips';
  static String vehicleAlerts(String id) => '/vehicles/$id/alerts';

  // Trips
  static const String trips = '/trips';
  static String tripById(String id) => '/trips/$id';

  // Alerts
  static const String alerts = '/alerts';
  static const String smartAlerts = '/alerts/smart';
  static String alertById(String id) => '/alerts/$id';

  // Analytics
  static const String analyticsWeekly = '/analytics/weekly';
  static const String analyticsMonthly = '/analytics/monthly';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllRead = '/notifications/read-all';

  // Settings
  static const String settings = '/settings';
  static const String updateProfile = '/settings/profile';
  static const String updateNotifications = '/settings/notifications';

  // FCM
  static const String registerFcmToken = '/devices/fcm';
}
