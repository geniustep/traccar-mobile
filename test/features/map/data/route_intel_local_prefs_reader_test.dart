import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/core/constants/route_intelligence_local_preference_keys.dart';
import 'package:elmogps/features/map/data/route_intel_local_prefs_reader.dart';

void main() {
  group('routeIntelLocalAttributesFromSharedPreferences', () {
    test('null when no keys', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      expect(routeIntelLocalAttributesFromSharedPreferences(p), isNull);
    });

    test('numeric string mapped to route key', () async {
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh: '88',
      });
      final p = await SharedPreferences.getInstance();
      final m = routeIntelLocalAttributesFromSharedPreferences(p);
      expect(
        m,
        equals({
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: '88',
        }),
      );
    });

    test('detectStops preserves bool false', () async {
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.detectStops: false,
      });
      final p = await SharedPreferences.getInstance();
      final m = routeIntelLocalAttributesFromSharedPreferences(p);
      expect(
        m?[RouteIntelligenceAttributeKeys.detectStops],
        false,
      );
    });
  });
}
