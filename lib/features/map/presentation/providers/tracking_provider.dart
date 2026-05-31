import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../vehicles/data/datasources/vehicle_remote_datasource.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../data/datasources/route_datasource.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../core/vehicle_live_merger.dart';

// ── RouteQuery ────────────────────────────────────────────────────────────────

/// Identifies a route request: vehicle + explicit local from/to datetimes.
///
/// Use the factory constructors for common cases:
/// - [RouteQuery.today]   → today 00:00 → now
/// - [RouteQuery.forDate] → full calendar day 00:00 → 23:59:59
@immutable
class RouteQuery {
  const RouteQuery({
    required this.vehicleId,
    required this.from,
    required this.to,
  });

  final String vehicleId;

  /// Start of the range (local time).
  final DateTime from;

  /// End of the range (local time).
  final DateTime to;

  DateTime get fromUtc => from.toUtc();
  DateTime get toUtc   => to.toUtc();

  /// True when both [from] and [to] fall on today's local date.
  bool get isToday {
    final now = DateTime.now();
    return from.year == now.year &&
        from.month == now.month &&
        from.day == now.day &&
        to.year == now.year &&
        to.month == now.month &&
        to.day == now.day;
  }

  /// True when [from] and [to] are on the same calendar day.
  bool get isSingleDay =>
      from.year == to.year &&
      from.month == to.month &&
      from.day == to.day;

  /// Duration of the requested window.
  Duration get window => to.difference(from);

  // ── Factories ──────────────────────────────────────────────────────────────

  /// Today: midnight → now.
  factory RouteQuery.today(String vehicleId) {
    final now = DateTime.now();
    return RouteQuery(
      vehicleId: vehicleId,
      from: DateTime(now.year, now.month, now.day),
      to: now,
    );
  }

  /// Full calendar day: 00:00:00 → 23:59:59.
  factory RouteQuery.forDate(String vehicleId, DateTime date) => RouteQuery(
        vehicleId: vehicleId,
        from: DateTime(date.year, date.month, date.day),
        to: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

  @override
  bool operator ==(Object other) =>
      other is RouteQuery &&
      other.vehicleId == vehicleId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(vehicleId, from, to);
}

// ── Providers ──────────────────────────────────────────────────────────────────

final routeDataSourceProvider = Provider<RouteDataSource>((ref) {
  return RouteDataSource(ref.read(traccarClientProvider));
});

/// REST-loaded base vehicle data (full metadata: name, plate, type, etc.).
/// Used as the foundation for the live vehicle view; position is overridden
/// by socket data when available.
final _baseVehicleProvider =
    FutureProvider.autoDispose.family<VehicleEntity, String>((ref, id) async {
  final ds = VehicleRemoteDataSource(
    ref.read(traccarClientProvider),
    ref.read(fleetBaseDataGateProvider),
  );
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

    return VehicleLiveMerger.mergeIfPresent(vehicle, {deviceId: livePos});
  });
});

/// After [PUT] `/devices/{id}` (e.g. Route Intelligence `attributes`), invalidates
/// cached REST vehicle rows so [liveVehicleProvider] reflects new `deviceAttributes`.
void invalidateVehicleLiveMetadata(WidgetRef ref, String vehicleId) {
  ref.invalidate(_baseVehicleProvider(vehicleId));
  ref.invalidate(liveVehicleProvider(vehicleId));
}

/// Today's route points for a vehicle as LatLng list.
/// Kept for backwards-compatibility with any caller outside tracking screen.
final todayRouteProvider =
    FutureProvider.autoDispose.family<List<LatLng>, String>((ref, id) async {
  final ds = ref.read(routeDataSourceProvider);
  final points = await ds.getRoute(id);
  return points.map((p) => p.position).toList();
});

/// Full route details for a specific [RouteQuery] (vehicleId + date).
/// This is the primary provider used by the tracking screen.
final routeDetailProvider =
    FutureProvider.autoDispose.family<List<RoutePoint>, RouteQuery>(
        (ref, query) async {
  final ds = ref.read(routeDataSourceProvider);
  return ds.getRoute(query.vehicleId, from: query.fromUtc, to: query.toUtc);
});

/// Today's full route details — thin wrapper over [routeDetailProvider].
final todayRouteDetailProvider =
    FutureProvider.autoDispose.family<List<RoutePoint>, String>(
        (ref, id) async {
  return ref.watch(
    routeDetailProvider(RouteQuery.today(id)).future,
  );
});
