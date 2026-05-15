import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_localizations.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import '../features/vehicles/presentation/screens/vehicle_comparison_screen.dart';
import '../features/vehicles/presentation/comparison/vehicle_comparison_route_args.dart';
import '../features/vehicles/presentation/replay_multi/multi_vehicle_replay_route_args.dart';
import '../features/vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart';
import '../features/map/presentation/screens/live_map_screen.dart';
import '../features/map/presentation/screens/vehicle_tracking_screen.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/alerts/presentation/screens/alert_detail_screen.dart';
import '../features/trips/presentation/screens/trips_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/commands/presentation/screens/device_commands_screen.dart';
import '../features/commands/presentation/screens/command_logs_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/reports/presentation/screens/route_report_map_screen.dart';
import '../features/reports/presentation/screens/replay_report_screen.dart';
import '../features/reports/presentation/screens/charts_report_screen.dart';
import '../features/reports/presentation/screens/trip_detail_map_screen.dart';
import '../features/reports/presentation/providers/reports_providers.dart';
import '../features/geofences/presentation/screens/geofence_details_screen.dart';
import '../features/geofences/presentation/screens/geofence_editor_screen.dart';
import '../features/geofences/presentation/screens/geofences_screen.dart';
import '../features/drivers/presentation/screens/drivers_screen.dart';
import '../features/drivers/presentation/screens/driver_details_screen.dart';
import '../features/drivers/presentation/screens/driver_editor_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_editor_screen.dart';
import '../features/fleet_intelligence/presentation/screens/fleet_intelligence_dashboard_screen.dart';
import '../core/debug/debug_console_screen.dart';
import '../core/debug/navigation_logger.dart';
import 'main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final initialAuth = ref.read(authProvider);
  final authNotifier = ValueNotifier<bool>(initialAuth.isAuthenticated);

  ref.listen<AuthState>(authProvider, (prev, next) {
    if (!next.isLoading) {
      authNotifier.value = next.isAuthenticated;
    }
  });

  final router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      final isAuth = auth.isAuthenticated;
      final isLoginRoute = loc == '/login';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/debug-console',
        redirect: (context, state) {
          if (kReleaseMode) return '/settings';
          return null;
        },
        builder: (context, state) => const DebugConsoleScreen(),
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
            path: '/fleet-intelligence',
            builder: (context, state) =>
                const FleetIntelligenceDashboardScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => ReportsScreen(
              entryParams: state.extra is ReportsEntryParams
                  ? state.extra as ReportsEntryParams
                  : null,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Pushed routes (no shell)
      GoRoute(
        path: '/vehicles/replay-multi',
        builder: (context, state) {
          List<String> ids = const [];
          DateTime? date;
          final extra = state.extra;
          if (extra is MultiVehicleReplayRouteArgs) {
            ids = extra.vehicleIds;
            date = extra.date;
          } else if (extra is Map<String, dynamic>) {
            final raw = extra['vehicleIds'];
            if (raw is List) {
              ids = raw.map((e) => e.toString()).toList();
            }
            final d = extra['date'];
            if (d is DateTime) date = d;
          }
          return MultiVehicleReplayScreen(
            vehicleIds: ids,
            initialDate: date,
          );
        },
      ),
      GoRoute(
        path: '/vehicles/compare',
        builder: (context, state) {
          List<String> ids = const [];
          final extra = state.extra;
          if (extra is VehicleComparisonRouteArgs) {
            ids = extra.vehicleIds;
          } else if (extra is List<String>) {
            ids = extra;
          } else if (extra is Map<String, dynamic>) {
            final raw = extra['vehicleIds'];
            if (raw is List) {
              ids = raw.map((e) => e.toString()).toList();
            }
          }
          return VehicleComparisonScreen(initialVehicleIds: ids);
        },
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) => VehicleDetailScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/track',
        builder: (context, state) => VehicleTrackingScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/vehicles/:id/trip-map',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final params = extra['params'] as ReportFilterParams?;
          final vehicleName = extra['vehicleName'] as String? ?? '';
          final subtitle = extra['tripSubtitle'] as String? ?? '';
          if (params == null) {
            return VehicleTrackingScreen(vehicleId: state.pathParameters['id']!);
          }
          return TripDetailMapScreen(
            params: params,
            vehicleName: vehicleName,
            subtitleLine: subtitle,
          );
        },
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

      // ── Commands routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/vehicles/:id/commands',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final id = int.tryParse(state.pathParameters['id']!) ?? 0;
          final extra = state.extra;
          final name = (extra is Map<String, dynamic>)
              ? (extra['name'] as String? ?? l10n.vehicle)
              : l10n.vehicle;
          return DeviceCommandsScreen(deviceId: id, deviceName: name);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/commands/logs',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final id = int.tryParse(state.pathParameters['id']!) ?? 0;
          final extra = state.extra;
          final name = (extra is Map<String, dynamic>)
              ? (extra['name'] as String? ?? l10n.vehicle)
              : l10n.vehicle;
          return CommandLogsScreen(deviceId: id, deviceName: name);
        },
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

      // ── Geofences ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/geofences',
        builder: (context, state) => const GeofencesScreen(),
      ),
      GoRoute(
        path: '/geofences/:id/edit',
        builder: (context, state) => GeofenceEditorScreen(
          geofenceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/geofences/:id',
        builder: (context, state) => GeofenceDetailsScreen(
          geofenceId: state.pathParameters['id']!,
        ),
      ),

      // ── Fleet: drivers ────────────────────────────────────────────────────────
      GoRoute(
        path: '/drivers',
        builder: (context, state) => const DriversScreen(),
      ),
      GoRoute(
        path: '/drivers/new/edit',
        builder: (context, state) =>
            const DriverEditorScreen(driverId: 'new'),
      ),
      GoRoute(
        path: '/drivers/:id/edit',
        builder: (context, state) => DriverEditorScreen(
          driverId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/drivers/:id',
        builder: (context, state) => DriverDetailsScreen(
          driverId: state.pathParameters['id']!,
        ),
      ),

      // ── Fleet: maintenance ─────────────────────────────────────────────────────
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/maintenance/new/edit',
        builder: (context, state) =>
            const MaintenanceEditorScreen(recordId: 'new'),
      ),
      GoRoute(
        path: '/maintenance/:id/edit',
        builder: (context, state) => MaintenanceEditorScreen(
          recordId: state.pathParameters['id']!,
        ),
      ),

      // ── Reports sub-routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/reports/route-map',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final params = extra['params'] as ReportFilterParams?;
          final vehicleName = extra['vehicleName'] as String? ?? '';
          if (params == null) return const ReportsScreen();
          return RouteReportMapScreen(
            params: params,
            vehicleName: vehicleName,
          );
        },
      ),
      GoRoute(
        path: '/reports/replay',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final params = extra['params'] as ReportFilterParams?;
          final vehicleName = extra['vehicleName'] as String? ?? '';
          if (params == null) return const ReportsScreen();
          return ReplayReportScreen(
            params: params,
            vehicleName: vehicleName,
          );
        },
      ),
      GoRoute(
        path: '/reports/charts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final params = extra['params'] as ReportFilterParams?;
          final vehicleName = extra['vehicleName'] as String? ?? '';
          if (params == null) return const ReportsScreen();
          return ChartsReportScreen(
            params: params,
            vehicleName: vehicleName,
          );
        },
      ),
    ],
  );

  ElmoNavigationLogger.attach(router);
  return router;
});
