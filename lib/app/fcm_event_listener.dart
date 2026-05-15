import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/notifications/services/fcm_sync_provider.dart';

/// Handles navigation triggered by FCM push notifications.
///
/// Two entry points:
///   1. App in background → user taps notification → [onMessageOpenedApp].
///   2. App terminated → user taps notification → [getInitialMessage].
///
/// In both cases, [fcmAuthSyncProvider] stores the alertId in
/// [pendingNotificationAlertIdProvider]. This widget watches that provider
/// and navigates to `/alerts/:id` once:
///   - auth is fully ready (isAuthenticated && !isLoading), AND
///   - a pending alertId is present.
///
/// If auth is not yet ready (cold start), the listener on [authProvider]
/// fires once login completes and retries the navigation.
class FcmEventListener extends ConsumerStatefulWidget {
  const FcmEventListener({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<FcmEventListener> createState() => _FcmEventListenerState();
}

class _FcmEventListenerState extends ConsumerState<FcmEventListener> {
  void _navigateToAlert(String alertId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingNotificationAlertIdProvider.notifier).state = null;
      context.go('/alerts/$alertId');
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Case 1: pending alertId arrives while app is already running ──────────
    ref.listen<String?>(pendingNotificationAlertIdProvider, (_, alertId) {
      if (alertId == null) return;
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated || auth.isLoading) return;
      _navigateToAlert(alertId);
    });

    // ── Case 2: auth becomes ready after cold-start notification tap ──────────
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.isAuthenticated || next.isLoading) return;
      // Only fire once when auth transitions from not-ready to ready.
      if (prev != null && prev.isAuthenticated) return;

      final alertId = ref.read(pendingNotificationAlertIdProvider);
      if (alertId == null) return;
      _navigateToAlert(alertId);
    });

    return widget.child ?? const SizedBox.shrink();
  }
}
