import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/debug_log_store.dart';
import '../../../core/logging/app_logger.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/alerts/presentation/providers/alerts_provider.dart';
import '../presentation/providers/notifications_provider.dart';
import 'fcm_service.dart';

// ── Pending navigation ─────────────────────────────────────────────────────────

/// Stores an alertId that arrived via FCM while the app was in the background
/// or terminated. [FcmEventListener] watches this and navigates to the detail
/// screen once auth is ready. Set back to null after navigation.
final pendingNotificationAlertIdProvider = StateProvider<String?>((ref) => null);

// ── Auth-bound FCM lifecycle ───────────────────────────────────────────────────

/// Initialises [FcmService] after login and resets it on logout.
///
/// On foreground message:
///   - Delegates to [NotificationsNotifier.addFcmEvent] which refreshes
///     [alertsProvider] from the Backend (single entry, no duplicate refresh).
///   - Does NOT create a notification from FCM data directly.
///
/// On notification tap (background / terminated):
///   - Stores `alertId` in [pendingNotificationAlertIdProvider].
///   - [FcmEventListener] handles the navigation.
///
/// Watch this from the app root (e.g. [ElmoApp.build]) so it is always active.
final fcmAuthSyncProvider = Provider<void>((ref) {
  AppLogger.fcm('Auth sync: watching auth state');

  void syncToAuth(AuthState state) {
    AppLogger.fcm(
      'Auth sync: isAuthenticated=${state.isAuthenticated} '
      'isLoading=${state.isLoading}',
    );

    if (state.isAuthenticated && !state.isLoading) {
      AppLogger.fcm('Auth ready — starting FCM');
      FcmService.instance.initialize(
        onTokenObtained: (token) async {
          AppLogger.fcm('Registering push token with backend…');
          try {
            await ref
                .read(notificationsRepositoryProvider)
                .registerFcmToken(token);
            DebugLogStore.instance.fcmTokenRegistered = true;
          } catch (e, st) {
            AppLogger.fcmError('registerFcmToken failed: $e');
            AppLogger.error('FCM', 'registerFcmToken', e, st);
          }
        },
        onMessage: (data) {
          final type = data['type'] as String?;
          final alertId = data['alertId'] as String?;
          DebugLogStore.instance
            ..fcmLastMessageType = type
            ..fcmLastAlertId = alertId;
          ref.read(notificationsProvider.notifier).addFcmEvent(data);
        },
        onMessageOpenedApp: (data) {
          final alertId = data['alertId'] as String?;
          if (alertId != null && alertId.isNotEmpty) {
            AppLogger.fcm('Notification tap → pending alertId=$alertId');
            DebugLogStore.instance.fcmLastAlertId = alertId;
            ref.read(pendingNotificationAlertIdProvider.notifier).state =
                alertId;
          }
        },
      );

      ref.read(alertsProvider.notifier).load();
      ref.read(notificationsProvider.notifier).load();
    } else if (!state.isAuthenticated && !state.isLoading) {
      FcmService.instance.reset();
      if (ref.exists(alertsProvider)) {
        ref.read(alertsProvider.notifier).resetOnLogout();
      }
      if (ref.exists(notificationsProvider)) {
        ref.read(notificationsProvider.notifier).resetOnLogout();
      }
      ref.read(pendingNotificationAlertIdProvider.notifier).state = null;
      AppLogger.fcm('Logout — FCM / alerts state cleared (no API reload)');
    }
  }

  ref.listen<AuthState>(authProvider, (_, next) => syncToAuth(next));
  syncToAuth(ref.read(authProvider));
});
