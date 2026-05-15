import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';

void main() {
  group('RouteIntelligenceThresholds.mergeFromGroupThenDevice', () {
    test('device overrides group overrides defaults (user example)', () {
      final t = RouteIntelligenceThresholds.mergeFromGroupThenDevice(
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 5,
        },
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
        },
      );
      expect(t.overspeedThresholdKmh, 75);
      expect(t.minStopDuration, const Duration(minutes: 5));
    });

    test('group only', () {
      final t = RouteIntelligenceThresholds.mergeFromGroupThenDevice(
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.detectOverspeed: false,
        },
        deviceAttributes: null,
      );
      expect(t.detectOverspeed, false);
    });
  });

  group('RouteIntelligenceThresholds.mergeLayeredAttributes', () {
    test('local only vs defaults scalar', () {
      final t = RouteIntelligenceThresholds.mergeLayeredAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
      );
      expect(t.overspeedThresholdKmh, 60);
    });

    test('user overrides local for same field', () {
      final t = RouteIntelligenceThresholds.mergeLayeredAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
        },
      );
      expect(t.overspeedThresholdKmh, 55);
    });

    test('group overrides user and local', () {
      final t = RouteIntelligenceThresholds.mergeLayeredAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
        },
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
        },
      );
      expect(t.overspeedThresholdKmh, 70);
    });

    test('device strongest over group/user/local partial merge', () {
      final t = RouteIntelligenceThresholds.mergeLayeredAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 2,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
        },
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
          RouteIntelligenceAttributeKeys.detectStops: false,
        },
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
        },
      );
      expect(t.overspeedThresholdKmh, 75);
      expect(t.detectStops, false);
      expect(t.minStopDuration, const Duration(minutes: 2));
    });

    test('mergeFromGroupThenDevice matches layered equivalent', () {
      expect(
        RouteIntelligenceThresholds.mergeFromGroupThenDevice(
          groupAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
          },
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.minStopDurationMinutes: 8,
          },
        ),
        RouteIntelligenceThresholds.mergeLayeredAttributes(
          groupAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
          },
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.minStopDurationMinutes: 8,
          },
        ),
      );
    });

    test('garbage maps in middle layers non-throwing', () {
      expect(
        () => RouteIntelligenceThresholds.mergeLayeredAttributes(
          localAttributes: {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: Object(),
          },
          userAttributes: {
            RouteIntelligenceAttributeKeys.minStopDurationMinutes: 'nope',
          },
          groupAttributes: const {},
          deviceAttributes: const {},
        ),
        returnsNormally,
      );
    });
  });

  group('RouteIntelligenceThresholds.mergeGlobalContextAttributes', () {
    test('local only', () {
      final t = RouteIntelligenceThresholds.mergeGlobalContextAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
      );
      expect(t.overspeedThresholdKmh, 60);
    });

    test('user beats local', () {
      final t = RouteIntelligenceThresholds.mergeGlobalContextAttributes(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 71,
        },
      );
      expect(t.overspeedThresholdKmh, 71);
    });

    test('invalid layers do not throw', () {
      expect(
        () => RouteIntelligenceThresholds.mergeGlobalContextAttributes(
          localAttributes: {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: Object(),
          },
          userAttributes: {
            RouteIntelligenceAttributeKeys.minStopDurationMinutes: 'xx',
          },
        ),
        returnsNormally,
      );
    });
  });

  group('RouteIntelligenceThresholds.fromAttributes', () {
    test('null or empty → fallback.normalized()', () {
      expect(
        RouteIntelligenceThresholds.fromAttributes(null),
        RouteIntelligenceThresholds.defaults.normalized(),
      );
      expect(
        RouteIntelligenceThresholds.fromAttributes({}),
        RouteIntelligenceThresholds.defaults.normalized(),
      );
    });

    test('overspeed only → partial merge from defaults', () {
      final t = RouteIntelligenceThresholds.fromAttributes(
        const {RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90},
      );
      expect(t.overspeedThresholdKmh, 90);
      expect(t.stopSpeedEnterKmh, RouteIntelligenceThresholds.defaults.stopSpeedEnterKmh);
      expect(t.detectStops, true);
    });

    test('full set of keys overrides all scalars and flags', () {
      final t = RouteIntelligenceThresholds.fromAttributes({
        RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: '2.5',
        RouteIntelligenceAttributeKeys.stopSpeedExitKmh: 6,
        RouteIntelligenceAttributeKeys.minStopDurationMinutes: 7,
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 100.5,
        RouteIntelligenceAttributeKeys.detectStops: 'false',
        RouteIntelligenceAttributeKeys.detectOverspeed: '0',
        RouteIntelligenceAttributeKeys.detectIgnition: 'off',
      });
      expect(t.stopSpeedEnterKmh, 2.5);
      expect(t.stopSpeedExitKmh, 6);
      expect(t.minStopDuration, const Duration(minutes: 7));
      expect(t.overspeedThresholdKmh, closeTo(100.5, 0.001));
      expect(t.detectStops, false);
      expect(t.detectOverspeed, false);
      expect(t.detectIgnition, false);
    });

    test('invalid numbers ignored (use fallback per field)', () {
      final t = RouteIntelligenceThresholds.fromAttributes(
        const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 'nope',
          RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: '-1',
        },
      );
      expect(t.overspeedThresholdKmh,
          RouteIntelligenceThresholds.defaults.overspeedThresholdKmh);
      /// -1 below 0 → normalized() fixes to default enter
      expect(t.stopSpeedEnterKmh,
          RouteIntelligenceThresholds.defaults.stopSpeedEnterKmh);
    });

    test('exit below enter → normalized() lifts exit', () {
      final t = RouteIntelligenceThresholds.fromAttributes(
        const {
          RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: 12,
          RouteIntelligenceAttributeKeys.stopSpeedExitKmh: 8,
        },
      );
      expect(t.stopSpeedEnterKmh, 12);
      expect(t.stopSpeedExitKmh, 12);
    });

    test('minStopDurationMinutes zero ignored', () {
      final t = RouteIntelligenceThresholds.fromAttributes(
        const {RouteIntelligenceAttributeKeys.minStopDurationMinutes: 0},
      );
      expect(t.minStopDuration,
          RouteIntelligenceThresholds.defaults.minStopDuration);
    });

    test('non-throwing on weird types', () {
      final t = RouteIntelligenceThresholds.fromAttributes({
        RouteIntelligenceAttributeKeys.detectStops: <String, Object>{},
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: Object(),
      });
      expect(t, isA<RouteIntelligenceThresholds>());
      expect(t.detectStops,
          RouteIntelligenceThresholds.defaults.detectStops);
    });
  });
}
