import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_route_gap.dart';
import 'package:elmogps/features/reports/core/replay_timeline_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/core/route_point_fixtures.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
  });

  setUp(() {
    l10n = AppLocalizations(const Locale('en'));
  });

  final t0 = utc(2024, 6, 1, 8);

  RouteEventTimelineItem gapItem() => RouteEventTimelineItem(
        selectionKey: 'g1',
        kind: RouteTimelineEntryKind.dataGap,
        sortTime: t0.add(const Duration(minutes: 20)),
        position: const LatLng(36.85, 10.15),
        title: 'gap',
        primaryTimeLabel: 'x',
        detailLine: 'y',
        stopStartTime: t0.add(const Duration(minutes: 5)),
        stopEndTime: t0.add(const Duration(minutes: 20)),
      );

  group('replayTimelineSeekTimeForItem', () {
    test('dataGap يختار أول نقطة بعد الفجوة', () {
      final item = gapItem();
      expect(
        replayTimelineSeekTimeForItem(item),
        item.stopEndTime,
      );
    });

    test('stop يستخدم sortTime', () {
      final t = t0.add(const Duration(hours: 1));
      final item = RouteEventTimelineItem(
        selectionKey: 's',
        kind: RouteTimelineEntryKind.stop,
        sortTime: t,
        position: const LatLng(1, 2),
        title: 'S',
        primaryTimeLabel: 'a',
        detailLine: '',
      );
      expect(replayTimelineSeekTimeForItem(item), t);
    });
  });

  group('buildReplaySupplementalTimelineItems', () {
    test('يضم dataGap وبداية ونهاية بترتيب زمني', () {
      final pts = <RoutePoint>[
        testRoutePoint(const LatLng(36.8, 10.13), 40, t0),
        testRoutePoint(
          const LatLng(36.81, 10.13),
          40,
          t0.add(const Duration(minutes: 1)),
        ),
        testRoutePoint(
          const LatLng(36.9, 10.13),
          40,
          t0.add(const Duration(minutes: 25)),
        ),
        testRoutePoint(
          const LatLng(36.91, 10.13),
          40,
          t0.add(const Duration(minutes: 26)),
        ),
      ];
      final gaps = ReplayRouteGapDetector.detectGaps(pts);
      expect(gaps.length, 1);

      final rows = buildReplaySupplementalTimelineItems(
        allPoints: pts,
        gaps: gaps,
        l10n: l10n,
      );
      expect(rows.length, greaterThanOrEqualTo(3));
      expect(
        rows.any((e) => e.kind == RouteTimelineEntryKind.routeStart),
        isTrue,
      );
      expect(
        rows.any((e) => e.kind == RouteTimelineEntryKind.routeEnd),
        isTrue,
      );
      expect(
        rows.any((e) => e.kind == RouteTimelineEntryKind.dataGap),
        isTrue,
      );
      for (var i = 1; i < rows.length; i++) {
        expect(
          rows[i].sortTime.isAfter(rows[i - 1].sortTime) ||
              rows[i].sortTime.isAtSameMomentAs(rows[i - 1].sortTime),
          isTrue,
        );
      }
    });
  });

  group('routeEventTimelineFilter dataGaps', () {
    test('فلتر dataGaps يعرض الفجوات فقط', () {
      final items = [
        RouteEventTimelineItem(
          selectionKey: 's',
          kind: RouteTimelineEntryKind.stop,
          sortTime: t0,
          position: const LatLng(1, 2),
          title: 'S',
          primaryTimeLabel: 'a',
          detailLine: '',
        ),
        gapItem(),
      ];
      final f = routeEventTimelineItemsFiltered(
        items,
        RouteEventTimelineFilter.dataGaps,
      );
      expect(f.length, 1);
      expect(f.single.kind, RouteTimelineEntryKind.dataGap);
    });

    test('فلتر All يعرض كل الأنواع', () {
      final items = [
        RouteEventTimelineItem(
          selectionKey: 'rs',
          kind: RouteTimelineEntryKind.routeStart,
          sortTime: t0,
          position: const LatLng(1, 2),
          title: 'Start',
          primaryTimeLabel: 'a',
          detailLine: '',
        ),
        gapItem(),
        RouteEventTimelineItem(
          selectionKey: 'o',
          kind: RouteTimelineEntryKind.overspeed,
          sortTime: t0.add(const Duration(hours: 2)),
          position: const LatLng(1, 2),
          title: 'O',
          primaryTimeLabel: 'b',
          detailLine: '',
        ),
      ];
      expect(
        routeEventTimelineItemsFiltered(items, RouteEventTimelineFilter.all)
            .length,
        3,
      );
    });

    test('counts تتضمن dataGaps', () {
      final items = [gapItem(), gapItem()];
      final c = routeEventTimelineFilterCounts(items);
      expect(c.dataGaps, 2);
      expect(c.all, 2);
    });
  });

  group('replay compact timeline display', () {
    RouteEventTimelineItem alert() => RouteEventTimelineItem(
          selectionKey: 'a',
          kind: RouteTimelineEntryKind.externalEvent,
          sortTime: t0,
          position: const LatLng(1, 2),
          title: 'Alert',
          primaryTimeLabel: 'a',
          detailLine: '',
        );

    RouteEventTimelineItem stop() => RouteEventTimelineItem(
          selectionKey: 's',
          kind: RouteTimelineEntryKind.stop,
          sortTime: t0.add(const Duration(minutes: 1)),
          position: const LatLng(1, 2),
          title: 'Stop',
          primaryTimeLabel: 'b',
          detailLine: '',
        );

    test('replayShouldDeprioritizeAlerts when alerts dominate', () {
      const counts = RouteEventTimelineFilterCounts(
        all: 20,
        stops: 1,
        overspeed: 0,
        ignition: 0,
        dataGaps: 0,
        alerts: 18,
      );
      expect(replayShouldDeprioritizeAlerts(counts), isTrue);
      expect(
        replayShouldDeprioritizeAlerts(
          const RouteEventTimelineFilterCounts(
            all: 5,
            stops: 2,
            overspeed: 1,
            ignition: 0,
            dataGaps: 0,
            alerts: 2,
          ),
        ),
        isFalse,
      );
    });

    test('replayTimelineDisplayOrder puts route events before alerts', () {
      final ordered = replayTimelineDisplayOrder(
        [alert(), stop(), alert()],
        deprioritizeAlerts: true,
      );
      expect(ordered.first.kind, RouteTimelineEntryKind.stop);
      expect(
        ordered.where((e) => e.kind == RouteTimelineEntryKind.externalEvent),
        hasLength(2),
      );
    });
  });

  group('formatReplayCurrentPointDateTime', () {
    test('EN includes date and time with separator', () {
      final t = DateTime.utc(2026, 5, 16, 9, 6, 24);
      final label = formatReplayCurrentPointDateTime(t, const Locale('en'));
      expect(label, contains('2026'));
      expect(label, contains('·'));
      expect(label, contains('10:06:24'));
    });

    test('FR locale formats without crash', () {
      final t = DateTime.utc(2026, 5, 16, 9, 6, 24);
      final label = formatReplayCurrentPointDateTime(t, const Locale('fr'));
      expect(label, isNotEmpty);
      expect(label, contains('·'));
    });
  });

  group('formatRouteTimelineSummaryLine', () {
    test('ملخص يتضمن التوقفات والفجوات', () {
      final items = [
        RouteEventTimelineItem(
          selectionKey: 's',
          kind: RouteTimelineEntryKind.stop,
          sortTime: t0,
          position: const LatLng(1, 2),
          title: 'S',
          primaryTimeLabel: 'a',
          detailLine: '',
        ),
        gapItem(),
      ];
      final line = formatRouteTimelineSummaryLine(items, l10n);
      expect(line, isNotNull);
      expect(line!, contains('1'));
      expect(line, contains('stop'));
    });
  });
}
