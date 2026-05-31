import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../vehicles/data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/route_intelligence_thresholds_write_repository_impl.dart';
import '../../domain/repositories/route_intelligence_thresholds_write_repository.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import 'route_intelligence_thresholds_provider.dart';
import 'tracking_provider.dart';

/// Wiring for [RouteIntelligenceThresholdsWriteRepository] (Phase 6J — vehicle only).
final routeIntelligenceThresholdsWriteRepositoryProvider =
    Provider<RouteIntelligenceThresholdsWriteRepository>((ref) {
  return RouteIntelligenceThresholdsWriteRepositoryImpl(
    VehicleRemoteDataSource(
      ref.read(traccarClientProvider),
      ref.read(fleetBaseDataGateProvider),
    ),
  );
});

/// After a successful [RouteIntelligenceThresholdsWriteRepository] vehicle save/clear,
/// invalidate vehicle lists, live REST metadata, and Route Intelligence resolution
/// so UI picks up fresh `device.attributes`.
///
/// Call from controllers / Phase 6K UI after `saveVehicleThresholds` / `clearVehicleThresholds`
/// completes without error. Does not run network itself.
void invalidateAfterVehicleRouteIntelCentralWrite(
  WidgetRef ref,
  String vehicleId,
) {
  if (vehicleId.isEmpty) return;
  ref.invalidate(vehiclesListProvider);
  invalidateVehicleLiveMetadata(ref, vehicleId);
  ref.invalidate(routeIntelligenceThresholdsForVehicleProvider(vehicleId));
  ref.invalidate(routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId));
}
