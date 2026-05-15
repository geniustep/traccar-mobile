import '../../../dashboard/data/services/dashboard_alert_filter.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../../maintenance/domain/entities/maintenance_record.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../fleet_admin_snapshot.dart';
import '../fleet_dashboard_period.dart';

/// يبني [FleetAdminSnapshot] من رحلات/أحداث التقارير وقوائم الأسطول المحلية.
///
/// **تقدير ترتيب السائقين:** يُشتق من ربط السائق بالمركبة ([DriverEntity.linkedDeviceIds])
/// ثم تجميع مسافة الرحلات والأحداث المهمة لتلك المركبات فقط. Traccar لا يربط
/// الحدث بمعرّف السائق مباشرةً في كل الحالات، لذلك التصنيف تقريبي مبني على المركبة المرتبطة.
class FleetAdminSnapshotBuilder {
  const FleetAdminSnapshotBuilder._();

  static const double expectedDailyMovementHours = 8;

  static FleetAdminSnapshot build({
    required FleetDashboardPeriod period,
    required List<TripModel> trips,
    required List<Map<String, dynamic>> eventsRaw,
    required List<DriverEntity> drivers,
    required List<VehicleEntity> vehicles,
    required List<MaintenanceRecordEntity> maintenance,
    Object? tripsEventsError,
  }) {
    final nameByDevice = <int, String>{
      for (final v in vehicles)
        if (int.tryParse(v.id) != null) int.parse(v.id): v.name,
    };

    final offlineByDevice = <int, bool>{
      for (final v in vehicles)
        if (int.tryParse(v.id) != null) int.parse(v.id): v.isOffline,
    };

    final overdueDevices = <int>{};
    var maintUp = 0, maintSoon = 0, maintOverdue = 0;
    final now = DateTime.now();

    VehicleEntity? vehicleForDevice(int deviceId) {
      for (final v in vehicles) {
        if (int.tryParse(v.id) == deviceId) return v;
      }
      return null;
    }

    for (final r in maintenance) {
      if (r.isCompleted) continue;
      final vid = r.deviceId;
      final v = vehicleForDevice(vid);
      final sev = r.resolveSeverity(
        reference: now,
        currentOdometerKm: v?.latestOdometerKm,
      );
      switch (sev) {
        case ElmoMaintenanceSeverity.upcoming:
          maintUp++;
        case ElmoMaintenanceSeverity.soon:
          maintSoon++;
        case ElmoMaintenanceSeverity.overdue:
          maintOverdue++;
          overdueDevices.add(vid);
        case ElmoMaintenanceSeverity.unknown:
        case ElmoMaintenanceSeverity.completed:
          break;
      }
    }

    final overspeedByDevice = <int, int>{};
    final importantByDevice = <int, int>{};
    final importantEvents = <Map<String, dynamic>>[];

    for (final e in eventsRaw) {
      final type = e['type'] as String? ?? '';
      if (!DashboardAlertFilter.isImportant(type)) continue;
      importantEvents.add(e);
      final id = (e['deviceId'] as num?)?.toInt() ?? 0;
      if (id == 0) continue;
      importantByDevice[id] = (importantByDevice[id] ?? 0) + 1;
      if (type == 'deviceOverspeed') {
        overspeedByDevice[id] = (overspeedByDevice[id] ?? 0) + 1;
      }
    }

    var overspeedTotal = 0;
    var geofenceTotal = 0;
    var onlineOfflineTotal = 0;
    for (final e in importantEvents) {
      final type = e['type'] as String? ?? '';
      if (type == 'deviceOverspeed') overspeedTotal++;
      if (type == 'geofenceEnter' || type == 'geofenceExit') geofenceTotal++;
      if (type == 'deviceOnline' || type == 'deviceOffline') onlineOfflineTotal++;
    }

    importantEvents.sort((a, b) {
      final ta = DateTime.tryParse(a['eventTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['eventTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    final recent = <RecentEventItem>[];
    for (final e in importantEvents.take(5)) {
      final id = (e['deviceId'] as num?)?.toInt() ?? 0;
      final t = e['type'] as String? ?? '';
      final time = DateTime.tryParse(e['eventTime'] as String? ?? '')?.toLocal() ??
          now;
      recent.add(
        RecentEventItem(
          type: t,
          deviceId: id,
          vehicleName: nameByDevice[id] ?? '',
          eventTime: time,
        ),
      );
    }

    final agg = <int, _TripAgg>{};
    for (final t in trips) {
      final id = int.tryParse(t.vehicleId) ?? 0;
      if (id == 0) continue;
      agg[id] =
          (agg[id] ?? const _TripAgg.zero()).add(t.distanceMeters, t.durationSeconds);
    }

    final periodDistance = trips.fold<double>(0, (s, t) => s + t.distanceMeters);
    final activeDevices = agg.entries.where((e) => e.value.distanceM > 0).length;

    bool hasIssue(int deviceId) {
      final ov = overspeedByDevice[deviceId] ?? 0;
      final od = overdueDevices.contains(deviceId);
      return ov > 0 || od;
    }

    final activityCandidates = agg.entries.toList()
      ..sort((a, b) => b.value.distanceM.compareTo(a.value.distanceM));

    final activityTop = <VehicleActivityItem>[];
    for (final e in activityCandidates.take(5)) {
      final id = e.key;
      final off = offlineByDevice[id] ?? false;
      activityTop.add(
        VehicleActivityItem(
          deviceId: id,
          vehicleName: nameByDevice[id] ?? '#$id',
          distanceMeters: e.value.distanceM,
          movementSeconds: e.value.movementSec,
          isOffline: off,
          hasIssue: hasIssue(id),
        ),
      );
    }

    final inactive = <VehicleActivityItem>[];
    for (final v in vehicles) {
      final id = int.tryParse(v.id);
      if (id == null) continue;
      final moved = agg[id]?.distanceM ?? 0;
      if (moved > 0) continue;
      inactive.add(
        VehicleActivityItem(
          deviceId: id,
          vehicleName: v.name,
          distanceMeters: 0,
          movementSeconds: 0,
          isOffline: v.isOffline,
          hasIssue: hasIssue(id),
        ),
      );
    }
    inactive.sort((a, b) {
      if (a.isOffline != b.isOffline) return a.isOffline ? -1 : 1;
      if (a.hasIssue != b.hasIssue) return a.hasIssue ? -1 : 1;
      return a.vehicleName.compareTo(b.vehicleName);
    });
    final activityInactive = inactive.take(5).toList();

    final licenseAttention = drivers
        .where((d) {
          final st = d.licenseStatus(now);
          return st == DriverLicenseStatus.expired ||
              st == DriverLicenseStatus.expiringSoon;
        })
        .toList();

    final rankingRows = <DriverRankingRow>[];
    for (final d in drivers) {
      if (d.linkedDeviceIds.isEmpty) continue;
      var dist = 0.0;
      var alerts = 0;
      var os = 0;
      for (final id in d.linkedDeviceIds) {
        dist += agg[id]?.distanceM ?? 0;
        alerts += importantByDevice[id] ?? 0;
        os += overspeedByDevice[id] ?? 0;
      }
      if (dist <= 0 && alerts <= 0 && os <= 0) continue;
      rankingRows.add(
        DriverRankingRow(
          driver: d,
          distanceMeters: dist,
          importantAlertCount: alerts,
          overspeedCount: os,
        ),
      );
    }
    rankingRows.sort((a, b) {
      final c = b.distanceMeters.compareTo(a.distanceMeters);
      if (c != 0) return c;
      return a.driver.name.compareTo(b.driver.name);
    });

    final driverRows = rankingRows.take(5).toList();

    final incomplete = maintenance.where((r) => !r.isCompleted).toList();
    incomplete.sort((a, b) {
      final da = a.dueDate;
      final db = b.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    final nextMaintenances = <MaintenancePreviewItem>[];
    for (final r in incomplete) {
      if (nextMaintenances.length >= 5) break;
      if (r.dueDate == null) continue;
      nextMaintenances.add(
        MaintenancePreviewItem(
          record: r,
          vehicleName: nameByDevice[r.deviceId] ?? '#${r.deviceId}',
          daysUntilDue: _daysUntil(r.dueDate!, now),
        ),
      );
    }

    final overdueNames = overdueDevices
        .map((id) => nameByDevice[id] ?? '#$id')
        .toSet()
        .toList()
      ..sort();

    double utilizationScore(int deviceId, int movementSec) {
      final off = offlineByDevice[deviceId] ?? false;
      if (off) return 0;
      if (movementSec <= 0) return 0;
      final h = movementSec / 3600.0;
      final raw = (h / expectedDailyMovementHours) * 100;
      return raw > 100 ? 100 : raw;
    }

    final utilList = agg.entries.map((e) {
      final id = e.key;
      return UtilizationItem(
        deviceId: id,
        vehicleName: nameByDevice[id] ?? '#$id',
        distanceMeters: e.value.distanceM,
        movementSeconds: e.value.movementSec,
        utilizationScore: utilizationScore(id, e.value.movementSec),
        isOffline: offlineByDevice[id] ?? false,
      );
    }).toList()
      ..sort((a, b) => b.utilizationScore.compareTo(a.utilizationScore));

    final utilizationRows = utilList.take(5).toList();

    return FleetAdminSnapshot(
      tripsEventsError: tripsEventsError,
      period: period,
      periodDistanceMeters: periodDistance,
      periodImportantAlertsCount: importantEvents.length,
      vehiclesActiveInPeriod: activeDevices,
      activityTop: activityTop,
      activityInactive: activityInactive,
      driverRows: driverRows,
      driverRankingIsEstimated: true,
      driversLicenseAttention: licenseAttention,
      maintenanceUpcoming: maintUp,
      maintenanceSoon: maintSoon,
      maintenanceOverdueRecords: maintOverdue,
      maintenanceOverdueVehicleCount: overdueDevices.length,
      nextMaintenances: nextMaintenances,
      overdueMaintenanceVehicleNames: overdueNames,
      overspeedCount: overspeedTotal,
      geofenceCount: geofenceTotal,
      onlineOfflineEventCount: onlineOfflineTotal,
      recentImportantEvents: recent,
      utilizationRows: utilizationRows,
    );
  }

  static int? _daysUntil(DateTime due, DateTime reference) {
    final d = DateTime.utc(due.year, due.month, due.day);
    final r = DateTime.utc(reference.year, reference.month, reference.day);
    return d.difference(r).inDays;
  }
}

class _TripAgg {
  const _TripAgg(this.distanceM, this.movementSec);

  const _TripAgg.zero() : distanceM = 0, movementSec = 0;

  final double distanceM;
  final int movementSec;

  _TripAgg add(double dMeters, int durSec) =>
      _TripAgg(distanceM + dMeters, movementSec + durSec);
}
