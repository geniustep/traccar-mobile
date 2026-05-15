import 'package:flutter/foundation.dart';

import 'route_intelligence_threshold_parsing.dart';
import 'route_intelligence_thresholds.dart';

/// Where a resolved threshold field originated in the layering stack.
enum RouteIntelligenceThresholdSource {
  device,
  group,
  user,
  local,
  defaults,
}

/// Per-field origin for resolved [RouteIntelligenceThresholdResolution.thresholds].
@immutable
class RouteIntelligenceThresholdSources {
  const RouteIntelligenceThresholdSources({
    required this.stopSpeedEnterKmhSource,
    required this.stopSpeedExitKmhSource,
    required this.minStopDurationSource,
    required this.overspeedThresholdKmhSource,
    required this.detectStopsSource,
    required this.detectOverspeedSource,
    required this.detectIgnitionSource,
  });

  /// Every field traced to baked-in defaults (no successful parse overlay).
  static const RouteIntelligenceThresholdSources allDefaults =
      RouteIntelligenceThresholdSources(
    stopSpeedEnterKmhSource: RouteIntelligenceThresholdSource.defaults,
    stopSpeedExitKmhSource: RouteIntelligenceThresholdSource.defaults,
    minStopDurationSource: RouteIntelligenceThresholdSource.defaults,
    overspeedThresholdKmhSource: RouteIntelligenceThresholdSource.defaults,
    detectStopsSource: RouteIntelligenceThresholdSource.defaults,
    detectOverspeedSource: RouteIntelligenceThresholdSource.defaults,
    detectIgnitionSource: RouteIntelligenceThresholdSource.defaults,
  );

  final RouteIntelligenceThresholdSource stopSpeedEnterKmhSource;
  final RouteIntelligenceThresholdSource stopSpeedExitKmhSource;
  final RouteIntelligenceThresholdSource minStopDurationSource;
  final RouteIntelligenceThresholdSource overspeedThresholdKmhSource;
  final RouteIntelligenceThresholdSource detectStopsSource;
  final RouteIntelligenceThresholdSource detectOverspeedSource;
  final RouteIntelligenceThresholdSource detectIgnitionSource;

