import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../drivers/domain/entities/driver.dart';
import '../../drivers/presentation/providers/drivers_providers.dart';
import '../../fleet_domain/fleet_condition_logic.dart';
import '../../maintenance/domain/entities/maintenance_record.dart';
import '../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../../vehicles/presentation/providers/vehicles_provider.dart';

class FleetVehicleBrief {
  const FleetVehicleBrief({
    required this.driverLine,
    required this.maintenanceLine,
    required this.hasMaintenanceOverdue,
    required this.insuranceLine,
    required this.techLine,
  });

  final String driverLine;
  final String maintenanceLine;

  /// يُحمَّل عند ظهور أولى صيانة متأخرات لذلك المركبة.
  final bool hasMaintenanceOverdue;

  /// نص مختصر يُطبَع حينَ تُستشعر تهديدات حقيقية فقط لتخفيف الازدحام.
  final String insuranceLine;
  final String techLine;
}

int _maintenanceRank(ElmoMaintenanceSeverity q) => switch (q) {
      ElmoMaintenanceSeverity.unknown => 0,
      ElmoMaintenanceSeverity.completed => 0,
      ElmoMaintenanceSeverity.upcoming => 1,
      ElmoMaintenanceSeverity.soon => 2,
      ElmoMaintenanceSeverity.overdue => 3,
    };

final fleetVehicleBriefMapProvider =
    Provider<Map<String, FleetVehicleBrief>>((ref) {
  ref.watch(localeProvider);
  ref.watch(driversListProvider);
  ref.watch(maintenanceListProvider);
  ref.watch(vehiclesListProvider);

  final locale = ref.read(localeProvider);
  final l10n = AppLocalizations(locale);
  final now = DateTime.now();

  final drivers =
      ref.read(driversListProvider).valueOrNull ?? const <DriverEntity>[];
  final rows =
      ref.read(maintenanceListProvider).valueOrNull ??
          const <MaintenanceRecordEntity>[];
  final vehicles =
      ref.read(vehiclesListProvider).valueOrNull ?? const <VehicleEntity>[];

  final output = <String, FleetVehicleBrief>{};

  for (final vehicle in vehicles) {
    final idNum = int.tryParse(vehicle.id);

    DriverEntity? linkedDriver;
    if (idNum != null) {
      for (final d in drivers) {
        if (d.linkedDeviceIds.contains(idNum)) {
          linkedDriver = d;
          break;
        }
      }
    }

    final displayName =
        linkedDriver?.name ?? vehicle.driverName?.trim();

    final driverLine = displayName != null &&
            displayName.isNotEmpty &&
            !_isPlaceholderDriverName(displayName)
        ? displayName
        : '';

    final scoped = rows
        .where((r) =>
            idNum != null &&
            r.deviceId == idNum &&
            !r.isCompleted)
        .toList(growable: false);

    MaintenanceRecordEntity? highlight;
    var bestRank = -1;
    var overdueAny = false;

    for (final r in scoped) {
      final s = r.resolveSeverity(
        reference: now,
        currentOdometerKm: vehicle.latestOdometerKm,
      );
      if (s == ElmoMaintenanceSeverity.overdue) overdueAny = true;

      final rank = _maintenanceRank(s);
      if (rank > 0 && rank >= bestRank) {
        bestRank = rank;
        highlight = r;
      }
    }

    final maintenanceLine = highlight == null
        ? ''
        : l10n.fleetCardMaintenanceSnippet(
            '${l10n.maintenanceTypeLocalized(highlight.maintenanceTypeCode ?? '')} — ${highlight.name}',
          );

    String docLine(DateTime? d, String label) {
      if (d == null) return '';
      switch (DriverLicenseStatus.fromExpiry(d, now)) {
        case DriverLicenseStatus.expired:
          return '$label — ${l10n.licenseStatusExpired}';
        case DriverLicenseStatus.expiringSoon:
          final days = _daysBetweenUtc(now, d);
          return '$label — ${l10n.licenseStatusSoon} ($days)';
        default:
          return '';
      }
    }

    final insuranceLine = docLine(
      vehicle.insuranceExpiry,
      l10n.fleetDocInsuranceLabel,
    );
    final techLine = docLine(
      vehicle.technicalInspectionExpiry,
      l10n.fleetDocInspectionLabel,
    );

    output[vehicle.id] = FleetVehicleBrief(
      driverLine: driverLine,
      maintenanceLine: maintenanceLine,
      hasMaintenanceOverdue: overdueAny,
      insuranceLine: insuranceLine,
      techLine: techLine,
    );
  }

  return output;
});

bool _isPlaceholderDriverName(String name) {
  final lower = name.trim().toLowerCase();
  const blocked = {
    'no driver assigned',
    'conducteur non assigné',
    'conducteur non assigne',
    'sin conductor asignado',
    'لا يوجد سائق',
    'لا يوجد سائق مخصّص',
    'n/a',
    'na',
    '-',
  };
  return blocked.contains(lower);
}

int _daysBetweenUtc(DateTime a, DateTime b) {
  final da = DateTime.utc(a.year, a.month, a.day);
  final db = DateTime.utc(b.year, b.month, b.day);
  return db.difference(da).inDays;
}
