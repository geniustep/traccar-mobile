import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/alerts/domain/entities/alert.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_event_deduplication.dart';
import 'package:elmogps/features/reports/core/replay_external_event.dart';
import 'package:elmogps/features/reports/core/replay_external_event_mapper.dart';
import 'package:elmogps/features/reports/domain/entities/event_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = AppLocalizations(const Locale('en'));
  });

  RoutePoint routePoint(DateTime t, double lat, double lng) => RoutePoint(
        position: LatLng(lat, lng),
        speed: 40,
        course: 0,
        fixTime: t,
        ignition: true,
      );

  test('report overspeed maps to timeline overspeed kind', () {
    final t = DateTime.utc(2024, 6, 1, 10);
    final events = ReplayExternalEventMapper.fromEventReports([
      EventReport(
        id: 1,
        type: 'deviceOverspeed',
        eventTime: t,
        deviceId: 7,
        deviceName: 'V1',
        speedKmh: 120,
        attributes: const {'latitude': 33.5, 'longitude': -7.6},
      ),
    ]);
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [routePoint(t, 33.5, -7.6)],
      l10n,
    );
    expect(bundle.items, hasLength(1));
    expect(bundle.items.first.kind, RouteTimelineEntryKind.overspeed);
    expect(bundle.mapEligibleEvents, hasLength(1));
    expect(routeEventTimelineValidPosition(bundle.items.first.position), isTrue);
  });

  test('alert without coordinates uses nearest route point for timeline', () {
    final t0 = DateTime.utc(2024, 6, 1, 10);
    final t1 = DateTime.utc(2024, 6, 1, 10, 5);
    final events = ReplayExternalEventMapper.fromAlerts([
      AlertEntity(
        id: 'a1',
        type: 'alarm',
        severity: 'critical',
        title: 'SOS',
        description: 'Help',
        vehicleId: '7',
        vehicleName: 'V1',
        createdAt: t1,
        isRead: false,
        latitude: null,
        longitude: null,
        attributes: const {},
      ),
    ]);
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [
        routePoint(t0, 33.0, -7.0),
        routePoint(t1, 33.1, -7.1),
      ],
      l10n,
    );
    expect(bundle.items.first.kind, RouteTimelineEntryKind.externalEvent);
    expect(bundle.mapEligibleEvents, isEmpty);
    expect(
      bundle.items.first.position,
      const LatLng(33.1, -7.1),
    );
  });

  test('deduplication replaces local overspeed within 30s', () {
    final t = DateTime.utc(2024, 6, 1, 12);
    final local = RouteEventTimelineItem(
      selectionKey: 'local_o',
      kind: RouteTimelineEntryKind.overspeed,
      sortTime: t,
      position: const LatLng(1, 1),
      title: 'Local',
      primaryTimeLabel: '12:00',
      detailLine: 'local',
    );
    final external = RouteEventTimelineItem(
      selectionKey: 'ext_o',
      kind: RouteTimelineEntryKind.overspeed,
      sortTime: t.add(const Duration(seconds: 10)),
      position: const LatLng(2, 2),
      title: 'Backend',
      primaryTimeLabel: '12:00',
      detailLine: 'backend',
    );
    final merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: [local],
      external: [external],
    );
    expect(merged, hasLength(1));
    expect(merged.first.title, 'Backend');
  });

  test('merged timeline stays chronological', () {
    final t0 = DateTime.utc(2024, 1, 1, 8);
    final t1 = DateTime.utc(2024, 1, 1, 9);
    final t2 = DateTime.utc(2024, 1, 1, 10);
    RouteEventTimelineItem item(DateTime t, String key) =>
        RouteEventTimelineItem(
          selectionKey: key,
          kind: RouteTimelineEntryKind.externalEvent,
          sortTime: t,
          position: const LatLng(0, 0),
          title: key,
          primaryTimeLabel: '',
          detailLine: '',
        );
    final merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: [item(t1, 'b')],
      external: [item(t0, 'a'), item(t2, 'c')],
    );
    expect(
      merged.map((e) => e.selectionKey).toList(),
      ['a', 'b', 'c'],
    );
  });

  test('unknown event type maps to externalEvent', () {
    final events = ReplayExternalEventMapper.fromEventReports([
      EventReport(
        id: 2,
        type: 'customUnknownType',
        eventTime: DateTime.utc(2024, 6, 1, 11),
        deviceId: 1,
        deviceName: 'V',
        attributes: const {},
      ),
    ]);
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [routePoint(DateTime.utc(2024, 6, 1, 11), 33.5, -7.6)],
      l10n,
    );
    expect(bundle.items.single.kind, RouteTimelineEntryKind.externalEvent);
  });

  test('ignitionOn from report maps to ignitionOn kind', () {
    final t = DateTime.utc(2024, 6, 1, 10);
    final events = ReplayExternalEventMapper.fromEventReports([
      EventReport(
        id: 3,
        type: 'ignitionOn',
        eventTime: t,
        deviceId: 1,
        deviceName: 'V',
        attributes: const {'latitude': 33.5, 'longitude': -7.6},
      ),
    ]);
    final bundle = ReplayExternalEventMapper.toTimelineBundle(
      events,
      [routePoint(t, 33.5, -7.6)],
      l10n,
    );
    expect(bundle.items.single.kind, RouteTimelineEntryKind.ignitionOn);
  });

  test('alerts filter matches externalEvent kind only', () {
    final items = [
      RouteEventTimelineItem(
        selectionKey: 'x',
        kind: RouteTimelineEntryKind.externalEvent,
        sortTime: DateTime.utc(2024),
        position: const LatLng(1, 1),
        title: 'Alert',
        primaryTimeLabel: '',
        detailLine: '',
      ),
      RouteEventTimelineItem(
        selectionKey: 'o',
        kind: RouteTimelineEntryKind.overspeed,
        sortTime: DateTime.utc(2024),
        position: const LatLng(1, 1),
        title: 'Speed',
        primaryTimeLabel: '',
        detailLine: '',
      ),
    ];
    final filtered = routeEventTimelineItemsFiltered(
      items,
      RouteEventTimelineFilter.alerts,
    );
    expect(filtered, hasLength(1));
    expect(filtered.first.kind, RouteTimelineEntryKind.externalEvent);
  });
}
