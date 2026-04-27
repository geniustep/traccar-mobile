import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/socket/traccar_socket_service.dart';
import '../../core/socket/socket_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'core_providers.dart';

export '../../core/socket/socket_provider.dart';

// ── WebSocket service ─────────────────────────────────────────────────────────

/// Overrides the abstract [traccarSocketServiceProvider] with a concrete
/// instance that has access to [SecureStorageService].
///
/// Register this override in [main.dart]:
/// ```dart
/// ProviderContainer(
///   overrides: [
///     traccarSocketServiceProvider.overrideWith(
///       (ref) => ref.read(concreteSocketServiceProvider),
///     ),
///   ],
/// )
/// ```
final concreteSocketServiceProvider = Provider<TraccarSocketService>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  final svc = TraccarSocketService(storage: storage);
  ref.onDispose(svc.dispose);
  return svc;
});

// ── Auth-bound socket lifecycle ───────────────────────────────────────────────

/// Connects the WebSocket when the user is signed in (token in secure storage);
/// disconnects on logout. Watch this from the app root.
final socketAuthSyncProvider = Provider<void>((ref) {
  final svc = ref.watch(concreteSocketServiceProvider);
  void syncToAuth(AuthState state) {
    if (state.isAuthenticated && !state.isLoading) {
      // Ensure JSESSIONID (from Set-Cookie) before WS — required by some
      // Nginx+Traccar stacks; also covers upgrades from app versions that
      // did not store the cookie, or if parsing failed the first time.
      Future.microtask(() async {
        try {
          await ref.read(authRepositoryProvider).ensureTraccarSocketSession();
        } catch (_) {}
        await svc.connect();
      });
    } else if (!state.isAuthenticated && !state.isLoading) {
      svc.disconnect();
    }
  }

  ref.listen<AuthState>(authProvider, (_, next) => syncToAuth(next));
  syncToAuth(ref.read(authProvider));
  ref.onDispose(svc.disconnect);
});
