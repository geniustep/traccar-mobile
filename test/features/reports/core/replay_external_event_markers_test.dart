import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_external_event.dart';
import 'package:elmogps/features/reports/core/replay_external_event_mapper.dart';
import 'package:elmogps/features/reports/presentation/widgets/replay_external_event_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));
  final t = DateTime.utc(2024, 6, 1, 10);

  RoutePoint routePoint(double lat, double lng) => RoutePoint(
        position: LatLng(lat, lng),
        speed: 40,
        course: 0,
        fixTime: t,
        ignition: true,
      );

  test('markers only for events with GPS', () {
    final events = [
      ReplayExternalEvent(
        id: 'al_1',
        source: ReplayExternalEventSource.backendAlerts,
        category: ReplayExternalEventCategory.alert,
        rawType: 'alarm',
        title: 'A',
        description: '',
        eventTime: t,
        latitude: 33.5,
        longitude: -7.6,
      ),
      ReplayExternalEvent(
        id: 'al_2',
        source: ReplayExternalEventSource.backendAlerts,
        category: ReplayExternalEventCategory.alert,
        rawType: 'alarm',
        title: 'B',
        description: '',
        eventTime: t.add(const Duration(minutes: 1)),
      ),
    ];
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [routePoint(33.5, -7.6)],
      l10n,
    );
    final markers = ReplayExternalEventMarkers.build(
      bundle: bundle,
      l10n: l10n,
      vehicleId: '7',
    );
    expect(markers.length, 1);
  });

  test('marker budget caps at maxMarkers', () {
    final events = List.generate(
      30,
      (i) => ReplayExternalEvent(
        id: 'e_$i',
        source: ReplayExternalEventSource.reportEvents,
        category: ReplayExternalEventCategory.alert,
        rawType: 'alarm',
        title: 'E',
        description: '',
        eventTime: t.add(Duration(seconds: i)),
        latitude: 33.5 + i * 0.001,
        longitude: -7.6,
      ),
    );
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [routePoint(33.5, -7.6)],
      l10n,
    );
    final markers = ReplayExternalEventMarkers.build(
      bundle: bundle,
      l10n: l10n,
      vehicleId: '7',
    );
    expect(markers.length, ReplayExternalEventMarkers.maxMarkers);
  });
}
