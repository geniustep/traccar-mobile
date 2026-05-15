import 'package:flutter/foundation.dart';

import '../../../core/constants/route_intelligence_attribute_keys.dart';
import 'route_event_models.dart';
import 'route_intelligence_threshold_parsing.dart';

/// Tunable **analysis** thresholds for [RouteEventAnalyzer] (trip meaning).
///
/// Display rules (zoom, marker budgets, etc.) stay in [MapZoomPolicy] /
/// [MapZoomThresholds] — do not mix map UI gates with these values.
@immutable
class RouteIntelligenceThresholds {
  const RouteIntelligenceThresholds({
    this.stopSpeedEnterKmh = 3.0,
    this.stopSpeedExitKmh = 5.0,
    this.minStopDuration = const Duration(minutes: 4),
    this.overspeedThresholdKmh = 80.0,
    this.detectStops = true,
    this.detectOverspeed = true,
    this.detectIgnition = true,
  });

  /// Matches previous hard-coded [RouteEventAnalysisConfig] defaults.
  static const RouteIntelligenceThresholds defaults = RouteIntelligenceThresholds();

  /// Layered merge: **`defaults` → local → user → group → `device`** (per-field:
  /// each next layer overrides only keys it defines; device is strongest).
  static RouteIntelligenceThresholds mergeLayeredAttributes({
    Map<String, dynamic>? localAttributes,
    Map<String, dynamic>? userAttributes,
    Map<String, dynamic>? groupAttributes,
    Map<String, dynamic>? deviceAttributes,
  }) {
    RouteIntelligenceThresholds t = defaults.normalized();
    void apply(Map<String, dynamic>? map) {
      if (map != null && map.isNotEmpty) {
        t = fromAttributes(map, fallback: t);
      }
    }

    apply(localAttributes);
    apply(userAttributes);
    apply(groupAttributes);
    apply(deviceAttributes);
    return t;
  }

  /// **Global (non-vehicle) context:** **`defaults` → local → user** per field.
  ///
  /// Strongest effective source: **user** › local › defaults. Does **not** use
  /// group or device layers.
  static RouteIntelligenceThresholds mergeGlobalContextAttributes({
    Map<String, dynamic>? localAttributes,
    Map<String, dynamic>? userAttributes,
  }) {
    return mergeLayeredAttributes(
      localAttributes: localAttributes,
      userAttributes: userAttributes,
      groupAttributes: null,
      deviceAttributes: null,
    );
  }

  /// Legacy name — same as [mergeLayeredAttributes] with only group + device layers.
  ///
  /// Kept for Phase 6C call sites and tests.
  static RouteIntelligenceThresholds mergeFromGroupThenDevice({
    Map<String, dynamic>? groupAttributes,
    Map<String, dynamic>? deviceAttributes,
  }) {
    return mergeLayeredAttributes(
      localAttributes: null,
      userAttributes: null,
      groupAttributes: groupAttributes,
      deviceAttributes: deviceAttributes,
    );
  }

  /// Parses Traccar **`device.attributes`** (subset of keys — see [RouteIntelligenceAttributeKeys]),
  /// **partial-merge** onto [fallback], then [normalized].
  ///
  /// Never throws: unknown types / missing keys skip that field. Empty or null
  /// map returns `fallback.normalized()` only (no overrides).
  static RouteIntelligenceThresholds fromAttributes(
    Map<String, dynamic>? attributes, {
    RouteIntelligenceThresholds fallback = RouteIntelligenceThresholds.defaults,
  }) {
    final raw = attributes;
    if (raw == null || raw.isEmpty) {
      return fallback.normalized();
    }

    double? ovEnter = routeIntelParseThresholdDouble(
      raw[RouteIntelligenceAttributeKeys.stopSpeedEnterKmh],
    );
    double? ovExit = routeIntelParseThresholdDouble(
      raw[RouteIntelligenceAttributeKeys.stopSpeedExitKmh],
    );

    Duration? ovMinStop;
    final minM = routeIntelParseNonNegativeInt(
      raw[RouteIntelligenceAttributeKeys.minStopDurationMinutes],
    );
    if (minM != null && minM > 0) {
      ovMinStop = Duration(minutes: minM);
    }

    double? ovOver = routeIntelParseThresholdDouble(
      raw[RouteIntelligenceAttributeKeys.overspeedThresholdKmh],
    );

    final ovDS =
        routeIntelParseLooseBool(raw[RouteIntelligenceAttributeKeys.detectStops]);
    final ovDO = routeIntelParseLooseBool(
      raw[RouteIntelligenceAttributeKeys.detectOverspeed],
    );
    final ovDI = routeIntelParseLooseBool(
      raw[RouteIntelligenceAttributeKeys.detectIgnition],
    );

    return RouteIntelligenceThresholds(
      stopSpeedEnterKmh: ovEnter ?? fallback.stopSpeedEnterKmh,
      stopSpeedExitKmh: ovExit ?? fallback.stopSpeedExitKmh,
      minStopDuration: ovMinStop ?? fallback.minStopDuration,
      overspeedThresholdKmh: ovOver ?? fallback.overspeedThresholdKmh,
      detectStops: ovDS ?? fallback.detectStops,
      detectOverspeed: ovDO ?? fallback.detectOverspeed,
      detectIgnition: ovDI ?? fallback.detectIgnition,
    ).normalized();
  }

