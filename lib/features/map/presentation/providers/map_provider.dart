import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';

final mapVehiclesProvider =
    FutureProvider.autoDispose<List<VehicleEntity>>((ref) async {
  return ref.read(vehicleRepositoryProvider).getVehicles();
});

// Selected vehicle ID on map (for bottom sheet popup)
final selectedMapVehicleProvider = StateProvider.autoDispose<String?>((ref) => null);

final mapAutoRefreshProvider = Provider.autoDispose<void>((ref) {
  // Wire up auto-refresh: call ref.invalidate(mapVehiclesProvider) on a timer
  // This is intentionally left for the app shell to trigger via a Timer
});
