import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../../drivers/presentation/providers/drivers_providers.dart';
import '../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../data/datasources/fleet_intelligence_remote_datasource.dart';
import '../../domain/fleet_admin_snapshot.dart';
import '../../domain/fleet_dashboard_period.dart';
import '../../domain/services/fleet_admin_snapshot_builder.dart';

final fleetIntelligenceRemoteProvider =
    Provider<FleetIntelligenceRemoteDataSource>((ref) {
  return FleetIntelligenceRemoteDataSource(ref.read(traccarClientProvider));
});

/// الفترة المعروضة في لوحة ذكاء الأسطول.
final fleetDashboardPeriodProvider =
    StateProvider<FleetDashboardPeriod>((ref) => FleetDashboardPeriod.today);

final fleetAdminSnapshotProvider = FutureProvider.autoDispose
    .family<FleetAdminSnapshot, FleetDashboardPeriod>((ref, period) async {
  ref.keepAlive();
  final vehicles = await ref.watch(vehiclesListProvider.future);
  final drivers = await ref.watch(driversListProvider.future);
  final maintenance = await ref.watch(maintenanceListProvider.future);
  final ds = ref.read(fleetIntelligenceRemoteProvider);
  // Use the unified refresh timestamp to prevent millisecond-level
  // differences between providers within the same refresh cycle.
  final refreshNow = ref.read(dashboardRefreshNowProvider);
  final range = period.utcRangeAt(refreshNow);
  final ids =
      vehicles.map((v) => int.tryParse(v.id)).whereType<int>().toList();
  Object? err;
  var trips = <TripModel>[];
  var events = <Map<String, dynamic>>[];
  try {
    final raw = await ds.fetchTripsAndEvents(
      deviceIds: ids,
      fromUtc: range.$1,
      toUtc: range.$2,
    );
    trips = raw.trips;
    events = raw.events;
  } catch (e) {
    err = e;
  }
  return FleetAdminSnapshotBuilder.build(
    period: period,
    trips: trips,
    eventsRaw: events,
    drivers: drivers,
    vehicles: vehicles,
    maintenance: maintenance,
    tripsEventsError: err,
  );
});

int countActiveDrivers(
  List<DriverEntity> drivers,
  List<VehicleEntity> vehicles,
) {
  final onlineIds = <int>{};
  for (final v in vehicles) {
    final id = int.tryParse(v.id);
    if (id != null && !v.isOffline) onlineIds.add(id);
  }
  var n = 0;
  for (final d in drivers) {
    if (d.linkedDeviceIds.any(onlineIds.contains)) n++;
  }
  return n;
}
