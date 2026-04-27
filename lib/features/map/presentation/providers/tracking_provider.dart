import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../vehicles/data/datasources/vehicle_remote_datasource.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../data/datasources/route_datasource.dart';
import '../../../../core/socket/socket_provider.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final routeDataSourceProvider = Provider<RouteDataSource>((ref) {
  return RouteDataSource(ref.read(traccarClientProvider));
});

/// REST-loaded base vehicle data (full metadata: name, plate, type, etc.).
/// Used as the foundation for the live vehicle view; position is overridden
/// by socket data when available.
final _baseVehicleProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  final ds = VehicleRemoteDataSource(ref.read(traccarClientProvider));
  final model = await ds.getVehicle(id);
  return model.toEntity();
});

/// Live vehicle data — merges REST metadata with real-time WebSocket position.
///
/// Strategy:
/// 1. Load full vehicle info once via REST ([_baseVehicleProvider]).
/// 2. Whenever the socket delivers a newer position for this device, apply it
///    via [VehicleEntity.copyWith] — no additional REST round-trip needed.
final liveVehicleProvider =
    Provider.autoDispose.family<AsyncValue<VehicleEntity>, String>((ref, id) {
  final base = ref.watch(_baseVehicleProvider(id));

  return base.whenData((vehicle) {
    final deviceId = int.tryParse(id);
    if (deviceId == null) return vehicle;

    final livePos = ref.watch(livePositionsProvider)[deviceId];
    if (livePos == null) return vehicle;

    final speedKmh = livePos.speed * 1.852;
    final status = speedKmh > 2.0
        ? 'moving'
        : (livePos.ignitionOn ? 'idle' : 'stopped');

    return vehicle.copyWith(
      latitude: livePos.latitude,
      longitude: livePos.longitude,
      speed: speedKmh,
      status: status,
      lastUpdate: livePos.fixTime,
      ignition: livePos.ignitionOn,
      batteryVoltage: livePos.batteryVoltage,
      fuelLevel: livePos.fuelLevel,
    );
  });
});

/// Today's route points for a vehicle as LatLng list (for polyline).
final todayRouteProvider =
    FutureProvider.autoDispose.family<List<LatLng>, String>((ref, id) async {
  final ds = ref.read(routeDataSourceProvider);
  final points = await ds.getRoute(id);
  return points.map((p) => p.position).toList();
});

/// Full route points with metadata (speed, time, etc.).
final todayRouteDetailProvider =
    FutureProvider.autoDispose.family<List<RoutePoint>, String>(
        (ref, id) async {
  final ds = ref.read(routeDataSourceProvider);
  return ds.getRoute(id);
});
