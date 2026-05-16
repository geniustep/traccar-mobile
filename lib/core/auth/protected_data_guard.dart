import '../../features/auth/presentation/providers/auth_provider.dart';
import '../logging/app_logger.dart';

/// Returns true when protected fleet APIs (alerts, devices, notifications) may run.
bool canLoadProtectedData(AuthState auth) =>
    auth.isAuthenticated && !auth.isLoading;

/// Debug log when a protected load is skipped (no HTTP).
void logSkippedProtectedLoad(String tag) {
  AppLogger.api('[$tag] Skipped load — unauthenticated');
}
