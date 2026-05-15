import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/data/route_intelligence_attributes_patch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeRouteIntelligenceIntoAttributes', () {
    test('keeps unrelated keys and overlays only elmo.route.*', () {
      final existing = <String, dynamic>{
        'other': 1,
        'fleet.color': 'blue',
        RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: 2.0,
      };
      final patch = <String, dynamic>{
        RouteIntelligenceAttributeKeys.stopSpeedEnterKmh: 7.0,
        RouteIntelligenceAttributeKeys.detectStops: false,
        'evil.inject': 'no',
      };

      final merged = mergeRouteIntelligenceIntoAttributes(existing, patch);

      expect(merged['other'], 1);
      expect(merged['fleet.color'], 'blue');
      expect(merged[RouteIntelligenceAttributeKeys.stopSpeedEnterKmh], 7.0);
      expect(merged[RouteIntelligenceAttributeKeys.detectStops], false);
      expect(merged.containsKey('evil.inject'), isFalse);
    });

    test('treats null existing as empty map', () {
      final patch = routeIntelThresholdsToAttributeMap(
        const RouteIntelligenceThresholds(),
      );
      final merged = mergeRouteIntelligenceIntoAttributes(null, patch);
      expect(
        merged.keys.toSet().containsAll(RouteIntelligenceAttributeKeys.allKeys),
        isTrue,
      );
    });
  });

  group('removeRouteIntelligenceKeysFromAttributes', () {
    test('removes only RouteIntelligence keys', () {
      final existing = <String, dynamic>{
        'keep.me': true,
        RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90.0,
        RouteIntelligenceAttributeKeys.detectIgnition: true,
      };

      final cleared = removeRouteIntelligenceKeysFromAttributes(existing);

      expect(cleared['keep.me'], true);
      for (final k in RouteIntelligenceAttributeKeys.allKeys) {
        expect(cleared.containsKey(k), isFalse);
      }
    });
  });

  group('routeIntelThresholdsToAttributeMap', () {
    test('outputs normalized values for all keys', () {
      const raw = RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 10,
        stopSpeedExitKmh: 5,
        minStopDuration: Duration(minutes: 0),
      );
      final map = routeIntelThresholdsToAttributeMap(raw);
      final parsed = RouteIntelligenceThresholds.fromAttributes(map);
      expect(parsed, equals(raw.normalized()));
    });
  });
}
