import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/route_intelligence_local_preference_keys.dart';
import '../core/route_intelligence_thresholds.dart';
import 'route_intel_local_prefs_reader.dart';

/// Effective thresholds from **saved local prefs only** merged onto app defaults.
RouteIntelligenceThresholds routeIntelThresholdsFromLocalPrefsLayerOnly(
  SharedPreferences prefs,
) {
  final map = routeIntelLocalAttributesFromSharedPreferences(prefs);
  return RouteIntelligenceThresholds.fromAttributes(
    map,
    fallback: RouteIntelligenceThresholds.defaults,
  );
}

/// Stable fingerprint used to reset UI state when prefs content changes externally.
String routeIntelLocalPrefsFingerprint(SharedPreferences prefs) {
  return RouteIntelligenceLocalPreferenceKeys.allPreferenceKeys
      .map((k) {
        if (!prefs.containsKey(k)) return '$k:§';
        return '$k:${prefs.get(k)}';
      })
      .join('|');
}

/// Persists normalized route-intelligence **local-only** thresholds.
Future<void> writeRouteIntelLocalThresholdsToSharedPreferences(
  SharedPreferences prefs,
  RouteIntelligenceThresholds thresholds,
) async {
  final n = thresholds.normalized();
  await prefs.setDouble(
    RouteIntelligenceLocalPreferenceKeys.stopSpeedEnterKmh,
    n.stopSpeedEnterKmh,
  );
  await prefs.setDouble(
    RouteIntelligenceLocalPreferenceKeys.stopSpeedExitKmh,
    n.stopSpeedExitKmh,
  );
  await prefs.setInt(
    RouteIntelligenceLocalPreferenceKeys.minStopDurationMinutes,
    n.minStopDuration.inMinutes,
  );
  await prefs.setDouble(
    RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh,
    n.overspeedThresholdKmh,
  );
  await prefs.setBool(
    RouteIntelligenceLocalPreferenceKeys.detectStops,
    n.detectStops,
  );
  await prefs.setBool(
    RouteIntelligenceLocalPreferenceKeys.detectOverspeed,
    n.detectOverspeed,
  );
  await prefs.setBool(
    RouteIntelligenceLocalPreferenceKeys.detectIgnition,
    n.detectIgnition,
  );
}

/// Removes **[RouteIntelligenceLocalPreferenceKeys]** entries only — does not touch
/// other prefs (e.g. map zoom policies).
Future<void> clearRouteIntelLocalPreferences(SharedPreferences prefs) async {
  for (final k in RouteIntelligenceLocalPreferenceKeys.allPreferenceKeys) {
    await prefs.remove(k);
  }
}
