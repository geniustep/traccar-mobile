import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../../map/core/trip_segment_summary.dart';
import '../../domain/entities/vehicle.dart';
import 'fleet_list_placeholders.dart';

/// Priorité d’alerte pour tri et bandeau carte flotte.
enum FleetCardAlertPriority {
  none(100),
  maintenanceNormal(40),
  maintenanceImportant(20),
  critical(0);

  const FleetCardAlertPriority(this.sortRank);
  final int sortRank;
}

/// Bandeau d’alerte / maintenance affiché sur la carte (une seule ligne prioritaire).
class FleetCardAlertBanner {
  const FleetCardAlertBanner({
    required this.priority,
    required this.text,
    required this.isErrorTone,
  });

  final FleetCardAlertPriority priority;
  final String text;
  final bool isErrorTone;
}

/// Logique d’affichage conditionnel pour [VehicleCard] et tri liste flotte.
abstract final class FleetListCardIntel {
  FleetListCardIntel._();

  static const _offlineCritical = Duration(hours: 24);
  static const _offlineAttention = Duration(hours: 2);
  static const _staleData = Duration(hours: 6);
  static const _lowBatteryV = 12.0;
  static const _attentionBatteryV = 12.3;

  /// Seuil batterie faible (tri liste + bandeau).
  static const double lowBatteryThresholdV = _lowBatteryV;

  static final _unreliableAddressTokens = {
    'unknown',
    'n/a',
    'na',
    'null',
    'inconnu',
    'adresse inconnue',
    'unknown address',
    'sin dirección',
    'dirección desconocida',
    'غير معروف',
    'عنوان غير معروف',
  };

  /// Nom conducteur affichable, ou `null` si absent / placeholder.
  static String? driverDisplayName({
    required FleetVehicleBrief? brief,
    required VehicleEntity vehicle,
    required AppLocalizations l10n,
  }) {
    final fromBrief = brief?.driverLine.trim();
    if (FleetListPlaceholders.isDisplayableDriver(fromBrief, l10n)) {
      return _stripDriverPrefix(fromBrief!, l10n);
    }
    final fromVehicle = vehicle.driverName?.trim();
    if (FleetListPlaceholders.isDisplayableDriver(fromVehicle, l10n)) {
      return fromVehicle;
    }
    return null;
  }

  static String _stripDriverPrefix(String line, AppLocalizations l10n) {
    final prefixes = <String>[
      'Driver ',
      'Conducteur ',
      'Conductor ',
      'السائق ',
    ];
    for (final p in prefixes) {
      if (line.startsWith(p)) return line.substring(p.length).trim();
    }
    final assigned = l10n.fleetCardDriverAssigned('{name}');
    const marker = '{name}';
    final idx = assigned.indexOf(marker);
    if (idx >= 0) {
      final prefix = assigned.substring(0, idx);
      final suffix = assigned.substring(idx + marker.length);
      var s = line;
      if (prefix.isNotEmpty && s.startsWith(prefix)) {
        s = s.substring(prefix.length);
      }
      if (suffix.isNotEmpty && s.endsWith(suffix)) {
        s = s.substring(0, s.length - suffix.length);
      }
      return s.trim();
    }
    return line;
  }

  static bool hasUsefulMaintenance(
    FleetVehicleBrief? brief,
    AppLocalizations l10n,
  ) {
    if (brief == null) return false;
    return brief.hasMaintenanceOverdue ||
        FleetListPlaceholders.isDisplayableMaintenance(
          brief.maintenanceLine,
          l10n,
        ) ||
        brief.insuranceLine.isNotEmpty ||
        brief.techLine.isNotEmpty;
  }

  static bool isReliableAddress(String? address) {
    if (address == null) return false;
    final t = address.trim();
    if (t.length < 3) return false;
    final lower = t.toLowerCase();
    if (_unreliableAddressTokens.contains(lower)) return false;
    if (lower.startsWith('unknown ') || lower.startsWith('n/a ')) {
      return false;
    }
    return true;
  }

