import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/route_intelligence_attribute_keys.dart';
import '../../../core/constants/route_intelligence_local_preference_keys.dart';

/// Reads route-intelligence **local preference** entries into a map keyed by
/// [RouteIntelligenceAttributeKeys], suitable for [RouteIntelligenceThresholds.fromAttributes].
///
/// Never throws; returns `null` when no keys present.
Map<String, dynamic>? routeIntelLocalAttributesFromSharedPreferences(
  SharedPreferences prefs,
) {
  final out = <String, dynamic>{};

  void putNum(String prefsKey, String routeKey) {
    final v = _readNumericLike(prefs, prefsKey);
    if (v != null) out[routeKey] = v;
  }

  void putBool(String prefsKey, String routeKey) {
    final v = _readBoolLike(prefs, prefsKey);
    if (v != null) out[routeKey] = v;
  }

  putNum(
    RouteIntelligenceLocalPreferenceKeys.stopSpeedEnterKmh,
    RouteIntelligenceAttributeKeys.stopSpeedEnterKmh,
  );
  putNum(
    RouteIntelligenceLocalPreferenceKeys.stopSpeedExitKmh,
    RouteIntelligenceAttributeKeys.stopSpeedExitKmh,
  );
  putNum(
    RouteIntelligenceLocalPreferenceKeys.minStopDurationMinutes,
    RouteIntelligenceAttributeKeys.minStopDurationMinutes,
  );
  putNum(
    RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh,
    RouteIntelligenceAttributeKeys.overspeedThresholdKmh,
  );
  putBool(
    RouteIntelligenceLocalPreferenceKeys.detectStops,
    RouteIntelligenceAttributeKeys.detectStops,
  );
  putBool(
    RouteIntelligenceLocalPreferenceKeys.detectOverspeed,
    RouteIntelligenceAttributeKeys.detectOverspeed,
  );
  putBool(
    RouteIntelligenceLocalPreferenceKeys.detectIgnition,
    RouteIntelligenceAttributeKeys.detectIgnition,
  );

  if (out.isEmpty) return null;
  return out;
}

dynamic _readNumericLike(SharedPreferences prefs, String key) {
  if (!prefs.containsKey(key)) return null;
  try {
    final s = prefs.getString(key);
    if (s != null) return s;
  } catch (_) {}
  try {
    final d = prefs.getDouble(key);
    if (d != null) return d;
  } catch (_) {}
  try {
    final i = prefs.getInt(key);
    if (i != null) return i;
  } catch (_) {}
  return null;
}

/// Supports native bool (`false` is preserved) and string forms parsed later by `fromAttributes`.
dynamic _readBoolLike(SharedPreferences prefs, String key) {
  if (!prefs.containsKey(key)) return null;
  try {
    final b = prefs.getBool(key);
    return b;
  } catch (_) {}
  try {
    final s = prefs.getString(key);
    if (s != null && s.isNotEmpty) return s;
  } catch (_) {}
  return null;
}
