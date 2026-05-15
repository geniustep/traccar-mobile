import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elmogps/core/constants/route_intelligence_local_preference_keys.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/data/route_intel_local_prefs_reader.dart';
import 'package:elmogps/features/map/data/route_intel_local_prefs_writer.dart';

void main() {
  group('route intel local prefs writer', () {
    test('writes all keys readably by reader and matches normalized', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final t = const RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 2,
        stopSpeedExitKmh: 1,
        minStopDuration: Duration(minutes: 5),
        overspeedThresholdKmh: 90,
        detectStops: false,
        detectOverspeed: true,
        detectIgnition: false,
      ).normalized();

      await writeRouteIntelLocalThresholdsToSharedPreferences(p, t);
      expect(
        RouteIntelligenceLocalPreferenceKeys.allPreferenceKeys
            .every((k) => p.containsKey(k)),
        isTrue,
      );
      final m = routeIntelLocalAttributesFromSharedPreferences(p);
      final roundTrip = RouteIntelligenceThresholds.fromAttributes(
        m,
        fallback: RouteIntelligenceThresholds.defaults,
      );

      expect(roundTrip.normalized(), t);
      expect(routeIntelThresholdsFromLocalPrefsLayerOnly(p).normalized(), t);

      await clearRouteIntelLocalPreferences(p);
      expect(routeIntelLocalAttributesFromSharedPreferences(p), isNull);
    });

    test('clearRouteIntelLocalPreferences does not remove unrelated keys',
        () async {
      SharedPreferences.setMockInitialValues({
        'unrelated.prefs.key': 'x',
      });
      final p = await SharedPreferences.getInstance();
      await writeRouteIntelLocalThresholdsToSharedPreferences(
        p,
        RouteIntelligenceThresholds.defaults,
      );
      await clearRouteIntelLocalPreferences(p);

      expect(p.getString('unrelated.prefs.key'), 'x');
      expect(routeIntelLocalAttributesFromSharedPreferences(p), isNull);
    });
  });
}
