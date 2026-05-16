import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/route_decimator.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import 'multi_replay_kpi.dart';
import 'multi_vehicle_replay_formatters.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_state.dart';
import 'multi_vehicle_replay_timeline.dart';

class MultiVehicleReplayRequest {
  const MultiVehicleReplayRequest({
    required this.vehicleIds,
    required this.date,
  });

  final List<String> vehicleIds;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is MultiVehicleReplayRequest &&
      _listEquals(vehicleIds, other.vehicleIds) &&
      date.year == other.date.year &&
      date.month == other.date.month &&
      date.day == other.date.day;

  @override
  int get hashCode => Object.hashAll([
        ...vehicleIds,
        date.year,
        date.month,
        date.day,
      ]);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final multiVehicleReplayLoaderProvider = FutureProvider.autoDispose
    .family<MultiVehicleReplayLoadState, MultiVehicleReplayRequest>(
        (ref, request) async {
  final ids = request.vehicleIds;
  final date = MultiVehicleReplayFormatters.startOfDay(request.date);
  final dateLabel =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final validation = MultiVehicleReplayTimelineBuilder.validateVehicleCount(
    ids.length,
  );
  if (validation != null) {
    return MultiVehicleReplayLoadState(
      status: MultiVehicleReplayLoadStatus.invalidSelection,
      invalidReason: validation,
      selectedDate: date,
    );
  }

  AppLogger.replay('multi_replay_load_started count=${ids.length} date=$dateLabel');

  final from = date.toUtc();
  final to = MultiVehicleReplayFormatters.endOfDayForReplay(date).toUtc();
  final vehicleNames = _resolveVehicleNames(ref, ids);
  final reportsRepo = ref.read(reportsRepositoryProvider);

  final sw = Stopwatch()..start();

  final tracks = await Future.wait(
    List.generate(ids.length, (i) async {
      final id = ids[i];
      final name = vehicleNames[id] ?? id;
      final vehicleSw = Stopwatch()..start();
      AppLogger.replay('multi_replay_vehicle_load_started vehicleId=$id');

      try {
        final raw = await reportsRepo.getRoute(
          deviceId: id,
          from: from,
          to: to,
        );
        vehicleSw.stop();
        final prepared = MultiVehicleReplayTimelineBuilder.preparePoints(raw);
        final mapPoints = RoutePointDecimator.decimateForMap(
          prepared,
          maxPoints: MultiVehicleReplayLimits.maxPointsPerVehicle,
        );

        AppLogger.replay(
          'multi_replay_vehicle_load_success vehicleId=$id '
          'points=${prepared.length} durationMs=${vehicleSw.elapsedMilliseconds}',
          durationMs: vehicleSw.elapsedMilliseconds,
        );

        return MultiVehicleReplayTrack(
          vehicleId: id,
          name: name,
          colorIndex: i,
          allPoints: prepared,
          mapPoints: mapPoints,
        );
      } catch (e) {
        vehicleSw.stop();
        AppLogger.replay(
          'multi_replay_vehicle_load_failed vehicleId=$id error=${e.runtimeType}',
        );
        return MultiVehicleReplayTrack(
          vehicleId: id,
          name: name,
          colorIndex: i,
          allPoints: const [],
          mapPoints: const [],
          loadError: e,
        );
      }
    }),
  );

  sw.stop();

  if (tracks.every((t) => !t.hasData && t.loadError != null)) {
    AppLogger.replay(
      'multi_replay_load_failed error=all_requests_failed durationMs=${sw.elapsedMilliseconds}',
    );
    return MultiVehicleReplayLoadState(
      status: MultiVehicleReplayLoadStatus.error,
      tracks: tracks,
      selectedDate: date,
      loadDurationMs: sw.elapsedMilliseconds,
    );
  }

  if (!tracks.any((t) => t.hasData)) {
    AppLogger.replay(
      'multi_replay_load_success count=${ids.length} totalPoints=0 '
      'durationMs=${sw.elapsedMilliseconds}',
      durationMs: sw.elapsedMilliseconds,
    );
    return MultiVehicleReplayLoadState(
      status: MultiVehicleReplayLoadStatus.empty,
      tracks: tracks,
      selectedDate: date,
      loadDurationMs: sw.elapsedMilliseconds,
    );
  }

  final timelineSw = Stopwatch()..start();
  final timeline = MultiVehicleReplayTimelineBuilder.build(tracks);
  timelineSw.stop();

  final comparisonSummary = MultiReplayKpiCalculator.buildSummary(tracks);

  final totalPoints = tracks.fold<int>(0, (s, t) => s + t.allPoints.length);

  AppLogger.replay(
    'multi_replay_timeline_built vehicles=${tracks.length} '
    'timestamps=${timeline.timestamps.length} '
    'durationMs=${timelineSw.elapsedMilliseconds}',
    durationMs: timelineSw.elapsedMilliseconds,
  );

  AppLogger.replay(
    'multi_replay_load_success count=${ids.length} totalPoints=$totalPoints '
    'durationMs=${sw.elapsedMilliseconds}',
    durationMs: sw.elapsedMilliseconds,
  );

  return MultiVehicleReplayLoadState(
    status: MultiVehicleReplayLoadStatus.success,
    tracks: tracks,
    timeline: timeline,
    selectedDate: date,
    totalPoints: totalPoints,
    loadDurationMs: sw.elapsedMilliseconds,
    timelineBuildMs: timelineSw.elapsedMilliseconds,
    comparisonSummary: comparisonSummary,
  );
});

Map<String, String> _resolveVehicleNames(Ref ref, List<String> ids) {
  final all = ref.read(mapVehiclesProvider).valueOrNull ?? const [];
  final map = <String, String>{};
  for (final v in all) {
    map[v.id] = v.name;
  }
  return {for (final id in ids) id: map[id] ?? id};
}
