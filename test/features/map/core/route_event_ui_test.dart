import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_event_ui.dart';

void main() {
  final en = AppLocalizations(const Locale('en'));

  RouteEventAnalysisResult analysisUi({
    int stopCount = 0,
    Duration totalStopDuration = Duration.zero,
    int overspeedCount = 0,
    double maxSpeed = 0,
    int ignitionTransitionCount = 0,
    bool ignitionDataLikelyPresent = false,
  }) =>
      RouteEventAnalysisResult(
        stops: const [],
        overspeeds: const [],
        ignitions: const [],
        summary: RouteEventSummary(
          stopCount: stopCount,
          totalStopDuration: totalStopDuration,
          overspeedCount: overspeedCount,
          maxSpeed: maxSpeed,
          ignitionTransitionCount: ignitionTransitionCount,
        ),
        ignitionDataLikelyPresent: ignitionDataLikelyPresent,
      );

  group('formatRouteIntelSummaryLine', () {
    test('null analysis → null', () {
      expect(formatRouteIntelSummaryLine(null, en), isNull);
    });

    test('no countable activity → null (not empty string)', () {
      expect(
        formatRouteIntelSummaryLine(
          analysisUi(
            stopCount: 0,
            overspeedCount: 0,
            ignitionTransitionCount: 0,
            ignitionDataLikelyPresent: false,
          ),
          en,
        ),
        isNull,
      );
    });

    test('stops only: includes localized label + count (+ duration when non-zero)',
        () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(
          stopCount: 3,
          totalStopDuration: const Duration(minutes: 42),
          maxSpeed: 40,
        ),
        en,
      );
      expect(line, isNotNull);
      expect(line!.contains(en.reportsStops), isTrue);
      expect(line.contains('3'), isTrue);
      expect(line.contains('42') || line.contains(RegExp(r'\d+m')), isTrue);
    });

    test('overspeed only: localized label + count', () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(overspeedCount: 7, maxSpeed: 120),
        en,
      );
      expect(line, isNotNull);
      expect(line!.contains(en.overspeedEvents), isTrue);
      expect(line.contains('7'), isTrue);
      expect(line.contains(en.reportsStops), false);
    });

    test(
        'ignition likely + transitions > 0: includes Ign snippet with count',
        () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(
          ignitionTransitionCount: 4,
          ignitionDataLikelyPresent: true,
        ),
        en,
      );
      expect(line, isNotNull);
      expect(line!.contains('Ign:'), isTrue);
      expect(line.contains('4'), isTrue);
    });

    test(
        'ignition not likely: hides Ign even if summary transition count non-zero',
        () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(
          ignitionTransitionCount: 99,
          ignitionDataLikelyPresent: false,
        ),
        en,
      );
      expect(line, isNull);
    });

    test('ignition likely but zero transitions → no Ign segment', () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(ignitionDataLikelyPresent: true),
        en,
      );
      expect(line, isNull);
    });

    test('blend stops + overspeed + ignition joins with middle dot', () {
      final line = formatRouteIntelSummaryLine(
        analysisUi(
          stopCount: 1,
          totalStopDuration: const Duration(minutes: 10),
          overspeedCount: 2,
          ignitionTransitionCount: 3,
          ignitionDataLikelyPresent: true,
          maxSpeed: 90,
        ),
        en,
      );
      expect(line, isNotNull);
      expect(line!.split(' · ').length >= 3, isTrue);
      expect(line.contains(en.reportsStops), isTrue);
      expect(line.contains(en.overspeedEvents), isTrue);
      expect(line.contains('Ign:'), isTrue);
      expect(line.contains(RegExp('[123]')), isTrue);
    });
  });

  group('Route timeline l10n keys (four locales)', () {
    /// Keys must resolve to visible text in every supported dashboard language.
    const codes = ['en', 'fr', 'ar', 'es'];

    for (final code in codes) {
      test('non-empty for $code', () {
        final l10n = AppLocalizations(Locale(code));
        expect(l10n.routeEventsTimelineTitle.trim().isEmpty, false);
        expect(l10n.routeEventsNoneDetected.trim().isEmpty, false);
        expect(l10n.routeEventsSeeMore.trim().isEmpty, false);
        expect(l10n.routeEventsSeeLess.trim().isEmpty, false);
        expect(l10n.routeEventFilterAll.trim().isEmpty, false);
        expect(l10n.routeEventFilterStops.trim().isEmpty, false);
        expect(l10n.routeEventFilterOverspeed.trim().isEmpty, false);
        expect(l10n.routeEventFilterIgnition.trim().isEmpty, false);
        expect(l10n.routeEventsFilterNoMatches.trim().isEmpty, false);
        expect(l10n.routeEventDetailsTitle.trim().isEmpty, false);
        expect(l10n.routeEventDetailsStop.trim().isEmpty, false);
        expect(l10n.routeEventDetailsOverspeed.trim().isEmpty, false);
        expect(l10n.routeEventDetailsIgnitionOn.trim().isEmpty, false);
        expect(l10n.routeEventDetailsIgnitionOff.trim().isEmpty, false);
        expect(l10n.routeEventDetailsStartTime.trim().isEmpty, false);
        expect(l10n.routeEventDetailsEndTime.trim().isEmpty, false);
        expect(l10n.routeEventDetailsDuration.trim().isEmpty, false);
        expect(l10n.routeEventDetailsTime.trim().isEmpty, false);
        expect(l10n.routeEventDetailsMaxSpeed.trim().isEmpty, false);
        expect(l10n.routeEventDetailsLocation.trim().isEmpty, false);
        expect(l10n.routeEventDetailsRecenter.trim().isEmpty, false);
      });
    }
  });
}
