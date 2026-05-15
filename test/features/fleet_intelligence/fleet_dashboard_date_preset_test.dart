import 'package:elmogps/features/fleet_intelligence/presentation/fleet_dashboard_date_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today: midnight local to fixed now', () {
    final now = DateTime(2026, 5, 10, 15, 30);
    final b = fleetDashboardLocalBounds(
      preset: FleetDashboardDatePreset.today,
      now: now,
    );
    expect(b.$1, DateTime(2026, 5, 10));
    expect(b.$2, now);
  });

  test('yesterday: full calendar day', () {
    final now = DateTime(2026, 5, 10, 12);
    final b = fleetDashboardLocalBounds(
      preset: FleetDashboardDatePreset.yesterday,
      now: now,
    );
    expect(b.$1, DateTime(2026, 5, 9));
    expect(b.$2, DateTime(2026, 5, 9, 23, 59, 59));
  });

  test('last7Days: start is 6 days before today start, end is now', () {
    final now = DateTime(2026, 5, 10, 11);
    final b = fleetDashboardLocalBounds(
      preset: FleetDashboardDatePreset.last7Days,
      now: now,
    );
    expect(b.$1, DateTime(2026, 5, 4));
    expect(b.$2, now);
  });

  test('custom: end today uses now; past end uses end of day', () {
    final now = DateTime(2026, 5, 10, 14);
    final r = DateTimeRange(
      start: DateTime(2026, 5, 8),
      end: DateTime(2026, 5, 10, 4),
    );
    final b = fleetDashboardLocalBounds(
      preset: FleetDashboardDatePreset.custom,
      now: now,
      customRange: r,
    );
    expect(b.$1, DateTime(2026, 5, 8));
    expect(b.$2, now);

    final r2 = DateTimeRange(
      start: DateTime(2026, 5, 5),
      end: DateTime(2026, 5, 7, 4),
    );
    final b2 = fleetDashboardLocalBounds(
      preset: FleetDashboardDatePreset.custom,
      now: now,
      customRange: r2,
    );
    expect(b2.$2, DateTime(2026, 5, 7, 23, 59, 59));
  });
}
