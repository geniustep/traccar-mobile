import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/traccar_device.dart';
import '../../../../core/models/traccar_event.dart';
import '../../../../core/models/traccar_position.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../data/services/dashboard_alert_filter.dart';
import '../../data/services/fleet_status_classifier.dart';

// ── Update-source tracking ────────────────────────────────────────────────────

/// Identifies the origin of the last dashboard data change.
///
/// Used by the UI to decide whether to play the live-pulse animation:
///   • [socket] → scale + flash on animated number widgets
///   • [rest] or [refresh] → counter roll only, no flash
enum DashboardUpdateSource {
  /// Initial load or pull-to-refresh via REST
  rest,
  /// Real-time update from WebSocket
  socket,
  /// Explicit pull-to-refresh initiated by the user
  refresh,
}

// ── Fleet live counts ─────────────────────────────────────────────────────────

/// Snapshot of fleet status counts derived from live WebSocket data.
class FleetLiveCounts {
  const FleetLiveCounts({
    required this.total,
    required this.moving,
    required this.stopped,
    required this.idle,
    required this.offline,
    required this.hasLiveData,
    this.updateSource = DashboardUpdateSource.rest,
  });

  final int total;
  final int moving;
  final int stopped;
  final int idle;
  final int offline;

  /// True once the WebSocket has delivered at least one position or device update.
  final bool hasLiveData;

  /// Origin of the latest count change (drives animation decisions in the UI).
  final DashboardUpdateSource updateSource;

  /// Recomputes counts from the merged vehicle list + live socket maps.
  ///
  /// Classification is fully delegated to [FleetStatusClassifier] — the same
  /// thresholds apply here as in the REST summary builder.
  static FleetLiveCounts compute(
    List<VehicleEntity> vehicles,
    Map<int, TraccarPosition> livePos,
    Map<int, TraccarDevice> liveDev, {
    DashboardUpdateSource source = DashboardUpdateSource.socket,
  }) {
    final hasLive = livePos.isNotEmpty || liveDev.isNotEmpty;

    if (!hasLive) {
      return FleetLiveCounts(
        total: vehicles.length,
        moving: 0,
        stopped: 0,
        idle: 0,
        offline: 0,
        hasLiveData: false,
        updateSource: DashboardUpdateSource.rest,
      );
    }

    var moving = 0, stopped = 0, idle = 0, offline = 0;

    for (final v in vehicles) {
      final id = int.tryParse(v.id);
      if (id == null) continue;

      final dev = liveDev[id];
      final pos = livePos[id];

      // Prefer live device status; fall back to vehicle entity fields
      final deviceStatus = dev?.status ?? (v.isOffline ? 'offline' : 'online');
      final speedKmh = pos?.speedKmh ?? v.speed;
      final ignition = pos?.ignitionOn ?? v.ignition;

      final bucket = FleetStatusClassifier.classify(
        deviceStatus: deviceStatus,
        speedKmh: speedKmh,
        ignition: ignition,
      );

      switch (bucket) {
        case FleetBucket.moving:
          moving++;
        case FleetBucket.stopped:
          stopped++;
        case FleetBucket.idle:
          idle++;
        case FleetBucket.offline:
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
      updateSource: source,
    );
  }
}

/// Recalculates moving / stopped / idle / offline from live socket data.
///
/// Rebuilds only when [livePositionsProvider], [liveDevicesProvider], or
/// [vehiclesListProvider] change.  The UI should use `select` on individual
/// counts when possible to narrow widget rebuilds.
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

// ── Socket event helpers ──────────────────────────────────────────────────────

bool _isSameLocalDay(DateTime utcOrLocal) {
  final a = utcOrLocal.toLocal();
  final b = DateTime.now();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Count of dashboard-relevant WebSocket events received today (local day).
///
/// Only types in [kDashboardAlertTypes] are counted, matching the REST
/// summary's alertsToday calculation.
final socketEventsTodayCountProvider = Provider<int>((ref) {
  final events = ref.watch(liveEventsProvider);
  return events
      .where((e) =>
          _isSameLocalDay(e.eventTime) &&
          DashboardAlertFilter.isImportantEvent(e))
      .length;
});

// ── Socket → AlertEntity conversion ──────────────────────────────────────────

AlertEntity _eventToAlert(TraccarEvent e, String deviceName) => AlertEntity(
      id: DashboardAlertFilter.alertId(e),
      type: e.type,
      severity: _evtSeverity(e.type, e.attributes),
      title: _evtTitle(e.type, e.attributes),
      description: '',
      vehicleId: '${e.deviceId}',
      vehicleName: deviceName,
      createdAt: e.eventTime.toLocal(),
      isRead: false,
      latitude: null,
      longitude: null,
      attributes: e.attributes,
      geofenceId:
          (e.geofenceId != null && e.geofenceId! > 0) ? e.geofenceId : null,
    );

String _evtSeverity(String type, Map<String, dynamic> attrs) =>
    switch (type) {
      'alarm' =>
        (attrs['alarm'] == 'sos' || attrs['alarm'] == 'hardBraking')
            ? 'critical'
            : 'high',
      'deviceOverspeed' => 'high',
      'geofenceExit' || 'geofenceEnter' => 'medium',
      'maintenance' => 'medium',
      'ignitionOn' || 'ignitionOff' => 'info',
      _ => 'info',
    };

String _evtTitle(String type, Map<String, dynamic> attrs) => switch (type) {
      'alarm' => _alarmTitle(attrs['alarm'] as String? ?? ''),
      'deviceOverspeed' => 'تجاوز السرعة المسموح بها',
      'geofenceExit' => 'خروج من المنطقة الجغرافية',
      'geofenceEnter' => 'دخول المنطقة الجغرافية',
      'deviceOffline' => 'الجهاز غير متصل',
      'deviceOnline' => 'الجهاز متصل',
      'ignitionOn' => 'تشغيل المحرك',
      'ignitionOff' => 'إيقاف المحرك',
      'maintenance' => 'تنبيه صيانة',
      _ => type,
    };

String _alarmTitle(String alarm) => switch (alarm) {
      'sos' => 'SOS — نداء استغاثة',
      'hardBraking' => 'كبح مفاجئ',
      'hardAcceleration' => 'تسارع مفاجئ',
      'powerOff' => 'انقطاع الطاقة',
      _ => 'إنذار: $alarm',
    };

/// Live [AlertEntity] list built from WebSocket events (newest-first).
///
/// Filtered to [kDashboardAlertTypes] only — minor telemetry events are
/// excluded.  IDs are normalised via [DashboardAlertFilter.alertId] to
/// prevent duplicates when merged with the REST baseline.
final socketAlertsProvider = Provider<List<AlertEntity>>((ref) {
  final events = ref.watch(liveEventsProvider);
  final liveDev = ref.watch(liveDevicesProvider);

  return events
      .where(DashboardAlertFilter.isImportantEvent)
      .map((e) => _eventToAlert(e, liveDev[e.deviceId]?.name ?? ''))
      .toList();
});
