import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/map/core/route_event_timeline_sheet_details.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  group('buildRouteEventSheetPresentation', () {
    test('stop: includes start, end, duration, location', () {
      final start = DateTime.utc(2025, 6, 1, 8);
      final end = DateTime.utc(2025, 6, 1, 8, 30);
      final item = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 's',
          anchorUtc: start,
          lat: 33.5731,
          lng: -7.5898,
        ),
        kind: RouteTimelineEntryKind.stop,
        sortTime: start,
        position: const LatLng(33.5731, -7.5898),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
        stopStartTime: start,
        stopEndTime: end,
      );
      final p = buildRouteEventSheetPresentation(item, l10n);
      expect(p.headline, l10n.routeEventDetailsStop);
      expect(p.hasValidMapPosition, true);
      expect(p.showRecenterAction, true);
      expect(p.addressLine, isNull);
      final labels = p.rows.map((e) => e.label).toList();
      expect(labels, contains(l10n.routeEventDetailsStartTime));
      expect(labels, contains(l10n.routeEventDetailsEndTime));
      expect(labels, contains(l10n.routeEventDetailsDuration));
      expect(labels, contains(l10n.routeEventDetailsLocation));
    });

    test('stop: exposes optional address when provided', () {
      final t = DateTime.utc(2025, 6, 1, 8);
      final item = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 's',
          anchorUtc: t,
          lat: 1,
          lng: 2,
        ),
        kind: RouteTimelineEntryKind.stop,
        sortTime: t,
        position: const LatLng(1, 2),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
        stopStartTime: t,
        stopEndTime: t.add(const Duration(minutes: 1)),
        stopAddress: 'Central zone',
      );
      final p = buildRouteEventSheetPresentation(item, l10n);
      expect(p.addressLine, 'Central zone');
    });

    test('overspeed: time, max speed, location', () {
      final t = DateTime.utc(2025, 6, 1, 10);
      final item = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'o',
          anchorUtc: t,
          lat: 10,
          lng: 20,
        ),
        kind: RouteTimelineEntryKind.overspeed,
        sortTime: t,
        position: const LatLng(10, 20),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
        overspeedMaxSpeedKmh: 102,
      );
      final p = buildRouteEventSheetPresentation(item, l10n);
      expect(p.headline, l10n.routeEventDetailsOverspeed);
      expect(
        p.rows.any(
          (r) =>
              r.label == l10n.routeEventDetailsMaxSpeed &&
              r.value.contains('102'),
        ),
        true,
      );
      expect(p.rows.any((r) => r.label == l10n.routeEventDetailsLocation), true);
    });

    test('ignition on and off headlines', () {
      final t = DateTime.utc(2025, 6, 1, 12);
      final onItem = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'i1',
          anchorUtc: t,
          lat: 3,
          lng: 4,
        ),
        kind: RouteTimelineEntryKind.ignitionOn,
        sortTime: t,
        position: const LatLng(3, 4),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
      );
      expect(
        buildRouteEventSheetPresentation(onItem, l10n).headline,
        l10n.routeEventDetailsIgnitionOn,
      );
      final offItem = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'i0',
          anchorUtc: t,
          lat: 3,
          lng: 4,
        ),
        kind: RouteTimelineEntryKind.ignitionOff,
        sortTime: t,
        position: const LatLng(3, 4),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
      );
      expect(
        buildRouteEventSheetPresentation(offItem, l10n).headline,
        l10n.routeEventDetailsIgnitionOff,
      );
    });

    test('invalid map position: no location row, no recenter', () {
      final t = DateTime.utc(2025, 6, 1, 12);
      final item = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'o',
          anchorUtc: t,
          lat: 0,
          lng: 0,
        ),
        kind: RouteTimelineEntryKind.overspeed,
        sortTime: t,
        position: const LatLng(0, 0),
        title: 'x',
        primaryTimeLabel: 'x',
        detailLine: 'x',
        overspeedMaxSpeedKmh: 90,
      );
      final p = buildRouteEventSheetPresentation(item, l10n);
      expect(p.hasValidMapPosition, false);
      expect(p.showRecenterAction, false);
      expect(
        p.rows.any((r) => r.label == l10n.routeEventDetailsLocation),
        false,
      );
    });
  });

  group('formatRouteTimelineStopDurationCompact', () {
    test('hours and minutes', () {
      expect(
        formatRouteTimelineStopDurationCompact(
          const Duration(hours: 2, minutes: 3),
        ),
        '2h 3m',
      );
    });

    test('minutes only', () {
      expect(
        formatRouteTimelineStopDurationCompact(const Duration(minutes: 45)),
        '45m',
      );
    });
  });
}
