/// Shared parsing helpers for Route Intelligence threshold attributes (`elmo.route.*`).
///
/// Mirrors the logic historically embedded in [RouteIntelligenceThresholds.fromAttributes]
/// so resolution trace stays consistent.
library route_intel_threshold_parsing;

import '../../../core/constants/route_intelligence_attribute_keys.dart';

double? routeIntelParseThresholdDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is double) return raw.isFinite ? raw : null;
  if (raw is int) return raw.toDouble();
  if (raw is num) return raw.toDouble();
  final s = '$raw'.trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

int? routeIntelParseNonNegativeInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw >= 0 ? raw : null;
  if (raw is num) {
    final v = raw.round();
    return v >= 0 ? v : null;
  }
  final s = '$raw'.trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

bool? routeIntelParseLooseBool(dynamic raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) {
    if (raw == 0) return false;
    if (raw == 1) return true;
  }
  final s = '$raw'.trim().toLowerCase();
  if (s.isEmpty) return null;
  if (const {'true', '1', 'yes', 'y', 'on'}.contains(s)) return true;
  if (const {'false', '0', 'no', 'n', 'off'}.contains(s)) return false;
  return null;
}

/// Returns minutes when `raw` parses as a strictly positive duration.
int? routeIntelParsePositiveMinutes(dynamic raw) {
  final minM = routeIntelParseNonNegativeInt(raw);
  if (minM == null || minM <= 0) return null;
  return minM;
}

bool routeIntelParsesStopSpeedEnter(Map<String, dynamic> m) {
  final v =
      routeIntelParseThresholdDouble(m[RouteIntelligenceAttributeKeys.stopSpeedEnterKmh]);
  return v != null;
}

bool routeIntelParsesStopSpeedExit(Map<String, dynamic> m) {
  final v =
      routeIntelParseThresholdDouble(m[RouteIntelligenceAttributeKeys.stopSpeedExitKmh]);
  return v != null;
}

bool routeIntelParsesMinStopDuration(Map<String, dynamic> m) {
  final minM =
      routeIntelParsePositiveMinutes(m[RouteIntelligenceAttributeKeys.minStopDurationMinutes]);
  return minM != null;
}

bool routeIntelParsesOverspeed(Map<String, dynamic> m) {
  final v = routeIntelParseThresholdDouble(
    m[RouteIntelligenceAttributeKeys.overspeedThresholdKmh],
  );
  return v != null;
}

bool routeIntelParsesDetectStops(Map<String, dynamic> m) {
  final v =
      routeIntelParseLooseBool(m[RouteIntelligenceAttributeKeys.detectStops]);
  return v != null;
}

bool routeIntelParsesDetectOverspeed(Map<String, dynamic> m) {
  final v =
      routeIntelParseLooseBool(m[RouteIntelligenceAttributeKeys.detectOverspeed]);
  return v != null;
}

bool routeIntelParsesDetectIgnition(Map<String, dynamic> m) {
  final v =
      routeIntelParseLooseBool(m[RouteIntelligenceAttributeKeys.detectIgnition]);
  return v != null;
}
