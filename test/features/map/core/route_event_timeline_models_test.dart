import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  RouteEventAnalysisResult synth({
    required List<RouteStopEvent> stops,
    required List<RouteOverspeedEvent> overspeeds,
    required List<RouteIgnitionEvent> ignitions,
    required bool ignitionLikely,
  }) =>
      RouteEventAnalysisResult(
        stops: stops,
        overspeeds: overspeeds,
        ignitions: ignitions,
        summary: RouteEventSummary(
          stopCount: stops.length,
          totalStopDuration: stops.fold<Duration>(
            Duration.zero,
            (a, s) => a + s.duration,
          ),
          overspeedCount: overspeeds.length,
          maxSpeed: 0,
          ignitionTransitionCount: ignitions.length,
        ),
        ignitionDataLikelyPresent: ignitionLikely,
      );

  group('routeEventTimelineValidPosition', () {
    test('false for (0,0)', () {
      expect(routeEventTimelineValidPosition(const LatLng(0, 0)), false);
    });

    test('false for near-zero coords', () {
      expect(routeEventTimelineValidPosition(const LatLng(1e-7, 0)), false);
      expect(routeEventTimelineValidPosition(const LatLng(0, 1e-7)), false);
    });

    test('true when one component exceeds epsilon', () {
      expect(routeEventTimelineValidPosition(const LatLng(1e-5, 0)), true);
      expect(routeEventTimelineValidPosition(const LatLng(0, 1e-5)), true);
    });
  });

  group('routeEventTimelineSelectionKey', () {
    test('same inputs produce same key', () {
      final t = DateTime.utc(2025, 1, 10, 8);
      final a = routeEventTimelineSelectionKey(
        kindCode: 's',
        anchorUtc: t,
        lat: 10.123456,
        lng: 20.987654,
      );
      final b = routeEventTimelineSelectionKey(
        kindCode: 's',
        anchorUtc: t,
        lat: 10.123456,
        lng: 20.987654,
      );
      expect(a, b);
      expect(a.startsWith('rint_s_'), true);
    });
  });

  group('buildRouteEventTimelineItems', () {
    test('merges stops, overspeed, ignition into one sorted list', () {
      final tBase = DateTime.utc(2025, 1, 10, 8);
      final stop = RouteStopEvent(
        startTime: tBase,
        endTime: tBase.add(const Duration(hours: 2)),
        latitude: 10.1,
        longitude: 20.2,
      );
      final over = RouteOverspeedEvent(
        time: tBase.add(const Duration(hours: 3)),
        speed: 95,
        latitude: 10.2,
        longitude: 20.3,
      );
      final ign = RouteIgnitionEvent(
        on: true,
        time: tBase.add(const Duration(hours: 1, minutes: 30)),
        latitude: 10.15,
        longitude: 20.25,
      );
      final analysis = synth(
        stops: [stop],
        overspeeds: [over],
        ignitions: [ign],
        ignitionLikely: true,
      );
      final items = buildRouteEventTimelineItems(analysis, l10n);
      expect(items, hasLength(3));
      expect(items.map((e) => e.kind).toSet(), equals(<RouteTimelineEntryKind>{
        RouteTimelineEntryKind.stop,
        RouteTimelineEntryKind.overspeed,
        RouteTimelineEntryKind.ignitionOn,
      }));

      expect(items.map((i) => i.sortTimeUtcMs),
          orderedEquals(<int>[
        stop.startTime.toUtc().millisecondsSinceEpoch,
        ign.time.toUtc().millisecondsSinceEpoch,
        over.time.toUtc().millisecondsSinceEpoch,
      ]));

      final byKind = <RouteTimelineEntryKind, RouteEventTimelineItem>{
        for (final x in items) x.kind: x,
      };
      expect(byKind[RouteTimelineEntryKind.stop]!.title, l10n.reportsStops);
      expect(
        byKind[RouteTimelineEntryKind.ignitionOn]!.title,
        l10n.ignitionOnLabel,
      );
      expect(
        byKind[RouteTimelineEntryKind.overspeed]!.title,
        l10n.overspeedEvents,
      );

      expect(byKind[RouteTimelineEntryKind.stop]!.stopStartTime, stop.startTime);
      expect(byKind[RouteTimelineEntryKind.stop]!.stopEndTime, stop.endTime);
      expect(byKind[RouteTimelineEntryKind.overspeed]!.overspeedMaxSpeedKmh, 95);

      expect(byKind[RouteTimelineEntryKind.stop]!.detailLine.contains(l10n.stopDurationLabel), true);
      expect(byKind[RouteTimelineEntryKind.overspeed]!.detailLine.contains('95'), true);

      expect(byKind[RouteTimelineEntryKind.stop]!.position.latitude, closeTo(10.1, 1e-9));
      expect(byKind[RouteTimelineEntryKind.overspeed]!.position.latitude, closeTo(10.2, 1e-9));

      final stopItem = routeEventTimelineItemForStop(stop, l10n);
      final overItem = routeEventTimelineItemForOverspeed(over, l10n);
      final ignItem = routeEventTimelineItemForIgnition(ign, l10n);
      expect(byKind[RouteTimelineEntryKind.stop]!.selectionKey, stopItem!.selectionKey);
      expect(byKind[RouteTimelineEntryKind.overspeed]!.selectionKey, overItem!.selectionKey);
      expect(byKind[RouteTimelineEntryKind.ignitionOn]!.selectionKey, ignItem!.selectionKey);
    });

    test('never adds ignition rows when ignitionDataLikelyPresent is false', () {
      final t = DateTime.utc(2025, 3, 1, 12);
      final fauxIgn = RouteIgnitionEvent(
        on: false,
        time: t,
        latitude: 5.5,
        longitude: 6.6,
      );
      final analysis = synth(
        stops: const [],
        overspeeds: const [],
        ignitions: [fauxIgn],
        ignitionLikely: false,
      );
      final items = buildRouteEventTimelineItems(analysis, l10n);
      expect(
        items.where((e) =>
            e.kind == RouteTimelineEntryKind.ignitionOn ||
            e.kind == RouteTimelineEntryKind.ignitionOff),
        isEmpty,
      );
    });

    test('drops rows with invalid position', () {
      final analysis = synth(
        stops: [
          RouteStopEvent(
            startTime: DateTime.utc(2025, 4, 1),
            endTime: DateTime.utc(2025, 4, 1, 0, 5),
            latitude: 0,
            longitude: 0,
          ),
        ],
        overspeeds: const [],
        ignitions: const [],
        ignitionLikely: false,
      );
      expect(buildRouteEventTimelineItems(analysis, l10n), isEmpty);
    });

    test('sorts descending input order into ascending timeline', () {
      final t0 = DateTime.utc(2025, 5, 1, 6);
      /// Deliberately build events out of chronological order in lists.
      final stops = [
        RouteStopEvent(
          startTime: t0.add(const Duration(minutes: 10)),
          endTime: t0.add(const Duration(minutes: 11)),
          latitude: 1,
          longitude: 2,
        ),
        RouteStopEvent(
          startTime: t0.add(const Duration(minutes: 5)),
          endTime: t0.add(const Duration(minutes: 6)),
          latitude: 1.001,
          longitude: 2.002,
        ),
      ];
      final analysis = synth(
        stops: stops,
        overspeeds: [
          RouteOverspeedEvent(
            time: t0,
            speed: 90,
            latitude: 1.1,
            longitude: 2.1,
          ),
        ],
        ignitions: const [],
        ignitionLikely: false,
      );
      final items = buildRouteEventTimelineItems(analysis, l10n);
      expect(
        items.map((e) => e.sortTimeUtcMs),
        orderedEquals(<int>[
          t0.toUtc().millisecondsSinceEpoch,
          t0.add(const Duration(minutes: 5)).toUtc().millisecondsSinceEpoch,
          t0.add(const Duration(minutes: 10)).toUtc().millisecondsSinceEpoch,
        ]),
      );
    });
  });
}

extension on RouteEventTimelineItem {
  int get sortTimeUtcMs => sortTime.toUtc().millisecondsSinceEpoch;
}
