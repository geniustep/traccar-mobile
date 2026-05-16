import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutePoint.fromJson', () {
    test('without attributes parses safely', () {
      final p = RoutePoint.fromJson({
        'latitude': 36.8,
        'longitude': 10.18,
        'speed': 10,
        'course': 90,
        'fixTime': '2026-05-15T10:00:00.000Z',
      });
      expect(p.attributes, isNull);
      expect(p.ignition, isFalse);
    });

    test('invalid attributes type does not crash', () {
      final p = RoutePoint.fromJson({
        'latitude': 36.8,
        'longitude': 10.18,
        'speed': 0,
        'course': 0,
        'fixTime': '2026-05-15T10:00:00.000Z',
        'attributes': 'not-a-map',
      });
      expect(p.attributes, isNull);
    });

    test('attributes map preserved', () {
      final p = RoutePoint.fromJson({
        'latitude': 36.8,
        'longitude': 10.18,
        'speed': 0,
        'course': 0,
        'fixTime': '2026-05-15T10:00:00.000Z',
        'attributes': {'fuel': 72, 'ignition': true, 'power': 12.4},
      });
      expect(p.attributes?['fuel'], 72);
      expect(p.ignition, isTrue);
    });
  });
}
