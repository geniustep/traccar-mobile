import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elmogps/features/map/core/route_event_analyzer.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_stop_address_enrichment.dart';
import 'package:elmogps/features/map/core/route_stop_address_resolver.dart';
import 'package:elmogps/features/map/core/stop_reverse_geocoder.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';

import 'route_point_fixtures.dart';

void main() {
  test('mergeStopAddressesFromRoutePoints fills stop from points in window', () {
    final pos = const LatLng(10.0, 20.0);
    final t0 = utc(2025, 6, 1, 8);
    final points = <RoutePoint>[
      testRoutePoint(pos, 2, t0),
      RoutePoint(
        position: pos,
        speed: 2,
        course: 0,
        fixTime: t0.add(const Duration(minutes: 10)),
        ignition: false,
        address: 'Quartier Central',
      ),
      testRoutePoint(pos, 2, t0.add(const Duration(minutes: 25))),
    ];
    final analysis = RouteEventAnalyzer.analyze(points);
    expect(analysis.stops, isNotEmpty);
    final merged = mergeStopAddressesFromRoutePoints(analysis.stops, points);
    expect(merged.single.address, 'Quartier Central');
  });

  test('RoutePoint.fromJson reads top-level address', () {
    final p = RoutePoint.fromJson({
      'latitude': 11.0,
      'longitude': 22.0,
      'speed': 0,
      'course': 0,
      'fixTime': '2025-06-01T08:00:00.000Z',
      'address': '  Ville Test  ',
      'attributes': <String, dynamic>{},
    });
    expect(p.address, 'Ville Test');
  });

  test('prefetchStopAddressesSequential respects maxGeocode', () async {
    final pos = const LatLng(1.0, 2.0);
    final t = utc(2025, 1, 1, 0);
    final stops = [
      for (var i = 0; i < 25; i++)
        RouteStopEvent(
          startTime: t.add(Duration(minutes: i * 60)),
          endTime: t.add(Duration(minutes: i * 60 + 5)),
          latitude: pos.latitude + i * 0.001,
          longitude: pos.longitude,
        ),
    ];
    final analysis = RouteEventAnalysisResult(
      stops: stops,
      overspeeds: const [],
      ignitions: const [],
      summary: RouteEventSummary(
        stopCount: stops.length,
        totalStopDuration: stops.fold(
          Duration.zero,
          (a, s) => a + s.duration,
        ),
        overspeedCount: 0,
        maxSpeed: 0,
        ignitionTransitionCount: 0,
      ),
      ignitionDataLikelyPresent: false,
    );
    var calls = 0;
    final resolver = RouteStopAddressResolver(
      geocoder: _CountingGeocoder(() => calls++),
    );
    var updates = 0;
    await prefetchStopAddressesSequential(
      resolver: resolver,
      intel: analysis,
      isStale: () => false,
      apply: (_) => updates++,
      maxGeocode: 20,
    );
    expect(calls, 20);
    expect(updates, 20);
  });
}

class _CountingGeocoder extends StopReverseGeocoder {
  _CountingGeocoder(this.onCall);
  final void Function() onCall;

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    onCall();
    return 'x';
  }
}
