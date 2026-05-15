import '../../../core/constants/route_intelligence_attribute_keys.dart';
import '../core/route_intelligence_thresholds.dart';

/// Pure helpers for **future** central writes (Phase 6J+): merge or strip
/// `elmo.route.*` keys without touching unrelated attribute entries.
///
/// See `docs/route_intelligence_thresholds_write_policy.md`.

/// Full normalized snapshot as platform `attributes` entries (server/local JSON).
Map<String, dynamic> routeIntelThresholdsToAttributeMap(
  RouteIntelligenceThresholds thresholds,
) {
  final n = thresholds.normalized();
  return <String, dynamic>{
    RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: n.stopSpeedEnterKmh,
    RouteIntelligenceAttributeKeys.stopSpeedExitKmh: n.stopSpeedExitKmh,
    RouteIntelligenceAttributeKeys.minStopDurationMinutes:
        n.minStopDuration.inMinutes,
    RouteIntelligenceAttributeKeys.overspeedThresholdKmh:
        n.overspeedThresholdKmh,
    RouteIntelligenceAttributeKeys.detectStops: n.detectStops,
    RouteIntelligenceAttributeKeys.detectOverspeed: n.detectOverspeed,
    RouteIntelligenceAttributeKeys.detectIgnition: n.detectIgnition,
  };
}

/// Copies [existingAttributes] and overlays only whitelisted `elmo.route.*` keys
/// present in [patch]. Ignores any [patch] keys outside [RouteIntelligenceAttributeKeys.allKeys].
Map<String, dynamic> mergeRouteIntelligenceIntoAttributes(
  Map<String, dynamic>? existingAttributes,
  Map<String, dynamic> patch,
) {
  final out = Map<String, dynamic>.from(existingAttributes ?? {});
  final allowed = RouteIntelligenceAttributeKeys.allKeys.toSet();
  for (final e in patch.entries) {
    if (allowed.contains(e.key)) {
      out[e.key] = e.value;
    }
  }
  return out;
}

/// Removes every [RouteIntelligenceAttributeKeys.allKeys] entry; keeps all other keys.
Map<String, dynamic> removeRouteIntelligenceKeysFromAttributes(
  Map<String, dynamic>? existingAttributes,
) {
  final out = Map<String, dynamic>.from(existingAttributes ?? {});
  for (final k in RouteIntelligenceAttributeKeys.allKeys) {
    out.remove(k);
  }
  return out;
}
