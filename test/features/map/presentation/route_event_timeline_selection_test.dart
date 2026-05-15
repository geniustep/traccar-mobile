import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_event_models.dart';
import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/map/presentation/widgets/route_event_timeline.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  RouteEventAnalysisResult minimalAnalysis() {
    final t = DateTime.utc(2025, 6, 1, 8);
    return RouteEventAnalysisResult(
      stops: [
        RouteStopEvent(
          startTime: t,
          endTime: t.add(const Duration(minutes: 5)),
          latitude: 10,
          longitude: 20,
        ),
      ],
      overspeeds: const [],
      ignitions: const [],
      summary: const RouteEventSummary(
        stopCount: 1,
        totalStopDuration: Duration(minutes: 5),
        overspeedCount: 0,
        maxSpeed: 0,
        ignitionTransitionCount: 0,
      ),
      ignitionDataLikelyPresent: false,
    );
  }

  int countSelectedDecorations(WidgetTester tester) {
    var n = 0;
    for (final el in tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer))) {
      final d = el.decoration;
      if (d is BoxDecoration && d.border != null) n++;
    }
    return n;
  }

  testWidgets('no selectedItemKey: no selection border on rows', (tester) async {
    final analysis = minimalAnalysis();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RouteEventTimeline(
            analysisKey: 'ak_test',
            analysis: analysis,
            compact: true,
            collapsedItemLimit: 8,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(countSelectedDecorations(tester), 0);
  });

  testWidgets('selectedItemKey matches one row decoration', (tester) async {
    final analysis = minimalAnalysis();
    final key =
        buildRouteEventTimelineItems(analysis, l10n).single.selectionKey;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RouteEventTimeline(
            analysisKey: 'ak_test',
            analysis: analysis,
            compact: true,
            collapsedItemLimit: 8,
            selectedItemKey: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(countSelectedDecorations(tester), 1);
  });
}
