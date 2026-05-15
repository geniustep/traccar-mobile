class StorageKeys {
  StorageKeys._();

  // ── Traccar Basic-Auth credentials (stored encrypted) ─────────────────────
  static const String traccarEmail    = 'traccar_email';
  static const String traccarPassword = 'traccar_password';
  static const String traccarUserId   = 'traccar_user_id';
  static const String traccarJsessionId = 'traccar_jsession_id';

  // ── Legacy token keys (kept for backward compatibility) ───────────────────
  static const String accessToken  = 'elmo_access_token';
  static const String refreshToken = 'elmo_refresh_token';
  static const String userId       = 'elmo_user_id';

  // ── Shared preferences ────────────────────────────────────────────────────
  // Route-intel optional keys: RouteIntelligenceLocalPreferenceKeys (`elmo.local.route.*`).
  static const String isDarkMode           = 'is_dark_mode';
  static const String language             = 'language';
  static const String fcmToken             = 'fcm_token';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String lastSyncTimestamp    = 'last_sync_timestamp';
  static const String onboardingComplete   = 'onboarding_complete';
  static const String userJson             = 'user_json';
}
