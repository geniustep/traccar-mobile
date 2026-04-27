import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/traccar_device.dart';
import '../../../../core/models/traccar_position.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';

/// Live fleet counts derived from WebSocket [livePositionsProvider] /
/// [liveDevicesProvider] merged with the last REST vehicle list.
class FleetLiveCounts {
  const FleetLiveCounts({
    required this.total,
    required this.moving,
    required this.stopped,
    required this.idle,
    required this.offline,
    required this.hasLiveData,
  });

  final int total;
  final int moving;
  final int stopped;
  final int idle;
  final int offline;

  /// True when at least one live map entry exists (socket has delivered data).
  final bool hasLiveData;

  static FleetLiveCounts compute(
    List<VehicleEntity> vehicles,
    Map<int, TraccarPosition> livePos,
    Map<int, TraccarDevice> liveDev,
  ) {
    final hasLive = livePos.isNotEmpty || liveDev.isNotEmpty;
    if (!hasLive) {
      return FleetLiveCounts(
        total: vehicles.length,
        moving: 0,
        stopped: 0,
        idle: 0,
        offline: 0,
        hasLiveData: false,
      );
    }

    var moving = 0, stopped = 0, idle = 0, offline = 0;
    for (final v in vehicles) {
      final id = int.tryParse(v.id);
      if (id == null) continue;
      final dev = liveDev[id];
      final pos = livePos[id];
      final bucket = _bucketFor(v, dev, pos);
      switch (bucket) {
        case _FleetBucket.moving:
          moving++;
        case _FleetBucket.stopped:
          stopped++;
        case _FleetBucket.idle:
          idle++;
        case _FleetBucket.offline:
          offline++;
      }
    }

    return FleetLiveCounts(
      total: vehicles.length,
      moving: moving,
      stopped: stopped,
      idle: idle,
      offline: offline,
      hasLiveData: true,
    );
  }
}

enum _FleetBucket { moving, stopped, idle, offline }

_FleetBucket _bucketFor(
  VehicleEntity v,
  TraccarDevice? dev,
  TraccarPosition? pos,
) {
  final deviceStatus = dev?.status;
  if (deviceStatus == 'offline' || deviceStatus == 'unknown') {
    return _FleetBucket.offline;
  }
  if (deviceStatus == null && pos == null && v.isOffline) {
    return _FleetBucket.offline;
  }

  final speedKmh = pos?.speedKmh ?? v.speed;
  final ignition = pos?.ignitionOn ?? v.ignition;

  if (speedKmh > 2.0) return _FleetBucket.moving;
  if (ignition) return _FleetBucket.idle;
  return _FleetBucket.stopped;
}

/// Recalculated moving / stopped / idle / offline from socket + vehicle list.
final fleetLiveCountsProvider = Provider<FleetLiveCounts>((ref) {
  final vehicles = ref.watch(vehiclesListProvider);
  final livePos = ref.watch(livePositionsProvider);
  final liveDev = ref.watch(liveDevicesProvider);

  return vehicles.maybeWhen(
    data: (list) => FleetLiveCounts.compute(list, livePos, liveDev),
    orElse: () => const FleetLiveCounts(
      total: 0,
      moving: 0,
      stopped: 0,
      idle: 0,
      offline: 0,
      hasLiveData: false,
    ),
  );
});

bool _isSameLocalDay(DateTime utcOrLocal) {
  final a = utcOrLocal.toLocal();
  final b = DateTime.now();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Events received on the WebSocket today (local day), from [liveEventsProvider].
final socketEventsTodayCountProvider = Provider<int>((ref) {
  final events = ref.watch(liveEventsProvider);
  return events.where((e) => _isSameLocalDay(e.eventTime)).length;
});