  /// Below this speed (km/h) we enter a "stopped" segment.
  final double stopSpeedEnterKmh;

  /// Above this speed (km/h) we leave a "stopped" segment (hysteresis).
  final double stopSpeedExitKmh;

  /// Minimum duration to emit a stop event.
  final Duration minStopDuration;

  /// Speed strictly above this (km/h) counts as overspeed during contiguous runs.
  final double overspeedThresholdKmh;

  final bool detectStops;
  final bool detectOverspeed;
  final bool detectIgnition;

  /// Safe values for analysis; never throws. Invalid input falls back to [defaults].
  RouteIntelligenceThresholds normalized() {
    const d = RouteIntelligenceThresholds.defaults;

    var enter = stopSpeedEnterKmh;
    if (!enter.isFinite || enter < 0) enter = d.stopSpeedEnterKmh;

    var exit = stopSpeedExitKmh;
    if (!exit.isFinite) exit = d.stopSpeedExitKmh;
    if (exit < enter) exit = enter;

    var dur = minStopDuration;
    if (dur.inMilliseconds <= 0) dur = d.minStopDuration;

    var over = overspeedThresholdKmh;
    if (!over.isFinite || over <= 0) over = d.overspeedThresholdKmh;

    return RouteIntelligenceThresholds(
      stopSpeedEnterKmh: enter,
      stopSpeedExitKmh: exit,
      minStopDuration: dur,
      overspeedThresholdKmh: over,
      detectStops: detectStops,
      detectOverspeed: detectOverspeed,
      detectIgnition: detectIgnition,
    );
  }

  /// Legacy config shape — used only inside [RouteEventAnalyzer] for stop/overspeed math.
  RouteEventAnalysisConfig toAnalysisConfig() {
    final n = normalized();
    return RouteEventAnalysisConfig(
      stopSpeedEnterKmh: n.stopSpeedEnterKmh,
      stopSpeedExitKmh: n.stopSpeedExitKmh,
      minStopDuration: n.minStopDuration,
      overspeedThresholdKmh: n.overspeedThresholdKmh,
    );
  }

  /// Stable string for memoization alongside route fingerprint (length / first / last fix).
  String get cacheKey {
    final n = normalized();
    return '${n.stopSpeedEnterKmh.toStringAsFixed(4)}_${n.stopSpeedExitKmh.toStringAsFixed(4)}_${n.minStopDuration.inSeconds}_${n.overspeedThresholdKmh.toStringAsFixed(4)}_${n.detectStops}_${n.detectOverspeed}_${n.detectIgnition}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteIntelligenceThresholds &&
          runtimeType == other.runtimeType &&
          stopSpeedEnterKmh == other.stopSpeedEnterKmh &&
          stopSpeedExitKmh == other.stopSpeedExitKmh &&
          minStopDuration == other.minStopDuration &&
          overspeedThresholdKmh == other.overspeedThresholdKmh &&
          detectStops == other.detectStops &&
          detectOverspeed == other.detectOverspeed &&
          detectIgnition == other.detectIgnition;

  @override
  int get hashCode => Object.hash(
        stopSpeedEnterKmh,
        stopSpeedExitKmh,
        minStopDuration,
        overspeedThresholdKmh,
        detectStops,
        detectOverspeed,
        detectIgnition,
      );
}
