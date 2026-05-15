import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../core/map_camera_focus.dart';
import '../../core/vehicle_live_merger.dart';
import 'map_vehicle_filter.dart';

// ── Live-merged map vehicles ──────────────────────────────────────────────────

/// All vehicles for the map, with positions kept up-to-date by WebSocket.
///
/// Strategy:
/// - [vehiclesListProvider] loads all vehicles with full metadata via REST.
/// - [livePositionsProvider] streams real-time position updates via WebSocket.
/// - This provider merges both: REST metadata + latest socket position.
///
/// The UI only needs to watch this single provider — it automatically reacts
/// whenever either source changes.
final mapVehiclesProvider =
    Provider.autoDispose<AsyncValue<List<VehicleEntity>>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesListProvider);
  final livePositions = ref.watch(livePositionsProvider);

  return vehiclesAsync.whenData((vehicles) {
    return VehicleLiveMerger.mergeFleet(vehicles, livePositions);
  });
});

// Selected vehicle ID on map (for bottom sheet popup)
final selectedMapVehicleProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Set before navigating to `/map` to focus a vehicle after the screen mounts.
final pendingMapVehicleFocusProvider = StateProvider<String?>((ref) => null);

/// Camera focus/fit-bounds request consumed by [LiveMapScreen] after filter apply.
final pendingMapCameraFocusProvider =
    StateProvider<MapCameraFocusRequest?>((ref) => null);

/// In-memory visibility filter for the live map (not persisted).
final vehicleMapFilterProvider =
    StateProvider.autoDispose<VehicleMapFilterState>(
  (ref) => const VehicleMapFilterState(),
);

/// Fleet list after applying [vehicleMapFilterProvider] (raw merge unchanged).
final filteredMapVehiclesProvider =
    Provider.autoDispose<AsyncValue<List<VehicleEntity>>>((ref) {
  final vehiclesAsync = ref.watch(mapVehiclesProvider);
  final filter = ref.watch(vehicleMapFilterProvider);

  return vehiclesAsync.whenData(
    (vehicles) => applyVehicleMapFilter(vehicles, filter),
  );
});
