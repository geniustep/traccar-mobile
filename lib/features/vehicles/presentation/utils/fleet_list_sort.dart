import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../utils/fleet_list_card_intel.dart';
import '../../domain/entities/vehicle.dart';

/// Tri de la liste flotte : activité récente d’abord, offline ancien en dernier.
///
/// Rangs suggérés (plus petit = plus haut dans la liste) :
/// - 5  : en mouvement + alerte critique
/// - 10 : en mouvement
/// - 15 : arrêté + maintenance / alerte critique
/// - 20 : arrêté récent
/// - 30 : arrêté ancien
/// - 40 : inactif (ralenti)
/// - 60 : hors ligne récent (&lt; 24 h)
/// - 80 : hors ligne prolongé
abstract final class FleetListSort {
  FleetListSort._();

  static const rankMovingCritical = 5;
  static const rankMoving = 10;
  static const rankStoppedAlert = 15;
  static const rankStoppedRecent = 20;
  static const rankStoppedOld = 30;
  static const rankIdle = 40;
  static const rankOfflineRecent = 60;
  static const rankOfflineLong = 80;

  /// Seuil « récent » pour arrêté / hors ligne.
  static const recentActivityThreshold = Duration(hours: 24);

  /// Seuil « arrêté depuis longtemps » (au-delà = rang 30).
  static const stoppedOldThreshold = Duration(hours: 24);

  static int compare(
    VehicleEntity a,
    VehicleEntity b, {
    FleetVehicleBrief? briefA,
    FleetVehicleBrief? briefB,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final ra = _rank(a, briefA, n);
    final rb = _rank(b, briefB, n);
    if (ra != rb) return ra.compareTo(rb);

    final byRecency = _compareLastUpdateDesc(a.lastUpdate, b.lastUpdate);
    if (byRecency != 0) return byRecency;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Plus récent en premier ; sans date en bas du groupe.
  static int _compareLastUpdateDesc(DateTime? a, DateTime? b) {
    if (a != null && b != null) return b.compareTo(a);
    if (a != null) return -1;
    if (b != null) return 1;
    return 0;
  }

  static Duration? _ageSince(VehicleEntity v, DateTime now) {
    final last = v.lastUpdate;
    if (last == null) return null;
    final d = now.difference(last);
    return d.isNegative ? Duration.zero : d;
  }

  static int _rank(
    VehicleEntity v,
    FleetVehicleBrief? brief,
    DateTime now,
  ) {
    final alert = FleetListCardIntel.alertPriority(v, brief, now: now);
    final age = _ageSince(v, now);

    if (v.isMoving) {
      return alert == FleetCardAlertPriority.critical
          ? rankMovingCritical
          : rankMoving;
    }

    if (v.isStopped) {
      if (_promotesStoppedInFleetSort(v, brief, alert)) {
        return rankStoppedAlert;
      }
      if (age == null || age <= stoppedOldThreshold) return rankStoppedRecent;
      return rankStoppedOld;
    }

    if (v.isIdle) {
      return rankIdle;
    }

    if (v.isOffline) {
      // Les alertes ne remontent pas un véhicule hors ligne au-dessus du trafic actif.
      if (age != null && age < recentActivityThreshold) {
        return rankOfflineRecent;
      }
      return rankOfflineLong;
    }

    return rankOfflineLong;
  }

  /// Maintenance / batterie faible — pas « données obsolètes » sur un arrêt ancien.
  static bool _promotesStoppedInFleetSort(
    VehicleEntity v,
    FleetVehicleBrief? brief,
    FleetCardAlertPriority alert,
  ) {
    if (brief?.hasMaintenanceOverdue == true) return true;
    if (alert == FleetCardAlertPriority.maintenanceImportant) return true;
    if (alert == FleetCardAlertPriority.maintenanceNormal &&
        brief != null &&
        brief.maintenanceLine.trim().isNotEmpty) {
      return true;
    }
    final bat = v.batteryVoltage;
    if (bat != null && bat < FleetListCardIntel.lowBatteryThresholdV) {
      return true;
    }
    return false;
  }

  static List<VehicleEntity> sorted(
    List<VehicleEntity> vehicles,
    Map<String, FleetVehicleBrief> briefs, {
    DateTime? now,
  }) {
    final copy = List<VehicleEntity>.from(vehicles);
    copy.sort((a, b) => compare(
          a,
          b,
          briefA: briefs[a.id],
          briefB: briefs[b.id],
          now: now,
        ));
    return copy;
  }
}
