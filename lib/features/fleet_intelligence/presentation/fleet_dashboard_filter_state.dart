import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/fleet_intelligence_query.dart';
import 'fleet_dashboard_date_preset.dart';

@immutable
class FleetDashboardFilterState {
  const FleetDashboardFilterState({
    this.datePreset = FleetDashboardDatePreset.today,
    this.customRange,
    this.maxVehicles = kFleetIntelligenceDefaultMaxVehicles,
    this.includeInactive = false,
    this.refreshNonce = 0,
  });

  final FleetDashboardDatePreset datePreset;
  final DateTimeRange? customRange;
  final int maxVehicles;
  final bool includeInactive;
  final int refreshNonce;

  FleetDashboardFilterState copyWith({
    FleetDashboardDatePreset? datePreset,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    int? maxVehicles,
    bool? includeInactive,
    int? refreshNonce,
  }) {
    return FleetDashboardFilterState(
      datePreset: datePreset ?? this.datePreset,
      customRange:
          clearCustomRange ? null : (customRange ?? this.customRange),
      maxVehicles: maxVehicles ?? this.maxVehicles,
      includeInactive: includeInactive ?? this.includeInactive,
      refreshNonce: refreshNonce ?? this.refreshNonce,
    );
  }
}
