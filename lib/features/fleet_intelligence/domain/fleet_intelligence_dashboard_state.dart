import 'package:flutter/foundation.dart';

import '../../map/core/fleet_intelligence_metrics_models.dart';
import 'fleet_intelligence_load_info.dart';
import 'fleet_intelligence_query.dart';

/// حالة لوحة ذكاء الأسطول — **Phase 10C**.
@immutable
class FleetIntelligenceDashboardState {
  const FleetIntelligenceDashboardState({
    required this.metrics,
    required this.query,
    required this.loadInfo,
    required this.generatedAtUtc,
  });

  final FleetIntelligenceMetrics metrics;
  final FleetIntelligenceQuery query;
  final FleetIntelligenceLoadInfo loadInfo;
  final DateTime generatedAtUtc;

  int get partialErrorsCount => loadInfo.routesFailedPartial;

  bool get isPartial =>
      loadInfo.hasOperationalFailures || loadInfo.isLimitedSample;

  bool get sampleIncomplete =>
      loadInfo.fleetRegisteredCount > metrics.totalVehicles ||
      loadInfo.isLimitedSample;

  bool get hasFleetMembershipIssue =>
      loadInfo.fleetRegisteredCount == 0 ||
      loadInfo.candidatesConsidered == 0 ||
      loadInfo.routesAnalyzed == 0;
}
