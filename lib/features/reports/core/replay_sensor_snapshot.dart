import 'package:flutter/foundation.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../map/data/datasources/route_datasource.dart';

/// Known sensor row kinds for localized labels (Phase R9).
enum ReplaySensorKind {
  fuel,
  battery,
  gsm,
  gpsSatellites,
  gpsAccuracy,
  driver,
}

/// One displayable sensor value (pre-formatted; no raw JSON).
@immutable
class ReplaySensorRow {
  const ReplaySensorRow({
    required this.kind,
    required this.displayValue,
  });

  final ReplaySensorKind kind;
  final String displayValue;
}

/// Sensor rows extracted from a [RoutePoint] (may be empty).
@immutable
class ReplayPointSensorSnapshot {
  const ReplayPointSensorSnapshot({this.rows = const []});

  final List<ReplaySensorRow> rows;

  bool get isEmpty => rows.isEmpty;

  /// Primary rows shown in snapshot details (cap avoids clutter).
  static const int maxRowsInSnapshot = 4;

  List<ReplaySensorRow> get primaryRows =>
      rows.length <= maxRowsInSnapshot
          ? rows
          : rows.sublist(0, maxRowsInSnapshot);
}

/// Ignition: [RoutePoint.ignition] is set at parse from attributes (direct priority).
abstract final class ReplaySensorIgnition {
  ReplaySensorIgnition._();

  /// Returns ignition for display when route analysis suggests ignition data exists.
  static bool resolveForDisplay(RoutePoint point) => point.ignition;
}

/// Maps position `attributes` to displayable sensor values (Phase R9).
abstract final class RoutePointAttributesMapper {
  RoutePointAttributesMapper._();

  static const _fuelKeys = ['fuel', 'fuelLevel', 'fuel.level'];
  static const _batteryKeys = [
    'power',
    'battery',
    'batteryLevel',
    'battery.level',
    'batteryVoltage',
  ];
  static const _gsmKeys = ['rssi', 'gsm', 'gsmSignal', 'signal'];
  static const _satelliteKeys = ['sat', 'satellites', 'gpsSatellites'];
  static const _accuracyKeys = ['accuracy', 'hdop'];
  static const _driverKeys = ['driverName', 'driver'];

  static ReplayPointSensorSnapshot fromRoutePoint(RoutePoint point) {
    final attrs = point.attributes;
    if (attrs == null || attrs.isEmpty) {
      return const ReplayPointSensorSnapshot();
    }

    final rows = <ReplaySensorRow>[];

    void add(ReplaySensorKind kind, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(ReplaySensorRow(kind: kind, displayValue: value));
    }

    add(ReplaySensorKind.fuel, _formatFuel(_firstNum(attrs, _fuelKeys)));
    add(ReplaySensorKind.battery, _formatBattery(attrs));
    add(ReplaySensorKind.gsm, _formatGsm(_firstNum(attrs, _gsmKeys), attrs));
    add(
      ReplaySensorKind.gpsSatellites,
      _formatSatellites(_firstNum(attrs, _satelliteKeys)),
    );
    add(
      ReplaySensorKind.gpsAccuracy,
      _formatAccuracy(_firstNum(attrs, _accuracyKeys), attrs),
    );
    add(ReplaySensorKind.driver, _formatDriver(attrs));

    return ReplayPointSensorSnapshot(rows: rows);
  }

  static num? _firstNum(Map<String, dynamic> attrs, List<String> keys) {
    for (final k in keys) {
      final v = attrs[k];
      final n = _asNum(v);
      if (n != null) return n;
    }
    return null;
  }

  static String? _firstString(Map<String, dynamic> attrs, List<String> keys) {
    for (final k in keys) {
      final v = attrs[k];
      if (v is String) {
        final t = v.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return null;
  }

  static num? _asNum(dynamic v) {
    if (v is num && v.isFinite) return v;
    if (v is String) {
      final p = double.tryParse(v.trim());
      if (p != null && p.isFinite) return p;
    }
    return null;
  }

  /// Fuel 0–100 → percent; 0–1 → percent.
  static String? _formatFuel(num? raw) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v >= 0 && v <= 1) {
      return '${(v * 100).round()}%';
    }
    if (v >= 0 && v <= 100) {
      return '${v.round()}%';
    }
    return null;
  }

  static String? _formatBattery(Map<String, dynamic> attrs) {
    for (final k in _batteryKeys) {
      final n = _asNum(attrs[k]);
      if (n == null) continue;
      final v = n.toDouble();
      final keyLower = k.toLowerCase();
      final looksLikeVoltage =
          keyLower == 'power' ||
          keyLower.contains('voltage') ||
          (v >= 3 && v <= 30);
      if (looksLikeVoltage && v >= 3 && v <= 30) {
        final decimals = v == v.roundToDouble() ? 0 : 1;
        return '${v.toStringAsFixed(decimals)} V';
      }
      if (keyLower.contains('level') ||
          (v >= 0 && v <= 100 && !looksLikeVoltage)) {
        return '${v.round()}%';
      }
    }
    return null;
  }

  static String? _formatGsm(num? raw, Map<String, dynamic> attrs) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v >= 0 && v <= 100 && v == v.roundToDouble()) {
      return '${v.round()}%';
    }
    if (v <= 0 && v >= -120) {
      return '${v.round()} dBm';
    }
    return null;
  }

  static String? _formatSatellites(num? raw) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v >= 0 && v <= 64 && v == v.roundToDouble()) {
      return v.round().toString();
    }
    return null;
  }

  static String? _formatAccuracy(num? raw, Map<String, dynamic> attrs) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (attrs.containsKey('hdop') && v > 0 && v <= 50) {
      return v.toStringAsFixed(1);
    }
    if (v > 0 && v <= 5000) {
      final rounded = v >= 10 ? v.round() : v.toStringAsFixed(1);
      return '$rounded m';
    }
    return null;
  }

  static String? _formatDriver(Map<String, dynamic> attrs) {
    final name = _firstString(attrs, _driverKeys);
    if (name == null) return null;
    if (RegExp(r'^\d+$').hasMatch(name)) return null;
    return name;
  }
}

abstract final class ReplaySensorSnapshotBuilder {
  ReplaySensorSnapshotBuilder._();

  static ReplayPointSensorSnapshot fromRoutePoint(RoutePoint point) =>
      RoutePointAttributesMapper.fromRoutePoint(point);

  static String labelFor(ReplaySensorKind kind, AppLocalizations l10n) {
    return switch (kind) {
      ReplaySensorKind.fuel => l10n.replaySensorFuel,
      ReplaySensorKind.battery => l10n.replaySensorBattery,
      ReplaySensorKind.gsm => l10n.replaySensorGsm,
      ReplaySensorKind.gpsSatellites => l10n.replaySensorSatellites,
      ReplaySensorKind.gpsAccuracy => l10n.replaySensorAccuracy,
      ReplaySensorKind.driver => l10n.replaySensorDriver,
    };
  }
}
