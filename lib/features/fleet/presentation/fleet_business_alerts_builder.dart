import '../../../core/l10n/app_localizations.dart';
import '../../alerts/domain/entities/alert.dart';
import '../../drivers/domain/entities/driver.dart';
import '../../maintenance/domain/entities/maintenance_record.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../../fleet_domain/fleet_condition_logic.dart';

/// ينشئ تنبيهات العمليات من بيانات الأسطول المحلية دون مسح أحداث مركزية Traccar الخام.
abstract final class FleetBusinessAlertsBuilder {
  static List<AlertEntity> build({
    required AppLocalizations l10n,
    required DateTime now,
    required List<VehicleEntity> vehicles,
    required List<DriverEntity> drivers,
    required List<MaintenanceRecordEntity> maintenance,
  }) {
    final out = <AlertEntity>[];

    void push({
      required String id,
      required String type,
      required String severity,
      required String title,
      required String description,
      required String vehicleId,
      required String vehicleName,
    }) {
      out.add(
        AlertEntity(
          id: id,
          type: type,
          severity: severity,
          title: title,
          description: description,
          vehicleId: vehicleId,
          vehicleName: vehicleName,
          createdAt: now,
          isRead: false,
          latitude: null,
          longitude: null,
          attributes: const {'elmoSynthetic': true},
          geofenceId: null,
        ),
      );
    }

    final nameById = {for (final v in vehicles) v.id: v.name};

    double? odForDevice(int deviceId) {
      final key = '$deviceId';
      for (final v in vehicles) {
        if (v.id == key) return v.latestOdometerKm;
      }
      return null;
    }

    for (final d in drivers) {
      switch (DriverLicenseStatus.fromExpiry(d.licenseExpiry, now)) {
        case DriverLicenseStatus.expired:
          push(
            id: 'elmo_drv_lic_exp_${d.id}',
            type: 'elmo_fleet_license_expired',
            severity: 'high',
            title: l10n.fleetAlertLicenseExpiredTitle,
            description: l10n.fleetAlertLicenseExpiredDesc(d.name),
            vehicleId: d.linkedDeviceIds.isNotEmpty
                ? '${d.linkedDeviceIds.first}'
                : '',
            vehicleName: d.linkedDeviceIds.isEmpty
                ? ''
                : (nameById['${d.linkedDeviceIds.first}'] ?? ''),
          );
        case DriverLicenseStatus.expiringSoon:
          push(
            id: 'elmo_drv_lic_soon_${d.id}',
            type: 'elmo_fleet_license_soon',
            severity: 'medium',
            title: l10n.fleetAlertLicenseSoonTitle,
            description: l10n.fleetAlertLicenseSoonDesc(d.name),
            vehicleId: d.linkedDeviceIds.isNotEmpty
                ? '${d.linkedDeviceIds.first}'
                : '',
            vehicleName: d.linkedDeviceIds.isEmpty
                ? ''
                : (nameById['${d.linkedDeviceIds.first}'] ?? ''),
          );
        default:
          break;
      }
    }

    for (final v in vehicles) {
      switch (DriverLicenseStatus.fromExpiry(v.insuranceExpiry, now)) {
        case DriverLicenseStatus.expired:
          push(
            id: 'elmo_ins_exp_${v.id}',
            type: 'elmo_fleet_insurance_expired',
            severity: 'high',
            title: l10n.fleetAlertInsuranceExpiredTitle,
            description: l10n.fleetAlertInsuranceExpiredDesc(v.name),
            vehicleId: v.id,
            vehicleName: v.name,
          );
        case DriverLicenseStatus.expiringSoon:
          push(
            id: 'elmo_ins_soon_${v.id}',
            type: 'elmo_fleet_insurance_soon',
            severity: 'medium',
            title: l10n.fleetAlertInsuranceSoonTitle,
            description: l10n.fleetAlertInsuranceSoonDesc(v.name),
            vehicleId: v.id,
            vehicleName: v.name,
          );
        default:
          break;
      }

      switch (
          DriverLicenseStatus.fromExpiry(v.technicalInspectionExpiry, now)) {
        case DriverLicenseStatus.expired:
          push(
            id: 'elmo_tech_exp_${v.id}',
            type: 'elmo_fleet_tech_expired',
            severity: 'high',
            title: l10n.fleetAlertTechExpiredTitle,
            description: l10n.fleetAlertTechExpiredDesc(v.name),
            vehicleId: v.id,
            vehicleName: v.name,
          );
        case DriverLicenseStatus.expiringSoon:
          push(
            id: 'elmo_tech_soon_${v.id}',
            type: 'elmo_fleet_tech_soon',
            severity: 'medium',
            title: l10n.fleetAlertTechSoonTitle,
            description: l10n.fleetAlertTechSoonDesc(v.name),
            vehicleId: v.id,
            vehicleName: v.name,
          );
        default:
          break;
      }
    }

    for (final m in maintenance) {
      if (m.deviceId <= 0) continue;

      final vid = '${m.deviceId}';
      final vName = nameById[vid] ?? '';
      final resolved = m.resolveSeverity(
        reference: now,
        currentOdometerKm: odForDevice(m.deviceId),
      );

      switch (resolved) {
        case ElmoMaintenanceSeverity.overdue:
          push(
            id: 'elmo_maint_over_${m.id}',
            type: 'elmo_fleet_maint_overdue',
            severity: 'high',
            title: l10n.fleetAlertMaintOverdueTitle,
            description: l10n.fleetAlertMaintOverdueDesc(vName, m.name),
            vehicleId: vid,
            vehicleName: vName,
          );
        case ElmoMaintenanceSeverity.soon:
          push(
            id: 'elmo_maint_soon_${m.id}',
            type: 'elmo_fleet_maint_soon',
            severity: 'medium',
            title: l10n.fleetAlertMaintSoonTitle,
            description: l10n.fleetAlertMaintSoonDesc(vName, m.name),
            vehicleId: vid,
            vehicleName: vName,
          );
        default:
          break;
      }
    }

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
}
