import 'package:elmogps/features/fleet_intelligence/domain/fleet_intelligence_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 5, 10, 8);
  final t1 = DateTime(2026, 5, 10, 18);

  test('cacheKey changes when from/to/maxVehicles/refreshNonce change', () {
    final a = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1);
    final b = FleetIntelligenceQuery(
      fromLocal: t0,
      toLocal: t1,
      maxVehicles: 12,
    );
    final c = FleetIntelligenceQuery(
      fromLocal: t0,
      toLocal: t1,
      refreshNonce: 2,
    );
    expect(a.cacheKey, isNot(b.cacheKey));
    expect(a.cacheKey, isNot(c.cacheKey));
  });

  test('cacheStableKey ignores refreshNonce', () {
    final a = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 0);
    final b =
        FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 99);
    expect(a.cacheStableKey, b.cacheStableKey);
    expect(a.cacheKey, isNot(b.cacheKey));
  });

  test('equality includes fields', () {
    final a = FleetIntelligenceQuery(
      fromLocal: t0,
      toLocal: t1,
      vehicleIds: const ['1', '2'],
      maxVehicles: 10,
      includeInactive: true,
      groupId: 'g1',
    );
    final b = FleetIntelligenceQuery(
      fromLocal: t0,
      toLocal: t1,
      vehicleIds: const ['1', '2'],
      maxVehicles: 10,
      includeInactive: true,
      groupId: 'g1',
    );
    expect(a, equals(b));
    expect(
      FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, groupId: 'x'),
      isNot(
        FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, groupId: 'y'),
      ),
    );
  });
}