  static String vehicleIdentifier(VehicleEntity v) {
    final uid = v.uniqueId?.trim();
    if (uid != null && uid.isNotEmpty) return uid;
    final plate = v.plateNumber.trim();
    if (plate.isNotEmpty) return plate;
    return v.id;
  }

  /// Ligne résumé : vitesse · moteur · contexte (arrêt / mouvement).
  static String buildSummaryLine({
    required VehicleEntity vehicle,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final speed = FormatUtils.speed(vehicle.speed);
    final engine = vehicle.ignition
        ? l10n.ignitionOnLabel
        : l10n.ignitionOffLabel;

    final parts = <String>[speed, engine];

    final context = _summaryContextPart(vehicle, l10n, n);
    if (context != null && context.isNotEmpty) parts.add(context);

    return parts.join(' · ');
  }

  /// Lignes de contexte sous le résumé (mouvement, moteur, arrêt).
  static List<String> contextDetailLines({
    required VehicleEntity vehicle,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final lines = <String>[];

    final movement = lastMovementLine(vehicle, l10n, now: n);
    if (movement != null) lines.add(movement);

    final ignition = ignitionContextLine(vehicle, l10n, now: n);
    if (ignition != null && !lines.contains(ignition)) lines.add(ignition);

    final stop = stopDurationLine(vehicle, l10n, now: n);
    if (stop != null && !lines.contains(stop)) lines.add(stop);

    return lines;
  }

  static String? stopDurationLine(
    VehicleEntity vehicle,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    if (vehicle.isOffline || vehicle.isMoving) return null;
    final last = vehicle.lastUpdate;
    if (last == null) return null;
    final since = (now ?? DateTime.now()).difference(last);
    if (since.isNegative) return null;

    final dur = formatTripDurationCompact(since);
    if (vehicle.isStopped) {
      return l10n.fleetCardSummaryStoppedFor(dur);
    }
    if (vehicle.isIdle) {
      return l10n.fleetCardSummaryIdleFor(dur);
    }
    if (!vehicle.ignition) {
      return l10n.fleetCardEngineOffSince(dur);
    }
    return null;
  }

  static String? _summaryContextPart(
    VehicleEntity vehicle,
    AppLocalizations l10n,
    DateTime now,
  ) {
    if (vehicle.isOffline) return null;

    final last = vehicle.lastUpdate;
    if (last == null) return null;

    final since = now.difference(last);
    if (since.isNegative) return null;

    if (vehicle.isMoving && vehicle.speed > 0) {
      return formatRelativeTime(last, l10n, now: now);
    }

    if (vehicle.isIdle && vehicle.ignition) {
      return l10n.fleetCardSummaryIdleFor(formatTripDurationCompact(since));
    }
    if (vehicle.isStopped) {
      return l10n.fleetCardSummaryStoppedFor(formatTripDurationCompact(since));
    }
    if (!vehicle.ignition && !vehicle.isMoving) {
      return l10n.fleetCardSummaryEngineOffFor(formatTripDurationCompact(since));
    }

    return null;
  }

  static FleetCardAlertPriority alertPriority(
    VehicleEntity vehicle,
    FleetVehicleBrief? brief, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    return _resolveAlertPriority(vehicle, brief, n);
  }

  static FleetCardAlertBanner? pickAlertBanner(
    VehicleEntity vehicle,
    FleetVehicleBrief? brief, {
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    FleetCardAlertBanner? best;

    void consider(FleetCardAlertBanner candidate) {
      if (best == null ||
          candidate.priority.sortRank < best!.priority.sortRank) {
        best = candidate;
      }
    }

    // ── Critique ───────────────────────────────────────────────────────────
    final last = vehicle.lastUpdate;
    if (last == null) {
      consider(FleetCardAlertBanner(
        priority: FleetCardAlertPriority.critical,
        text: l10n.fleetCardAlertNoRecentData,
        isErrorTone: true,
      ));
    } else {
      final age = n.difference(last);
      if (vehicle.isOffline && age >= _offlineCritical) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.critical,
          text: l10n.fleetCardAlertOfflineLong(
            formatTripDurationCompact(age),
          ),
          isErrorTone: true,
        ));
      } else if (age >= _staleData) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.critical,
          text: l10n.fleetCardAlertStaleData(
            formatRelativeTime(last, l10n, now: n),
          ),
          isErrorTone: true,
        ));
      } else if (vehicle.isOffline && age >= _offlineAttention) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.critical,
          text: l10n.fleetCardAlertOfflineSince(
            formatRelativeTime(last, l10n, now: n),
          ),
          isErrorTone: true,
        ));
      }
    }

    final v = vehicle.batteryVoltage;
    if (v != null && v < _lowBatteryV) {
      consider(FleetCardAlertBanner(
        priority: FleetCardAlertPriority.critical,
        text: l10n.fleetCardAlertLowBattery(FormatUtils.voltage(v)),
        isErrorTone: true,
      ));
    } else if (v != null && v < _attentionBatteryV) {
      consider(FleetCardAlertBanner(
        priority: FleetCardAlertPriority.maintenanceImportant,
        text: l10n.fleetCardAlertBatteryAttention(FormatUtils.voltage(v)),
        isErrorTone: false,
      ));
    }

    final fuel = vehicle.fuelLevel;
    if (fuel != null && fuel > 0 && fuel < 15) {
      consider(FleetCardAlertBanner(
        priority: FleetCardAlertPriority.maintenanceImportant,
        text: l10n.fleetCardAlertLowFuel('${fuel.toStringAsFixed(0)}%'),
        isErrorTone: false,
      ));
    }

    // ── Maintenance / documents ────────────────────────────────────────────
    if (brief != null) {
      if (brief.hasMaintenanceOverdue &&
          FleetListPlaceholders.isDisplayableMaintenance(
            brief.maintenanceLine,
            l10n,
          )) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.maintenanceImportant,
          text: brief.maintenanceLine.trim(),
          isErrorTone: true,
        ));
      } else if (brief.insuranceLine.isNotEmpty &&
          brief.insuranceLine.contains(l10n.licenseStatusExpired)) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.maintenanceImportant,
          text: brief.insuranceLine,
          isErrorTone: true,
        ));
      } else if (brief.techLine.isNotEmpty &&
          brief.techLine.contains(l10n.licenseStatusExpired)) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.maintenanceImportant,
          text: brief.techLine,
          isErrorTone: true,
        ));
      } else if (FleetListPlaceholders.isDisplayableMaintenance(
        brief.maintenanceLine,
        l10n,
      )) {
        final sev = _maintenanceSeverityFromLine(brief);
        consider(FleetCardAlertBanner(
          priority: sev == ElmoMaintenanceSeverity.soon
              ? FleetCardAlertPriority.maintenanceImportant
              : FleetCardAlertPriority.maintenanceNormal,
          text: brief.maintenanceLine.trim(),
          isErrorTone: sev == ElmoMaintenanceSeverity.soon,
        ));
      } else if (brief.insuranceLine.isNotEmpty) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.maintenanceNormal,
          text: brief.insuranceLine,
          isErrorTone: false,
        ));
      } else if (brief.techLine.isNotEmpty) {
        consider(FleetCardAlertBanner(
          priority: FleetCardAlertPriority.maintenanceNormal,
          text: brief.techLine,
          isErrorTone: false,
        ));
      }
    }

    if (best != null &&
        FleetListPlaceholders.isMaintenancePlaceholder(best!.text, l10n)) {
      return null;
    }
    return best;
  }

  static FleetCardAlertPriority _resolveAlertPriority(
    VehicleEntity vehicle,
    FleetVehicleBrief? brief,
    DateTime now,
  ) {
    FleetCardAlertPriority best = FleetCardAlertPriority.none;

    void consider(FleetCardAlertPriority p) {
      if (p.sortRank < best.sortRank) best = p;
    }

    final last = vehicle.lastUpdate;
    if (last == null) {
      consider(FleetCardAlertPriority.critical);
    } else {
      final age = now.difference(last);
      if (vehicle.isOffline && age >= _offlineCritical) {
        consider(FleetCardAlertPriority.critical);
      } else if (age >= _staleData) {
        consider(FleetCardAlertPriority.critical);
      } else if (vehicle.isOffline && age >= _offlineAttention) {
        consider(FleetCardAlertPriority.critical);
      }
    }

    final v = vehicle.batteryVoltage;
    if (v != null && v < _lowBatteryV) {
      consider(FleetCardAlertPriority.critical);
    } else if (v != null && v < _attentionBatteryV) {
      consider(FleetCardAlertPriority.maintenanceImportant);
    }

    final fuel = vehicle.fuelLevel;
    if (fuel != null && fuel > 0 && fuel < 15) {
      consider(FleetCardAlertPriority.maintenanceImportant);
    }

    if (brief != null) {
      if (brief.hasMaintenanceOverdue &&
          brief.maintenanceLine.trim().isNotEmpty) {
        consider(FleetCardAlertPriority.maintenanceImportant);
      } else if (brief.maintenanceLine.trim().isNotEmpty) {
        consider(FleetCardAlertPriority.maintenanceNormal);
      } else if (brief.insuranceLine.isNotEmpty || brief.techLine.isNotEmpty) {
        consider(FleetCardAlertPriority.maintenanceNormal);
      }
    }

    return best;
  }

  static ElmoMaintenanceSeverity _maintenanceSeverityFromLine(
    FleetVehicleBrief brief,
  ) {
    if (brief.hasMaintenanceOverdue) {
      return ElmoMaintenanceSeverity.overdue;
    }
    return ElmoMaintenanceSeverity.upcoming;
  }

  /// Ligne « dernier mouvement » (hors résumé) si pertinent.
  static String? lastMovementLine(
    VehicleEntity vehicle,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    if (!vehicle.isMoving || vehicle.lastUpdate == null) return null;
    return l10n.fleetCardLastMovement(
      formatRelativeTime(vehicle.lastUpdate!, l10n, now: now),
    );
  }

  /// Dernier allumage / moteur éteint depuis.
  static String? ignitionContextLine(
    VehicleEntity vehicle,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final last = vehicle.lastUpdate;
    if (last == null || vehicle.isOffline) return null;
    final n = now ?? DateTime.now();
    final since = n.difference(last);
    if (since.isNegative) return null;

    if (vehicle.ignition) {
      return l10n.fleetCardLastIgnition(
        formatRelativeTime(last, l10n, now: n),
      );
    }
    if (vehicle.isStopped || vehicle.isIdle) {
      return l10n.fleetCardEngineOffSince(
        formatTripDurationCompact(since),
      );
    }
    return null;
  }

  static String? lastPositionLine(
    VehicleEntity vehicle,
    AppLocalizations l10n,
  ) {
    final addr = vehicle.address;
    if (!isReliableAddress(addr)) return null;
    return l10n.fleetCardLastPosition(addr!.trim());
  }

  static String? lastDataFooterLine(
    VehicleEntity vehicle,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final last = vehicle.lastUpdate;
    if (last == null) return null;
    return l10n.fleetCardLastData(
      formatRelativeTime(last, l10n, now: now),
    );
  }

  static String formatRelativeTime(
    DateTime dt,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final diff = n.difference(dt);
    if (diff.inSeconds < 45) return l10n.relativeJustNow;
    if (diff.inMinutes < 60) {
      return l10n.relativeMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.relativeHoursAgo(diff.inHours);
    }
    if (diff.inDays == 1) {
      final hm = _hm(dt);
      return l10n.relativeYesterdayAt(hm);
    }
    if (diff.inDays < 7) {
      return l10n.relativeDaysAgo(diff.inDays);
    }
    return l10n.relativeDateAt(_shortDate(dt), _hm(dt));
  }

  static String _hm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _shortDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo';
  }
}
