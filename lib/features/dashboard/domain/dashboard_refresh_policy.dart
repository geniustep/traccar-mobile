import '../../../core/connection/app_connection_status.dart';

/// How aggressively the dashboard should refresh its REST data.
enum DashboardRefreshMode {
  /// Data is fresh enough — do nothing.
  none,

  /// Lightweight background refresh: fleet summary + unread alerts.
  /// No loading indicators, no chart/analytics refresh.
  silentLight,

  /// Refresh fleet summary, vehicle status, alerts, attention center.
  /// Skip heavy analytics/historical data.
  medium,

  /// Full refresh of everything including period snapshots.
  /// Used only for pull-to-refresh, first load, account change, etc.
  full,
}

/// Pure-logic policy that decides which refresh mode to use.
///
/// Callers provide the current context; this function returns the optimal
/// mode without side-effects — easy to test.
DashboardRefreshMode computeRefreshMode({
  required DateTime? lastRefreshAt,
  required bool hasCachedData,
  required bool isManualRefresh,
  required LiveSyncStatus liveStatus,
}) {
  if (isManualRefresh) return DashboardRefreshMode.full;
  if (!hasCachedData) return DashboardRefreshMode.full;
  if (lastRefreshAt == null) return DashboardRefreshMode.full;

  final age = DateTime.now().difference(lastRefreshAt);

  if (age.inSeconds < 30) return DashboardRefreshMode.none;

  if (age.inMinutes < 5) {
    if (liveStatus == LiveSyncStatus.connected) {
      return DashboardRefreshMode.silentLight;
    }
    return DashboardRefreshMode.silentLight;
  }

  return DashboardRefreshMode.medium;
}

/// Returns the mode to use when the app resumes from background.
DashboardRefreshMode computeBackgroundResumeMode({
  required Duration backgroundDuration,
  required bool hasCachedData,
}) {
  if (backgroundDuration.inSeconds < 30) return DashboardRefreshMode.none;
  if (!hasCachedData) return DashboardRefreshMode.full;
  if (backgroundDuration.inMinutes < 5) return DashboardRefreshMode.silentLight;
  if (backgroundDuration.inMinutes < 15) return DashboardRefreshMode.medium;
  return DashboardRefreshMode.full;
}
