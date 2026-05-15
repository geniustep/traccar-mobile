import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/map_zoom_policy.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/map/core/route_polyline_builder.dart';

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

  group('routeEventTimelineItemFor*', () {
    test('stop matches row from buildRouteEventTimelineItems', () {
      final t = DateTime.utc(2025, 7, 1, 8);
      final stop = RouteStopEvent(
        startTime: t,
        endTime: t.add(const Duration(minutes: 20)),
        latitude: 11.1,
        longitude: 22.2,
      );
      final analysis = synth(
        stops: [stop],
        overspeeds: const [],
        ignitions: const [],
        ignitionLikely: false,
      );
      final single = routeEventTimelineItemForStop(stop, l10n);
      final fromList = buildRouteEventTimelineItems(analysis, l10n)
          .singleWhere((e) => e.kind == RouteTimelineEntryKind.stop);
      expect(single!.sortTime, fromList.sortTime);
      expect(single.position.latitude, fromList.position.latitude);
      expect(single.stopEndTime, fromList.stopEndTime);
      expect(single.selectionKey, fromList.selectionKey);
    });

    test('overspeed matches merged list row', () {
      final t = DateTime.utc(2025, 7, 1, 9);
      final ov = RouteOverspeedEvent(
        time: t,
        speed: 101,
        latitude: 11.2,
        longitude: 22.3,
      );
      final analysis = synth(
        stops: const [],
        overspeeds: [ov],
        ignitions: const [],
        ignitionLikely: false,
      );
      final single = routeEventTimelineItemForOverspeed(ov, l10n);
      final fromList = buildRouteEventTimelineItems(analysis, l10n).single;
      expect(single!.overspeedMaxSpeedKmh, fromList.overspeedMaxSpeedKmh);
      expect(fromList.kind, RouteTimelineEntryKind.overspeed);
      expect(single.selectionKey, fromList.selectionKey);
    });

    test('ignition matches merged list row', () {
      final t = DateTime.utc(2025, 7, 1, 10);
      final ig = RouteIgnitionEvent(
        on: true,
        time: t,
        latitude: 11.3,
        longitude: 22.4,
      );
      final analysis = synth(
        stops: const [],
        overspeeds: const [],
        ignitions: [ig],
        ignitionLikely: true,
      );
      final single = routeEventTimelineItemForIgnition(ig, l10n);
      final fromList = buildRouteEventTimelineItems(analysis, l10n).single;
      expect(single!.kind, fromList.kind);
      expect(single.sortTime, fromList.sortTime);
      expect(single.selectionKey, fromList.selectionKey);
    });
  });

  group('RouteIntelligenceMarkerBundle', () {
    test('itemByMarkerId covers every marker; onTap forwards correct item', () {
      final t0 = DateTime.utc(2025, 8, 1, 6);
      final analysis = synth(
        stops: [
          RouteStopEvent(
            startTime: t0,
            endTime: t0.add(const Duration(minutes: 30)),
            latitude: 1.0,
            longitude: 2.0,
          ),
        ],
        overspeeds: [
          RouteOverspeedEvent(
            time: t0.add(const Duration(hours: 1)),
            speed: 95,
            latitude: 1.01,
            longitude: 2.01,
          ),
        ],
        ignitions: [
          RouteIgnitionEvent(
            on: false,
            time: t0.add(const Duration(hours: 2)),
            latitude: 1.02,
            longitude: 2.02,
          ),
        ],
        ignitionLikely: true,
      );

      final received = <RouteEventTimelineItem>[];
      const vid = 'veh_x';
      final bundle = RoutePolylineBuilder.buildRouteIntelligenceMarkerBundle(
        analysis: analysis,
        l10n: l10n,
        policy: MapZoomPolicy.at(16),
        reportStyle: true,
        vehicleId: vid,
        onMarkerTap: received.add,
      );

      expect(bundle.markers.isNotEmpty, true);
      expect(bundle.markers.length, bundle.itemByMarkerId.length);

      for (final m in bundle.markers) {
        expect(bundle.itemByMarkerId[m.markerId.value], isNotNull);
      }

      for (final m in bundle.markers) {
        m.onTap?.call();
      }
      expect(received.length, bundle.markers.length);
      expect(received.map((e) => e.kind).toSet(), contains(RouteTimelineEntryKind.stop));
      expect(received.map((e) => e.kind).toSet(), contains(RouteTimelineEntryKind.overspeed));
      expect(received.map((e) => e.kind).toSet(), contains(RouteTimelineEntryKind.ignitionOff));
    });

    test('selectedEventKey raises stop marker zIndex', () {
      final t0 = DateTime.utc(2025, 8, 1, 6);
      final analysis = synth(
        stops: [
          RouteStopEvent(
            startTime: t0,
            endTime: t0.add(const Duration(minutes: 30)),
            latitude: 1.0,
            longitude: 2.0,
          ),
        ],
        overspeeds: const [],
        ignitions: const [],
        ignitionLikely: false,
      );
      final stopRow =
          buildRouteEventTimelineItems(analysis, l10n).single;
      const vid = 'veh_sel';

      final unselected = RoutePolylineBuilder.buildRouteIntelligenceMarkerBundle(
        analysis: analysis,
        l10n: l10n,
        policy: MapZoomPolicy.at(16),
        reportStyle: true,
        vehicleId: vid,
      );
      final stopMarkerUnsel = unselected.markers
          .firstWhere((m) => m.markerId.value.contains('_rint_stop_'));

      final selected = RoutePolylineBuilder.buildRouteIntelligenceMarkerBundle(
        analysis: analysis,
        l10n: l10n,
        policy: MapZoomPolicy.at(16),
        reportStyle: true,
        vehicleId: vid,
        selectedEventKey: stopRow.selectionKey,
      );
      final stopMarkerSel = selected.markers
          .firstWhere((m) => m.markerId.value.contains('_rint_stop_'));

      expect(stopMarkerUnsel.zIndexInt, 1);
      expect(stopMarkerSel.zIndexInt, 2);
    });

    test('empty analysis yields empty bundle', () {
      final b = RoutePolylineBuilder.buildRouteIntelligenceMarkerBundle(
        analysis: null,
        l10n: l10n,
        policy: MapZoomPolicy.at(16),
        reportStyle: true,
        vehicleId: 'v',
      );
      expect(b.markers, isEmpty);
      expect(b.itemByMarkerId, isEmpty);
    });
  });
}
