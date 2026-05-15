import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart'
    show vehicleAlertsProvider;
import '../../../map/presentation/providers/map_provider.dart';
import '../../../reports/domain/entities/summary_report.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../domain/entities/vehicle.dart';
import 'vehicles_provider.dart';
import '../comparison/vehicle_comparison_model.dart';
import '../comparison/vehicle_comparison_state.dart';

/// Stable key for [vehicleComparisonLoaderProvider].
class VehicleComparisonRequest {
  const VehicleComparisonRequest({required this.vehicleIds});

  final List<String> vehicleIds;

  @override
  bool operator ==(Object other) =>
      other is VehicleComparisonRequest &&
      _listEquals(vehicleIds, other.vehicleIds);

  @override
  int get hashCode => Object.hashAll(vehicleIds);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Loads today KPIs for each vehicle in parallel (per-vehicle KPIs also parallel).
final vehicleComparisonLoaderProvider = FutureProvider.autoDispose
    .family<VehicleComparisonState, VehicleComparisonRequest>((ref, request) async {
  final ids = request.vehicleIds;
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final from = todayStart.toUtc();
  final to = now.toUtc();

  final sw = Stopwatch()..start();
  AppLogger.comparison(
    'comparison_load_started count=${ids.length} period=today',
  );

  if (ids.length < 2) {
    AppLogger.comparison('comparison_empty_selection');
    return VehicleComparisonState.success(
      items: const [],
      periodStart: todayStart,
      periodEnd: now,
    );
  }

  try {
    final vehiclesSw = Stopwatch()..start();
    final vehicleById = _resolveVehicles(ref, ids);
    vehiclesSw.stop();
    AppLogger.comparison(
      'load_source vehicles durationMs=${vehiclesSw.elapsedMilliseconds}',
      durationMs: vehiclesSw.elapsedMilliseconds,
      source: 'vehicles',
    );

    final reportsRepo = ref.read(reportsRepositoryProvider);

    final items = await Future.wait(
      ids.map((id) => _loadItem(
            ref: ref,
            vehicleId: id,
            vehicle: vehicleById[id],
            reportsRepo: reportsRepo,
            from: from,
            to: to,
            todayStart: todayStart,
            now: now,
          )),
    );

    sw.stop();
    final totalMs = sw.elapsedMilliseconds;
    final level = totalMs > 8000
        ? 'critical'
        : totalMs > 4000
            ? 'slow'
            : totalMs > 2000
                ? 'acceptable'
                : 'good';
    AppLogger.comparison(
      'comparison_load_success count=${ids.length} durationMs=$totalMs level=$level',
      durationMs: totalMs,
      source: 'total',
    );

    return VehicleComparisonState.success(
      items: items,
      periodStart: todayStart,
      periodEnd: now,
    );
  } catch (e) {
    sw.stop();
    AppLogger.comparison(
      'comparison_load_failed error=$e durationMs=${sw.elapsedMilliseconds}',
    );
    return VehicleComparisonState.failure(
      errorMessage: e.toString(),
      periodStart: todayStart,
      periodEnd: now,
    );
  }
});

Map<String, VehicleEntity> _resolveVehicles(Ref ref, List<String> ids) {
  final map = <String, VehicleEntity>{};

  final mapAsync = ref.read(mapVehiclesProvider);
  for (final v in mapAsync.valueOrNull ?? const <VehicleEntity>[]) {
    map[v.id] = v;
  }

  final missing = ids.where((id) => !map.containsKey(id)).toList();
  if (missing.isEmpty) return map;

  final listAsync = ref.read(vehiclesListProvider);
  for (final v in listAsync.valueOrNull ?? const <VehicleEntity>[]) {
    if (ids.contains(v.id)) map[v.id] = v;
  }

  return map;
}

Future<T> _logTimed<T>(
  String source,
  String vehicleId,
  Future<T> Function() run,
) async {
  final sw = Stopwatch()..start();
  try {
    return await run();
  } finally {
    sw.stop();
    AppLogger.comparison(
      'load_source $source vehicleId=$vehicleId durationMs=${sw.elapsedMilliseconds}',
      durationMs: sw.elapsedMilliseconds,
      source: source,
    );
  }
}

Future<VehicleComparisonItem> _loadItem({
  required Ref ref,
  required String vehicleId,
  required VehicleEntity? vehicle,
  required ReportsRepository reportsRepo,
  required DateTime from,
  required DateTime to,
  required DateTime todayStart,
  required DateTime now,
}) async {
  final results = await Future.wait<Object?>([
    _logTimed<SummaryReport?>('summary', vehicleId, () async {
      try {
        return await reportsRepo.getSummary(
          deviceId: vehicleId,
          from: from,
          to: to,
        );
      } catch (_) {
        return null;
      }
    }),
    _logTimed<({int count, int seconds})?>('stops', vehicleId, () async {
      try {
        final stops = await reportsRepo.getStops(
          deviceId: vehicleId,
          from: from,
          to: to,
        );
        var sec = 0;
        for (final s in stops) {
          sec += s.durationSeconds;
        }
        return (count: stops.length, seconds: sec);
      } catch (_) {
        return null;
      }
    }),
    _logTimed<int?>('trips', vehicleId, () async {
      try {
        final trips = await reportsRepo.getTrips(
          deviceId: vehicleId,
          from: from,
          to: to,
        );
        return trips.length;
      } catch (_) {
        return null;
      }
    }),
    _logTimed<int?>('alerts', vehicleId, () async {
      try {
        final alerts = await ref.read(vehicleAlertsProvider(vehicleId).future);
        return alerts
            .where((a) =>
                !a.createdAt.isBefore(todayStart) &&
                !a.createdAt.isAfter(now))
            .length;
      } catch (_) {
        return null;
      }
    }),
  ]);

  final summary = results[0] as SummaryReport?;
  final stopsData = results[1] as ({int count, int seconds})?;
  final tripsCount = results[2] as int?;
  final alertsTodayCount = results[3] as int?;

  final v = vehicle;
  final plate = v != null && v.plateNumber.isNotEmpty
      ? v.plateNumber
      : (v?.uniqueId);

  return VehicleComparisonItem(
    vehicleId: vehicleId,
    name: v?.name ?? vehicleId,
    plate: plate?.isNotEmpty == true ? plate : null,
    status: v?.status,
    lastUpdate: v?.lastUpdate,
    distanceKm: summary?.totalDistanceKm,
    tripsCount: tripsCount,
    stopsCount: stopsData?.count,
    stopDurationSeconds: stopsData?.seconds,
    maxSpeedKmh: summary?.maxSpeedKmh,
    averageSpeedKmh: summary?.averageSpeedKmh,
    alertsToday: alertsTodayCount,
    engineDurationSeconds: summary?.engineDuration.inSeconds,
  );
}
