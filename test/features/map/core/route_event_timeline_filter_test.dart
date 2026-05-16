import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  RouteEventTimelineItem stop() => RouteEventTimelineItem(
        selectionKey: 's1',
        kind: RouteTimelineEntryKind.stop,
        sortTime: DateTime.utc(2025, 1, 1),
        position: const LatLng(1, 2),
        title: 'S',
        primaryTimeLabel: 'a',
        detailLine: '',
      );

  RouteEventTimelineItem os() => RouteEventTimelineItem(
        selectionKey: 'o1',
        kind: RouteTimelineEntryKind.overspeed,
        sortTime: DateTime.utc(2025, 1, 2),
        position: const LatLng(1, 2),
        title: 'O',
        primaryTimeLabel: 'b',
        detailLine: '',
      );

  RouteEventTimelineItem ignOn() => RouteEventTimelineItem(
        selectionKey: 'i1',
        kind: RouteTimelineEntryKind.ignitionOn,
        sortTime: DateTime.utc(2025, 1, 3),
        position: const LatLng(1, 2),
        title: 'I',
        primaryTimeLabel: 'c',
        detailLine: '',
      );

  RouteEventTimelineItem ignOff() => RouteEventTimelineItem(
        selectionKey: 'i0',
        kind: RouteTimelineEntryKind.ignitionOff,
        sortTime: DateTime.utc(2025, 1, 4),
        position: const LatLng(1, 2),
        title: 'X',
        primaryTimeLabel: 'd',
        detailLine: '',
      );

  RouteEventTimelineItem gap() => RouteEventTimelineItem(
        selectionKey: 'g1',
        kind: RouteTimelineEntryKind.dataGap,
        sortTime: DateTime.utc(2025, 1, 5),
        position: const LatLng(1, 2),
        title: 'G',
        primaryTimeLabel: 'e',
        detailLine: '',
      );

  test('filter all keeps all', () {
    final items = [stop(), os(), ignOn()];
    expect(
      routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.all).length,
      3,
    );
  });

  test('filter stops only', () {
    final items = [stop(), os(), ignOn()];
    final f =
        routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.stops);
    expect(f.length, 1);
    expect(f.single.kind, RouteTimelineEntryKind.stop);
  });

  test('filter overspeed only', () {
    final items = [stop(), os(), ignOff()];
    final f = routeEventTimelineItemsFiltered(
      items,
      RouteEventTimelineFilter.overspeed,
    );
    expect(f.length, 1);
    expect(f.single.kind, RouteTimelineEntryKind.overspeed);
  });

  test('filter ignition on and off', () {
    final items = [stop(), os(), ignOn(), ignOff()];
    final f =
        routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.ignition);
    expect(f.length, 2);
  });

  RouteEventTimelineItem routeStart() => RouteEventTimelineItem(
        selectionKey: 'rs',
        kind: RouteTimelineEntryKind.routeStart,
        sortTime: DateTime.utc(2025, 1, 0),
        position: const LatLng(1, 2),
        title: 'Start',
        primaryTimeLabel: 'a',
        detailLine: '',
      );

  RouteEventTimelineItem routeEnd() => RouteEventTimelineItem(
        selectionKey: 're',
        kind: RouteTimelineEntryKind.routeEnd,
        sortTime: DateTime.utc(2025, 1, 6),
        position: const LatLng(1, 2),
        title: 'End',
        primaryTimeLabel: 'b',
        detailLine: '',
      );

  RouteEventTimelineItem external() => RouteEventTimelineItem(
        selectionKey: 'x',
        kind: RouteTimelineEntryKind.externalEvent,
        sortTime: DateTime.utc(2025, 1, 7),
        position: const LatLng(1, 2),
        title: 'Alert',
        primaryTimeLabel: 'c',
        detailLine: '',
      );

  test('routeStart and routeEnd appear in all filter only', () {
    final items = [routeStart(), stop(), routeEnd()];
    expect(
      routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.all).length,
      3,
    );
    expect(
      routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.stops).length,
      1,
    );
    expect(
      routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.stops)
          .any((e) => e.kind == RouteTimelineEntryKind.routeStart),
      isFalse,
    );
  });

  test('filter alerts only externalEvent', () {
    final items = [external(), os(), routeStart()];
    final f = routeEventTimelineItemsFiltered(
      items,
      RouteEventTimelineFilter.alerts,
    );
    expect(f.length, 1);
    expect(f.single.kind, RouteTimelineEntryKind.externalEvent);
  });

  test('filter dataGaps only', () {
    final items = [stop(), gap(), os()];
    final f = routeEventTimelineItemsFiltered(
      items,
      RouteEventTimelineFilter.dataGaps,
    );
    expect(f.length, 1);
    expect(f.single.kind, RouteTimelineEntryKind.dataGap);
  });

  test('counts match kinds', () {
    final items = [stop(), stop(), os(), ignOn(), gap()];
    final c = routeEventTimelineFilterCounts(items);
    expect(c.all, 5);
    expect(c.stops, 2);
    expect(c.overspeed, 1);
    expect(c.ignition, 1);
    expect(c.dataGaps, 1);
  });

  test('selection key may be absent from filtered list — matcher consistent', () {
    final items = [stop(), os()];
    final filtered =
        routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.stops);
    final hiddenKey = 'o1';
    expect(filtered.any((e) => e.selectionKey == hiddenKey), false);
    expect(
      routeEventTimelineItemMatchesFilter(os(), RouteEventTimelineFilter.stops),
      false,
    );
  });

  test('buildRouteEventTimelineItems integrates with filters', () {
    final analysis = RouteEventAnalysisResult(
      stops: [
        RouteStopEvent(
          startTime: DateTime.utc(2025, 3, 1),
          endTime: DateTime.utc(2025, 3, 1, 0, 10),
          latitude: 10,
          longitude: 20,
        ),
      ],
      overspeeds: [
        RouteOverspeedEvent(
          time: DateTime.utc(2025, 3, 2),
          speed: 90,
          latitude: 10.1,
          longitude: 20.1,
        ),
      ],
      ignitions: const [],
      summary: const RouteEventSummary(
        stopCount: 1,
        totalStopDuration: Duration(minutes: 10),
        overspeedCount: 1,
        maxSpeed: 90,
        ignitionTransitionCount: 0,
      ),
      ignitionDataLikelyPresent: false,
    );
    final rows = buildRouteEventTimelineItems(analysis, l10n);
    expect(rows.length, 2);
    expect(
      routeEventTimelineItemsFiltered(rows, RouteEventTimelineFilter.stops).length,
      1,
    );
  });
}