  RouteIntelligenceThresholdSources copyWith({
    RouteIntelligenceThresholdSource? stopSpeedEnterKmhSource,
    RouteIntelligenceThresholdSource? stopSpeedExitKmhSource,
    RouteIntelligenceThresholdSource? minStopDurationSource,
    RouteIntelligenceThresholdSource? overspeedThresholdKmhSource,
    RouteIntelligenceThresholdSource? detectStopsSource,
    RouteIntelligenceThresholdSource? detectOverspeedSource,
    RouteIntelligenceThresholdSource? detectIgnitionSource,
  }) {
    return RouteIntelligenceThresholdSources(
      stopSpeedEnterKmhSource:
          stopSpeedEnterKmhSource ?? this.stopSpeedEnterKmhSource,
      stopSpeedExitKmhSource:
          stopSpeedExitKmhSource ?? this.stopSpeedExitKmhSource,
      minStopDurationSource:
          minStopDurationSource ?? this.minStopDurationSource,
      overspeedThresholdKmhSource:
          overspeedThresholdKmhSource ?? this.overspeedThresholdKmhSource,
      detectStopsSource: detectStopsSource ?? this.detectStopsSource,
      detectOverspeedSource:
          detectOverspeedSource ?? this.detectOverspeedSource,
      detectIgnitionSource:
          detectIgnitionSource ?? this.detectIgnitionSource,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteIntelligenceThresholdSources &&
          runtimeType == other.runtimeType &&
          stopSpeedEnterKmhSource == other.stopSpeedEnterKmhSource &&
          stopSpeedExitKmhSource == other.stopSpeedExitKmhSource &&
          minStopDurationSource == other.minStopDurationSource &&
          overspeedThresholdKmhSource ==
              other.overspeedThresholdKmhSource &&
          detectStopsSource == other.detectStopsSource &&
          detectOverspeedSource == other.detectOverspeedSource &&
          detectIgnitionSource == other.detectIgnitionSource;

  @override
  int get hashCode => Object.hashAll([
        stopSpeedEnterKmhSource,
        stopSpeedExitKmhSource,
        minStopDurationSource,
        overspeedThresholdKmhSource,
        detectStopsSource,
        detectOverspeedSource,
        detectIgnitionSource,
      ]);
}

/// Final thresholds plus [**source trace**](`RouteIntelligenceThresholdSources`)
/// for preview / debug / admin (Phase 6F).
@immutable
class RouteIntelligenceThresholdResolution {
  const RouteIntelligenceThresholdResolution({
    required this.thresholds,
    required this.sources,
  });

  final RouteIntelligenceThresholds thresholds;
  final RouteIntelligenceThresholdSources sources;

  /// Same merge order as [`RouteIntelligenceThresholds.mergeLayeredAttributes`]:
  /// apply **local → user → group → device**, each layer via [`fromAttributes`].
  ///
  /// A layer attributes **source** to a field only when that field’s raw value is
  /// **parsable** (same rules as `fromAttributes` / helpers in
  /// `route_intelligence_threshold_parsing.dart`). Unparsable garbage does not claim
  /// the field — a lower‑precedence layer can still supply it.
  ///
  /// **Normalization:** values that parse but are sanitized in [`normalized()`]
  /// **keep** the source of the layer that supplied the readable raw values,
  /// including hysteresis clamp when exit speed is below enter speed.
  static RouteIntelligenceThresholdResolution mergeLayeredAttributesWithSources({
    Map<String, dynamic>? localAttributes,
    Map<String, dynamic>? userAttributes,
    Map<String, dynamic>? groupAttributes,
    Map<String, dynamic>? deviceAttributes,
  }) {
    RouteIntelligenceThresholds t =
        RouteIntelligenceThresholds.defaults.normalized();
    var src = RouteIntelligenceThresholdSources.allDefaults;

    void applyLayer(
      Map<String, dynamic>? map,
      RouteIntelligenceThresholdSource layer,
    ) {
      if (map == null || map.isEmpty) return;

      RouteIntelligenceThresholdSources next = src;

      if (routeIntelParsesStopSpeedEnter(map)) {
        next = next.copyWith(stopSpeedEnterKmhSource: layer);
      }
      if (routeIntelParsesStopSpeedExit(map)) {
        next = next.copyWith(stopSpeedExitKmhSource: layer);
      }
      if (routeIntelParsesMinStopDuration(map)) {
        next = next.copyWith(minStopDurationSource: layer);
      }
      if (routeIntelParsesOverspeed(map)) {
        next = next.copyWith(overspeedThresholdKmhSource: layer);
      }
      if (routeIntelParsesDetectStops(map)) {
        next = next.copyWith(detectStopsSource: layer);
      }
      if (routeIntelParsesDetectOverspeed(map)) {
        next = next.copyWith(detectOverspeedSource: layer);
      }
      if (routeIntelParsesDetectIgnition(map)) {
        next = next.copyWith(detectIgnitionSource: layer);
      }

      t = RouteIntelligenceThresholds.fromAttributes(map, fallback: t);
      src = next;
    }

    applyLayer(localAttributes, RouteIntelligenceThresholdSource.local);
    applyLayer(userAttributes, RouteIntelligenceThresholdSource.user);
    applyLayer(groupAttributes, RouteIntelligenceThresholdSource.group);
    applyLayer(deviceAttributes, RouteIntelligenceThresholdSource.device);

    return RouteIntelligenceThresholdResolution(thresholds: t, sources: src);
  }

  /// Same as [`RouteIntelligenceThresholds.mergeGlobalContextAttributes`]:
  /// **local → user** only (effective per-field: user beats local beats defaults).
  static RouteIntelligenceThresholdResolution mergeGlobalContextAttributesWithSources({
    Map<String, dynamic>? localAttributes,
    Map<String, dynamic>? userAttributes,
  }) {
    return mergeLayeredAttributesWithSources(
      localAttributes: localAttributes,
      userAttributes: userAttributes,
      groupAttributes: null,
      deviceAttributes: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteIntelligenceThresholdResolution &&
          runtimeType == other.runtimeType &&
          thresholds == other.thresholds &&
          sources == other.sources;

  @override
  int get hashCode => Object.hash(thresholds, sources);
}
