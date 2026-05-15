import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../dashboard/data/services/dashboard_alert_filter.dart';

/// Extra toggles for the live fleet map that should persist across rebuilds.
final liveMapMapTypeProvider = StateProvider<MapType>((ref) => MapType.normal);

/// Draw unread important alerts on the map when they include coordinates.
final liveMapShowAlertPinsProvider = StateProvider<bool>((ref) => false);

/// Optional today's GPS trace for the selected vehicle (extra API load).
final liveMapShowTodayRouteOverlayProvider = StateProvider<bool>((ref) => false);

/// Device IDs with at least one **unread** dashboard-important alert.
final mapUnreadImportantAlertVehicleIdsProvider = Provider<Set<String>>((ref) {
  final async = ref.watch(alertsProvider).alertsAsync;
  return async.whenOrNull(
        data: (alerts) => alerts
            .where(
              (a) =>
                  !a.isRead && DashboardAlertFilter.isImportantAlert(a),
            )
            .map((a) => a.vehicleId)
            .toSet(),
      ) ??
      const {};
});
