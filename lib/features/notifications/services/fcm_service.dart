import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_log_store.dart';
import '../../../core/logging/app_logger.dart';

/// Handles Firebase Cloud Messaging: permission, token, and message routing.
///
/// Responsibilities (only):
///   - Request notification permission.
///   - Obtain and refresh the FCM token, forwarding it via [onTokenObtained].
///   - Route foreground / background / terminated message data to callers.
///
/// Does NOT:
///   - Store read/unread state (backend owns that).
///   - Show UI alerts directly.
///   - Interact with Firebase beyond messaging.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Initializes FCM once per session (after successful login).
  ///
  /// [onTokenObtained] — send token to backend; called on first token and
  ///   on every refresh. Must not throw (errors are caught and logged).
  /// [onMessage] — foreground message data payload.
  /// [onMessageOpenedApp] — user tapped notification while app was in BG /
  ///   terminated state; also handles [getInitialMessage].
  Future<void> initialize({
    required Future<void> Function(String token) onTokenObtained,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onMessageOpenedApp,
  }) async {
    if (_initialized) {
      AppLogger.fcm('Already initialized — skipping duplicate call');
      return;
    }
    _initialized = true;
    AppLogger.fcm('Initializing…');

    final messaging = FirebaseMessaging.instance;

    // ── 1. Request permission ─────────────────────────────────────────────────
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      AppLogger.fcm('Permission status: ${settings.authorizationStatus}');
      DebugLogStore.instance.fcmPermissionStatus =
          settings.authorizationStatus.name;
    } catch (e) {
      AppLogger.fcmError('requestPermission error (continuing): $e');
      DebugLogStore.instance.fcmPermissionStatus = 'error';
    }

    // ── 2. Obtain token ───────────────────────────────────────────────────────
    String? token;
    try {
      token = await messaging.getToken();
    } catch (e) {
      AppLogger.fcmError('getToken error: $e');
    }

    if (token != null) {
      _logMaskedToken('Token obtained', token);
      try {
        await onTokenObtained(token);
        AppLogger.fcm('Token registered with backend OK');
      } catch (e) {
        AppLogger.fcmError('Failed to register token with backend: $e');
      }
    } else {
      AppLogger.fcm('Warning: FCM token is null (emulator / no Play Services?)');
    }

    // ── 3. Token refresh ──────────────────────────────────────────────────────
    _subscriptions.add(
      messaging.onTokenRefresh.listen((newToken) {
        _logMaskedToken('Token refreshed', newToken);
        onTokenObtained(newToken).catchError(
          (Object e) =>
              AppLogger.fcmError('Token refresh — backend register failed: $e'),
        );
      }),
    );

    // ── 4. Foreground messages ────────────────────────────────────────────────
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        AppLogger.fcm(
          'Message received: type=${message.data['type'] ?? '?'} '
          'alertId=${message.data['alertId'] ?? '-'}',
        );
        onMessage(message.data);
      }),
    );

    // ── 5. Background → foreground (notification tap) ─────────────────────────
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.fcm(
          'App opened from notification (background): '
          'alertId=${message.data['alertId'] ?? '-'}',
        );
        onMessageOpenedApp(message.data);
      }),
    );

    // ── 6. Terminated → foreground (initial message) ─────────────────────────
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      AppLogger.fcm(
        'App launched from notification (terminated): '
        'alertId=${initial.data['alertId'] ?? '-'}',
      );
      onMessageOpenedApp(initial.data);
    }

    AppLogger.fcm('Initialization complete');
  }

  /// Call on logout: cancels all listeners and resets the guard so FCM can be
  /// re-initialized after the next login.
  void reset() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
    AppLogger.fcm('Service reset (logout)');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static void _logMaskedToken(String label, String token) {
    if (!kDebugMode) return;
    final masked = token.length > 16
        ? '${token.substring(0, 10)}...${token.substring(token.length - 6)}'
        : '***';
    AppLogger.fcm('$label: $masked');
  }
}
