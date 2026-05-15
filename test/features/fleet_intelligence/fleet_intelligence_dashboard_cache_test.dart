import 'package:elmogps/features/fleet_intelligence/application/fleet_intelligence_dashboard_cache.dart';
import 'package:elmogps/features/fleet_intelligence/domain/fleet_intelligence_dashboard_state.dart';
import 'package:elmogps/features/fleet_intelligence/domain/fleet_intelligence_load_info.dart';
import 'package:elmogps/features/fleet_intelligence/domain/fleet_intelligence_query.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_calculator.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 5, 10, 8);
  final t1 = DateTime(2026, 5, 10, 18);
  FleetIntelligenceDashboardState dummyDashboardState(FleetIntelligenceQuery q,
      {int partialFailures = 0}) {
    final metrics =
        FleetIntelligenceMetricsCalculator.calculate(vehicles: const [
      FleetVehicleTripInput(vehicleId: 'z', trips: []),
    ]);
    return FleetIntelligenceDashboardState(
      metrics: metrics,
      query: q,
      loadInfo: FleetIntelligenceLoadInfo(
        fleetRegisteredCount: 3,
        candidatesConsidered: 2,
        routesAnalyzed: 2,
        routesFailedPartial: partialFailures,
        skippedBeyondCap: 0,
        maxVehicles: q.maxVehicles,
        fromLocal: q.fromLocal,
        toLocal: q.toLocal,
        usedOnlineFirstOrdering: true,
      ),
      generatedAtUtc: DateTime.utc(2026, 5, 10, 10),
    );
  }

  group('FleetIntelligenceDashboardCache', () {
    test('same stable key + same refreshNonce returns cached state', () {
      final cache = FleetIntelligenceDashboardCache(ttl: const Duration(minutes: 5));
      final q0 = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 0);
      final state = dummyDashboardState(q0);
      final u = DateTime.utc(2026, 5, 10, 12);
      cache.record(query: q0, state: state, nowUtc: u);

      final qSame = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 0);
      expect(q0.cacheStableKey, qSame.cacheStableKey);
      final hit = cache.peekIfFresh(query: qSame, nowUtc: u.add(const Duration(seconds: 30)));
      expect(hit, same(state));
    });

    test('refreshNonce bump bypasses cache', () {
      final cache = FleetIntelligenceDashboardCache(ttl: const Duration(minutes: 5));
      final q0 = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 0);
      final u = DateTime.utc(2026, 5, 10, 12);
      cache.record(
        query: q0,
        state: dummyDashboardState(q0),
        nowUtc: u,
      );

      final qBumped =
          FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, refreshNonce: 1);
      expect(
        cache.peekIfFresh(query: qBumped, nowUtc: u.add(const Duration(seconds: 2))),
        isNull,
      );
    });

    test('expired TTL does not serve cache', () {
      final cache =
          FleetIntelligenceDashboardCache(ttl: const Duration(seconds: 1));
      final q0 = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1);
      final tRecord = DateTime.utc(2026, 5, 10, 12);
      cache.record(query: q0, state: dummyDashboardState(q0), nowUtc: tRecord);

      expect(
        cache.peekIfFresh(
          query: q0,
          nowUtc: tRecord.add(const Duration(milliseconds: 500)),
        ),
        isNotNull,
      );
      expect(
        cache.peekIfFresh(
          query: q0,
          nowUtc: tRecord.add(const Duration(seconds: 2)),
        ),
        isNull,
      );
    });

    test('partial failure metadata preserved in round-trip', () {
      final cache = FleetIntelligenceDashboardCache(ttl: const Duration(minutes: 2));
      final q0 = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1);
      final st = dummyDashboardState(q0, partialFailures: 2);
      final u = DateTime.utc(2026, 5, 10, 12);
      cache.record(query: q0, state: st, nowUtc: u);
      final out = cache.peekIfFresh(
        query: q0,
        nowUtc: u.add(const Duration(seconds: 5)),
      );
      expect(out!.partialErrorsCount, 2);
      expect(out.isPartial, isTrue);
    });

    test('different query uses different cache bucket', () {
      final cache = FleetIntelligenceDashboardCache(ttl: const Duration(minutes: 5));
      final qA = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1);
      final qB = FleetIntelligenceQuery(
        fromLocal: t0,
        toLocal: t1.add(const Duration(hours: 1)),
      );
      expect(qA.cacheStableKey, isNot(qB.cacheStableKey));
      final u = DateTime.utc(2026, 5, 10, 12);
      cache.record(query: qA, state: dummyDashboardState(qA), nowUtc: u);
      expect(cache.peekIfFresh(query: qB, nowUtc: u), isNull);
    });
  });
}
