import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_stop_address_resolver.dart';
import 'package:elmogps/features/map/core/stop_reverse_geocoder.dart';

class _ThrowsGeocoder extends StopReverseGeocoder {
  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    throw Exception('network');
  }
}

class _MapGeocoder extends StopReverseGeocoder {
  _MapGeocoder(this.map);
  final Map<String, String> map;

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async =>
      map['$latitude,$longitude'];
}

void main() {
  final t0 = DateTime.utc(2025, 6, 1, 8);
  final t1 = t0.add(const Duration(minutes: 30));

  group('RouteStopAddressResolver', () {
    test('returns embedded stop address without calling geocoder', () async {
      final geo = _MapGeocoder({'99,99': 'should not run'});
      final r = RouteStopAddressResolver(geocoder: geo);
      final stop = RouteStopEvent(
        startTime: t0,
        endTime: t1,
        latitude: 1.0,
        longitude: 2.0,
        address: '  Server Ave  ',
      );
      expect(await r.resolveStop(stop), 'Server Ave');
    });

    test('uses geocoder and caches result', () async {
      final geo = _MapGeocoder({'1.0,2.0': 'Rue Test'});
      final r = RouteStopAddressResolver(geocoder: geo);
      final stop = RouteStopEvent(
        startTime: t0,
        endTime: t1,
        latitude: 1.0,
        longitude: 2.0,
      );
      expect(await r.resolveStop(stop), 'Rue Test');
      expect(await r.resolveStop(stop), 'Rue Test');
    });

    test('geocoder failure yields null without throwing', () async {
      final r = RouteStopAddressResolver(geocoder: _ThrowsGeocoder());
      final stop = RouteStopEvent(
        startTime: t0,
        endTime: t1,
        latitude: 5.0,
        longitude: 6.0,
      );
      expect(await r.resolveStop(stop), isNull);
      expect(await r.resolveStop(stop), isNull);
    });
  });
}
