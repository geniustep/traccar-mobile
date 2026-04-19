import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import '../features/map/presentation/screens/live_map_screen.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/alerts/presentation/screens/alert_detail_screen.dart';
import '../features/trips/presentation/screens/trips_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  ref.listen<AuthState>(authProvider, (prev, next) {
    if (!next.isLoading) {
      authNotifier.value = next.isAuthenticated;
    }
  });

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final isAuth = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/vehicles',
            builder: (context, state) => const VehiclesScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const LiveMapScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Pushed routes (no shell)
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) => VehicleDetailScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/trips',
        builder: (context, state) => TripsScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (context, state) => AlertDetailScreen(
          alertId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (context, state) => TripsScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
