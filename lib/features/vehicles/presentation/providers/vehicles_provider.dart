import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(
    VehicleRemoteDataSource(ref.read(dioClientProvider)),
  );
});

final vehiclesListProvider =
    FutureProvider.autoDispose<List<VehicleEntity>>((ref) async {
  return ref.read(vehicleRepositoryProvider).getVehicles();
});

final vehicleDetailProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  return ref.read(vehicleRepositoryProvider).getVehicle(id);
});

final vehicleLiveProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  return ref.read(vehicleRepositoryProvider).getVehicleLive(id);
});

// Search / filter state
class VehicleFilterState {
  const VehicleFilterState({
    this.query = '',
    this.statusFilter,
  });

  final String query;
  final String? statusFilter;

  VehicleFilterState copyWith({String? query, String? statusFilter, bool clearStatus = false}) {
    return VehicleFilterState(
      query: query ?? this.query,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

final vehicleFilterProvider =
    StateNotifierProvider.autoDispose<VehicleFilterNotifier, VehicleFilterState>(
  (ref) => VehicleFilterNotifier(),
);

class VehicleFilterNotifier extends StateNotifier<VehicleFilterState> {
  VehicleFilterNotifier() : super(const VehicleFilterState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setStatus(String? s) =>
      state = state.copyWith(statusFilter: s, clearStatus: s == null);
  void clear() => state = const VehicleFilterState();
}

final filteredVehiclesProvider =
    Provider.autoDispose<AsyncValue<List<VehicleEntity>>>((ref) {
  final vehicles = ref.watch(vehiclesListProvider);
  final filter = ref.watch(vehicleFilterProvider);

  return vehicles.whenData((list) {
    return list.where((v) {
      final matchQuery = filter.query.isEmpty ||
          v.name.toLowerCase().contains(filter.query.toLowerCase()) ||
          v.plateNumber.toLowerCase().contains(filter.query.toLowerCase());
      final matchStatus = filter.statusFilter == null ||
          v.status == filter.statusFilter;
      return matchQuery && matchStatus;
    }).toList();
  });
});
