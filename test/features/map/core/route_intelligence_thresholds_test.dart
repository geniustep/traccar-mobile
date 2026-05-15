import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';

void main() {
  group('RouteIntelligenceThresholds.defaults', () {
    test('matches legacy analysis defaults', () {
      const d = RouteIntelligenceThresholds.defaults;
      expect(d.stopSpeedEnterKmh, 3.0);
      expect(d.stopSpeedExitKmh, 5.0);
      expect(d.minStopDuration, const Duration(minutes: 4));
      expect(d.overspeedThresholdKmh, 80.0);
      expect(d.detectStops, true);
      expect(d.detectOverspeed, true);
      expect(d.detectIgnition, true);
    });
  });

  group('RouteIntelligenceThresholds.normalized()', () {
    test('fixes negative enter to defaults', () {
      const raw = RouteIntelligenceThresholds(stopSpeedEnterKmh: -10);
      final n = raw.normalized();
      expect(n.stopSpeedEnterKmh, RouteIntelligenceThresholds.defaults.stopSpeedEnterKmh);
    });

    test('fixes NaN exit using default then clamps exit >= enter', () {
      final n = RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 10,
        stopSpeedExitKmh: double.nan,
      ).normalized();
      // Default exit would be below enter; normalization lifts exit to enter.
      expect(n.stopSpeedEnterKmh, 10);
      expect(n.stopSpeedExitKmh, 10);
    });

    test('raises exit above enter when exit is lower', () {
      final n = RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 8,
        stopSpeedExitKmh: 2,
      ).normalized();
      expect(n.stopSpeedEnterKmh, 8);
      expect(n.stopSpeedExitKmh, 8);
    });

    test('fixes zero minStopDuration via fallback', () {
      final n = RouteIntelligenceThresholds(
        minStopDuration: Duration.zero,
      ).normalized();
      expect(n.minStopDuration,
          RouteIntelligenceThresholds.defaults.minStopDuration);
    });

    test('fixes negative minStopDuration via fallback', () {
      final n = RouteIntelligenceThresholds(
        minStopDuration: const Duration(seconds: -1),
      ).normalized();
      expect(n.minStopDuration,
          RouteIntelligenceThresholds.defaults.minStopDuration);
    });

    test('fixes non-positive overspeed via fallback', () {
      expect(
        RouteIntelligenceThresholds(overspeedThresholdKmh: 0).normalized()
            .overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
      expect(
        RouteIntelligenceThresholds(overspeedThresholdKmh: -50).normalized()
            .overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
    });

    test('fixes non-finite overspeed via fallback', () {
      expect(
        RouteIntelligenceThresholds(overspeedThresholdKmh: double.nan)
            .normalized()
            .overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
      expect(
        RouteIntelligenceThresholds(overspeedThresholdKmh: double.infinity)
            .normalized()
            .overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
    });

    test('preserves detect flags unchanged', () {
      final n = RouteIntelligenceThresholds(
        stopSpeedEnterKmh: -1,
        detectStops: false,
        detectOverspeed: false,
        detectIgnition: false,
      ).normalized();
      expect(n.detectStops, false);
      expect(n.detectOverspeed, false);
      expect(n.detectIgnition, false);
    });
  });

  group('cacheKey', () {
    test('matches for same logical values', () {
      expect(
        const RouteIntelligenceThresholds().cacheKey,
        equals(RouteIntelligenceThresholds.defaults.cacheKey),
      );
    });

    test('normalized invalid enter shares cacheKey with defaults', () {
      expect(
        const RouteIntelligenceThresholds(stopSpeedEnterKmh: -1).cacheKey,
        RouteIntelligenceThresholds.defaults.cacheKey,
      );
    });

    test('changes when a scalar changes', () {
      const base = RouteIntelligenceThresholds();
      final other = RouteIntelligenceThresholds(
        overspeedThresholdKmh:
            RouteIntelligenceThresholds.defaults.overspeedThresholdKmh + 1,
      );
      expect(base.cacheKey != other.cacheKey, isTrue);
    });

    test('changes when a detect flag changes', () {
      const a = RouteIntelligenceThresholds();
      const b = RouteIntelligenceThresholds(detectStops: false);
      expect(a.cacheKey != b.cacheKey, isTrue);
    });

    test('stable across separate instances with same fields', () {
      expect(
        const RouteIntelligenceThresholds().cacheKey,
        const RouteIntelligenceThresholds().cacheKey,
      );
    });

    /// Design: [cacheKey] uses [normalized()] internally.
    test('reflects normalization (invalid enter)', () {
      final bad = RouteIntelligenceThresholds(
        stopSpeedEnterKmh: double.nan,
        stopSpeedExitKmh: 5,
      );
      final keyClean = RouteIntelligenceThresholds(
        stopSpeedEnterKmh:
            RouteIntelligenceThresholds.defaults.stopSpeedEnterKmh,
        stopSpeedExitKmh: 5,
      ).cacheKey;
      expect(bad.cacheKey, keyClean);
    });
  });

  group('equality / hashCode', () {
    test('same values are equal', () {
      const a = RouteIntelligenceThresholds();
      const b = RouteIntelligenceThresholds();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different values are not equal', () {
      const a = RouteIntelligenceThresholds();
      const b = RouteIntelligenceThresholds(detectStops: false);
      expect(a == b, false);
    });
  });
}
