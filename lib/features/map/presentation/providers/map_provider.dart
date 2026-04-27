import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../../../core/socket/socket_provider.dart';

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
    if (livePositions.isEmpty) return vehicles;

    return vehicles.map((v) {
      final deviceId = int.tryParse(v.id);
      if (deviceId == null) return v;

      final pos = livePositions[deviceId];
      if (pos == null) return v;

      final speedKmh = pos.speed * 1.852;
      final status = speedKmh > 2.0
          ? 'moving'
          : (pos.ignitionOn ? 'idle' : 'stopped');

      return v.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speed: speedKmh,
        status: status,
        lastUpdate: pos.fixTime,
        ignition: pos.ignitionOn,
        batteryVoltage: pos.batteryVoltage,
        fuelLevel: pos.fuelLevel,
      );
    }).toList();
  });
});

// Selected vehicle ID on map (for bottom sheet popup)
final selectedMapVehicleProvider =
    StateProvider.autoDispose<String?>((ref) => null);
