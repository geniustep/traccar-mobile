import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/protected_data_guard.dart';
import '../../../../core/error/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../utils/fleet_list_sort.dart';
import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(
    VehicleRemoteDataSource(
      ref.read(traccarClientProvider),
      ref.read(fleetBaseDataGateProvider),
    ),
  );
});

final vehiclesListProvider =
    FutureProvider.autoDispose<List<VehicleEntity>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!canLoadProtectedData(auth)) {
    logSkippedProtectedLoad('Devices');
    return [];
  }
  return ref.read(vehicleRepositoryProvider).getVehicles();
});

final vehicleDetailProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  if (!canLoadProtectedData(ref.read(authProvider))) {
    logSkippedProtectedLoad('Devices');
    throw const AuthException();
  }
  return ref.read(vehicleRepositoryProvider).getVehicle(id);
});

final vehicleLiveProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  if (!canLoadProtectedData(ref.read(authProvider))) {
    logSkippedProtectedLoad('Devices');
    throw const AuthException();
  }
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
  final briefs = ref.watch(fleetVehicleBriefMapProvider);

  return vehicles.whenData((list) {
    final filtered = list.where((v) {
      final matchQuery = filter.query.isEmpty ||
          v.name.toLowerCase().contains(filter.query.toLowerCase()) ||
          v.plateNumber.toLowerCase().contains(filter.query.toLowerCase()) ||
          (v.uniqueId != null &&
              v.uniqueId!.toLowerCase().contains(filter.query.toLowerCase())) ||
          (v.driverName != null &&
              v.driverName!.toLowerCase().contains(filter.query.toLowerCase()));
      final matchStatus = filter.statusFilter == null ||
          v.status == filter.statusFilter;
      return matchQuery && matchStatus;
    }).toList();
    return FleetListSort.sorted(filtered, briefs);
  });
});

/// Compteurs par statut pour les chips de filtre (masquer ceux à 0).
Map<String?, int> fleetStatusFilterCounts(List<VehicleEntity> vehicles) {
  return {
    null: vehicles.length,
    'moving': vehicles.where((v) => v.status == 'moving').length,
    'stopped': vehicles.where((v) => v.status == 'stopped').length,
    'idle': vehicles.where((v) => v.status == 'idle').length,
    'offline': vehicles.where((v) => v.status == 'offline').length,
  };
}

List<String?> visibleFleetStatusFilters(Map<String?, int> counts) {
  const order = [null, 'moving', 'stopped', 'idle', 'offline'];
  return order.where((s) => s == null || (counts[s] ?? 0) > 0).toList();
}
