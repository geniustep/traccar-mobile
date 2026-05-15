import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/features/map/core/route_intelligence_threshold_resolution.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';

void main() {
  group('RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources',
      () {
    test('parity with RouteIntelligenceThresholds.mergeLayeredAttributes', () {
      const localAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.minStopDurationMinutes: 2,
      };
      const userAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 55,
      };
      const groupAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
        RouteIntelligenceAttributeKeys.detectStops: false,
      };
      const deviceAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
      };

      expect(
        RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
          localAttributes: localAttrs,
          userAttributes: userAttrs,
          groupAttributes: groupAttrs,
          deviceAttributes: deviceAttrs,
        ).thresholds,
        RouteIntelligenceThresholds.mergeLayeredAttributes(
          localAttributes: localAttrs,
          userAttributes: userAttrs,
          groupAttributes: groupAttrs,
          deviceAttributes: deviceAttrs,
        ),
      );
    });

    test('defaults only → all sources are defaults', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources();
      expect(r.thresholds, RouteIntelligenceThresholds.defaults.normalized());
      expect(r.sources, RouteIntelligenceThresholdSources.allDefaults);
    });

    test('local only sets sources for provided parsable keys', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
          RouteIntelligenceAttributeKeys.detectStops: false,
        },
      );
      expect(r.thresholds.overspeedThresholdKmh, 60);
      expect(r.thresholds.detectStops, false);
      expect(
        r.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.local,
      );
      expect(
        r.sources.detectStopsSource,
        RouteIntelligenceThresholdSource.local,
      );
      expect(
        r.sources.minStopDurationSource,
        RouteIntelligenceThresholdSource.defaults,
      );
    });

    test('user beats local on same field (source + value)', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 71,
        },
      );
      expect(r.thresholds.overspeedThresholdKmh, 71);
      expect(
        r.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.user,
      );
    });

    test('group beats user/local partial merge sources', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
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
      expect(r.thresholds.minStopDuration, const Duration(minutes: 2));
      expect(
        r.sources.minStopDurationSource,
        RouteIntelligenceThresholdSource.local,
      );
      expect(
        r.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.device,
      );
      expect(
        r.sources.detectStopsSource,
        RouteIntelligenceThresholdSource.group,
      );
    });

    test('invalid device string does not claim field; fallback to group', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
        },
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 'abc',
          RouteIntelligenceAttributeKeys.detectStops: true,
        },
      );
      expect(r.thresholds.overspeedThresholdKmh, 90);
      expect(
        r.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.group,
      );
      expect(
        r.sources.detectStopsSource,
        RouteIntelligenceThresholdSource.device,
      );
    });

    test('readable exit lower than enter: normalized holds device source both', () {
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
        deviceAttributes: const {
          RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: 12,
          RouteIntelligenceAttributeKeys.stopSpeedExitKmh: 8,
        },
      );
      expect(r.thresholds.stopSpeedEnterKmh, 12);
      expect(r.thresholds.stopSpeedExitKmh, 12);
      expect(
        r.sources.stopSpeedEnterKmhSource,
        RouteIntelligenceThresholdSource.device,
      );
      expect(
        r.sources.stopSpeedExitKmhSource,
        RouteIntelligenceThresholdSource.device,
      );
    });
  });

  group('RouteIntelligenceThresholdResolution.mergeGlobalContextAttributesWithSources',
      () {
    test('parity with mergeGlobalContextAttributes', () {
      const localAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 60,
      };
      const userAttrs = <String, dynamic>{
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 71,
      };
      expect(
        RouteIntelligenceThresholdResolution
            .mergeGlobalContextAttributesWithSources(
          localAttributes: localAttrs,
          userAttributes: userAttrs,
        ).thresholds,
        RouteIntelligenceThresholds.mergeGlobalContextAttributes(
          localAttributes: localAttrs,
          userAttributes: userAttrs,
        ),
      );
    });

    test('user beats local for sources', () {
      final r = RouteIntelligenceThresholdResolution
          .mergeGlobalContextAttributesWithSources(
        localAttributes: const {
          RouteIntelligenceAttributeKeys.detectOverspeed: false,
          RouteIntelligenceAttributeKeys.minStopDurationMinutes: 3,
        },
        userAttributes: const {
          RouteIntelligenceAttributeKeys.detectOverspeed: true,
        },
      );
      expect(r.thresholds.detectOverspeed, true);
      expect(
        r.sources.detectOverspeedSource,
        RouteIntelligenceThresholdSource.user,
      );
      expect(
        r.sources.minStopDurationSource,
        RouteIntelligenceThresholdSource.local,
      );
    });
  });
}
