import 'fleet_dashboard_period.dart';
import '../../drivers/domain/entities/driver.dart';
import '../../maintenance/domain/entities/maintenance_record.dart';

/// لقطة مجمّعة لواجهة لوحة المدير — بلا منطق شبكة (يُبنى في [FleetAdminSnapshotBuilder]).
class FleetAdminSnapshot {
  const FleetAdminSnapshot({
    this.tripsEventsError,
    required this.period,
    required this.periodDistanceMeters,
    required this.periodImportantAlertsCount,
    required this.vehiclesActiveInPeriod,
    required this.activityTop,
    required this.activityInactive,
    required this.driverRows,
    required this.driverRankingIsEstimated,
    required this.driversLicenseAttention,
    required this.maintenanceUpcoming,
    required this.maintenanceSoon,
    required this.maintenanceOverdueRecords,
    required this.maintenanceOverdueVehicleCount,
    required this.nextMaintenances,
    required this.overdueMaintenanceVehicleNames,
    required this.overspeedCount,
    required this.geofenceCount,
    required this.onlineOfflineEventCount,
    required this.recentImportantEvents,
    required this.utilizationRows,
  });

  /// عند فشل جلب الرحلات/الأحداث فقط؛ بقية الأقسام تُستمد من مزوّدات أخرى.
  final Object? tripsEventsError;

  final FleetDashboardPeriod period;

  final double periodDistanceMeters;
  final int periodImportantAlertsCount;
  final int vehiclesActiveInPeriod;

  final List<VehicleActivityItem> activityTop;
  final List<VehicleActivityItem> activityInactive;

  final List<DriverRankingRow> driverRows;
  final bool driverRankingIsEstimated;

  final List<DriverEntity> driversLicenseAttention;

  final int maintenanceUpcoming;
  final int maintenanceSoon;
  final int maintenanceOverdueRecords;
  final int maintenanceOverdueVehicleCount;
  final List<MaintenancePreviewItem> nextMaintenances;
  final List<String> overdueMaintenanceVehicleNames;

  final int overspeedCount;
  final int geofenceCount;
  final int onlineOfflineEventCount;
  final List<RecentEventItem> recentImportantEvents;

  final List<UtilizationItem> utilizationRows;
}

class VehicleActivityItem {
  const VehicleActivityItem({
    required this.deviceId,
    required this.vehicleName,
    required this.distanceMeters,
    required this.movementSeconds,
    required this.isOffline,
    required this.hasIssue,
  });

  final int deviceId;
  final String vehicleName;
  final double distanceMeters;
  final int movementSeconds;
  final bool isOffline;
  final bool hasIssue;
}

class DriverRankingRow {
  const DriverRankingRow({
    required this.driver,
    required this.distanceMeters,
    required this.importantAlertCount,
    required this.overspeedCount,
  });

  final DriverEntity driver;
  final double distanceMeters;
  final int importantAlertCount;
  final int overspeedCount;
}

class MaintenancePreviewItem {
  const MaintenancePreviewItem({
    required this.record,
    required this.vehicleName,
    required this.daysUntilDue,
  });

  final MaintenanceRecordEntity record;
  final String vehicleName;
  /// سالب إذا المتأخر.
  final int? daysUntilDue;
}

class RecentEventItem {
  const RecentEventItem({
    required this.type,
    required this.deviceId,
    required this.vehicleName,
    required this.eventTime,
  });

  final String type;
  final int deviceId;
  final String vehicleName;
  final DateTime eventTime;
}

class UtilizationItem {
  const UtilizationItem({
    required this.deviceId,
    required this.vehicleName,
    required this.distanceMeters,
    required this.movementSeconds,
    required this.utilizationScore,
    required this.isOffline,
  });

  final int deviceId;
  final String vehicleName;
  final double distanceMeters;
  final int movementSeconds;
  final double utilizationScore;
  final bool isOffline;
}
