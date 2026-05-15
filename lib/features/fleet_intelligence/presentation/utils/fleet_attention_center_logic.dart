import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../map/core/driver_behavior_score_models.dart';
import '../../../map/core/fleet_intelligence_metrics_config.dart';
import '../../../map/core/fleet_intelligence_metrics_models.dart';

/// سبب ظهور مركبة في مركز المتابعة (**Phase 10E**).
enum FleetAttentionReason {
  highRisk,
  lowScore,
  manyOverspeed,
  manyStops,
  inactive,
  insufficientData,
}

@immutable
class FleetAttentionItem {
  const FleetAttentionItem({
    required this.summary,
    required this.reasons,
  });

  final FleetVehicleIntelligenceSummary summary;
  final List<FleetAttentionReason> reasons;

  /// أولوية عرض: أصغر = أعلى الأولوية.
  int get primaryRank {
    var r = 99;
    for (final x in reasons) {
      r = math.min(r, _reasonPriority(x));
    }
    return r;
  }

  static int _reasonPriority(FleetAttentionReason reason) {
    switch (reason) {
      case FleetAttentionReason.highRisk:
        return 0;
      case FleetAttentionReason.lowScore:
        return 1;
      case FleetAttentionReason.manyOverspeed:
        return 2;
      case FleetAttentionReason.manyStops:
        return 3;
      case FleetAttentionReason.insufficientData:
        return 4;
      case FleetAttentionReason.inactive:
        return 5;
    }
  }
}

abstract final class FleetAttentionCenterLogic {
  FleetAttentionCenterLogic._();

  static const int defaultItemLimit = 10;

  /// عتبات «كثرة» بسيطة — منفصلة عن نواة الحاسبة.
  static const int manyStopsMin = 18;
  static Duration get longStopAccumulated => const Duration(hours: 2);

  static int _manyOverspeedThreshold(FleetIntelligenceMetricsConfig cfg) {
    final n = cfg.normalized();
    return math.max(10, n.moderateRiskOverspeedAttentionMin + 2);
  }

  /// أسباب المركبة لهذه الفترة؛ قد تُرجع قائمة فارغة.
  static List<FleetAttentionReason> reasonsForVehicle(
    FleetVehicleIntelligenceSummary s,
    FleetIntelligenceMetricsConfig cfg,
  ) {
    final n = cfg.normalized();
    final out = <FleetAttentionReason>{};

    if (s.riskLevel == DriverRiskLevel.highRisk) {
      out.add(FleetAttentionReason.highRisk);
    }
    if (s.isPeriodScorable &&
        s.periodScore != null &&
        s.periodScore! <= n.attentionScoreAtOrBelow) {
      out.add(FleetAttentionReason.lowScore);
    }
    final ovTh = _manyOverspeedThreshold(n);
    if (s.totalOverspeedEvents >= ovTh) {
      out.add(FleetAttentionReason.manyOverspeed);
    }
    if (s.totalStops >= manyStopsMin ||
        s.totalStopDuration >= longStopAccumulated) {
      out.add(FleetAttentionReason.manyStops);
    }
    if (s.totalTrips == 0 || !s.isActive) {
      out.add(FleetAttentionReason.inactive);
    } else if (!s.isPeriodScorable &&
        s.riskLevel == DriverRiskLevel.unknown) {
      out.add(FleetAttentionReason.insufficientData);
    }

    final list = out.toList()
      ..sort((a, b) => FleetAttentionItem._reasonPriority(a)
          .compareTo(FleetAttentionItem._reasonPriority(b)));

    if (list.isEmpty && s.needsAttention) {
      return [FleetAttentionReason.insufficientData];
    }

    return list;
  }

  static List<FleetAttentionItem> buildItems({
    required List<FleetVehicleIntelligenceSummary> summaries,
    FleetIntelligenceMetricsConfig config =
        FleetIntelligenceMetricsConfig.defaults,
    int limit = defaultItemLimit,
  }) {
    final items = <FleetAttentionItem>[];
    final seen = <String>{};
    for (final s in summaries) {
      if (!seen.add(s.vehicleId)) continue;
      final reasons = reasonsForVehicle(s, config);
      if (reasons.isEmpty) continue;
      items.add(FleetAttentionItem(summary: s, reasons: reasons));
    }

    int compareItems(FleetAttentionItem a, FleetAttentionItem b) {
      final c = a.primaryRank.compareTo(b.primaryRank);
      if (c != 0) return c;
      final as = a.summary.periodScore;
      final bs = b.summary.periodScore;
      if (as != null && bs != null && as != bs) return as.compareTo(bs);
      if (as != null && bs == null) return -1;
      if (as == null && bs != null) return 1;
      return b.summary.totalOverspeedEvents
          .compareTo(a.summary.totalOverspeedEvents);
    }

    items.sort(compareItems);
    if (items.length <= limit) return items;
    return items.sublist(0, limit);
  }
}
