import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/features/map/core/route_stop_address_cache.dart';

void main() {
  group('routeStopAddressCacheKey', () {
    test('same rounded coords share key', () {
      final long = routeStopAddressCacheKey(33.123456789, -7.987654321);
      expect(long, '33.12346_-7.98765');
      final b = routeStopAddressCacheKey(33.12346, -7.98765);
      expect(long, b);
    });

    test('different coords yield different keys', () {
      final a = routeStopAddressCacheKey(10.0, 20.0);
      final b = routeStopAddressCacheKey(10.00002, 20.0);
      expect(a, isNot(b));
    });
  });
}
