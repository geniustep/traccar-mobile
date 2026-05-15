import '../../../vehicles/domain/entities/vehicle.dart';

/// Visibility filter for the live fleet map (in-memory, not persisted).
///
/// [selectedVehicleIds] may later feed a vehicle-comparison feature — keep
/// selection independent of search-only UI state.
class VehicleMapFilterState {
  const VehicleMapFilterState({
    this.selectedVehicleIds = const {},
    this.onlineOnly = false,
    this.movingOnly = false,
    this.searchQuery = '',
  });

  final Set<String> selectedVehicleIds;
  final bool onlineOnly;
  final bool movingOnly;
  final String searchQuery;

  bool get isActive =>
      selectedVehicleIds.isNotEmpty ||
      onlineOnly ||
      movingOnly ||
      searchQuery.trim().isNotEmpty;

  int get selectedCount => selectedVehicleIds.length;

  VehicleMapFilterState copyWith({
    Set<String>? selectedVehicleIds,
    bool? onlineOnly,
    bool? movingOnly,
    String? searchQuery,
    bool clearSelectedIds = false,
    bool clearSearch = false,
  }) {
    return VehicleMapFilterState(
      selectedVehicleIds: clearSelectedIds
          ? const {}
          : (selectedVehicleIds ?? this.selectedVehicleIds),
      onlineOnly: onlineOnly ?? this.onlineOnly,
      movingOnly: movingOnly ?? this.movingOnly,
      searchQuery: clearSearch ? '' : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleMapFilterState &&
          _setEquals(selectedVehicleIds, other.selectedVehicleIds) &&
          onlineOnly == other.onlineOnly &&
          movingOnly == other.movingOnly &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(selectedVehicleIds),
        onlineOnly,
        movingOnly,
        searchQuery,
      );
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final id in a) {
    if (!b.contains(id)) return false;
  }
  return true;
}

/// True when [vehicle] matches a case-insensitive search query.
bool matchesVehicleSearchQuery(VehicleEntity vehicle, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return vehicle.name.toLowerCase().contains(q) ||
      vehicle.plateNumber.toLowerCase().contains(q) ||
      (vehicle.uniqueId != null &&
          vehicle.uniqueId!.toLowerCase().contains(q)) ||
      (vehicle.driverName != null &&
          vehicle.driverName!.toLowerCase().contains(q));
}

/// Quick filters + search for the filter sheet list (no selected-ID restriction).
List<VehicleEntity> vehiclesForFilterSheetList(
  List<VehicleEntity> vehicles, {
  required String searchQuery,
  required bool onlineOnly,
  required bool movingOnly,
}) {
  var result = vehicles;
  if (onlineOnly) {
    result = result.where((v) => v.isOnline).toList();
  }
  if (movingOnly) {
    result = result.where((v) => v.isMoving).toList();
  }
  final q = searchQuery.trim();
  if (q.isNotEmpty) {
    result = result.where((v) => matchesVehicleSearchQuery(v, q)).toList();
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

/// Applies visibility filter rules to the merged fleet list (map markers).
List<VehicleEntity> applyVehicleMapFilter(
  List<VehicleEntity> vehicles,
  VehicleMapFilterState filter,
) {
  var result = vehicles;

  if (filter.selectedVehicleIds.isNotEmpty) {
    final ids = filter.selectedVehicleIds;
    result = result.where((v) => ids.contains(v.id)).toList();
  }

  if (filter.onlineOnly) {
    result = result.where((v) => v.isOnline).toList();
  }

  if (filter.movingOnly) {
    result = result.where((v) => v.isMoving).toList();
  }

  final q = filter.searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((v) => matchesVehicleSearchQuery(v, q)).toList();
  }

  return result;
}
