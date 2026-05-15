import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';

/// Attaches a lightweight route observer to [GoRouter] (debug-only via [AppLogger]).
///
/// Logs one line per **distinct** path entered:
///   `[Navigation] Entered: /alerts`
///
/// Phase 5: Also updates DebugLogStore route history for Debug Console.
abstract final class ElmoNavigationLogger {
  static String? _lastPath;

  /// Attaches the logger to [router]. Call once after creating [GoRouter].
  static void attach(GoRouter router) {
    router.routerDelegate.addListener(() => _onRouteChange(router));
  }

  static void _onRouteChange(GoRouter router) {
    final path = router.routerDelegate.currentConfiguration.uri.path;

    if (path.isEmpty || path == _lastPath) return;

    _lastPath = path;
    AppLogger.navigation('Entered: $path');
  }
}
