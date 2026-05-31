import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/core/theme/app_theme.dart';
import 'package:elmogps/core/theme/theme_provider.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/map/presentation/providers/route_intelligence_thresholds_provider.dart';
import 'package:elmogps/features/reports/core/replay_external_event.dart';
import 'package:elmogps/features/reports/presentation/providers/replay_period_events_provider.dart';
import 'package:elmogps/features/reports/presentation/providers/reports_providers.dart';
import 'package:elmogps/features/reports/presentation/screens/replay_report_screen.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_replay_kpi.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_formatters.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_provider.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_state.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'replay_qa_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
  });

  final params = ReportFilterParams(
    vehicleId: 'qa-vehicle-1',
    from: DateTime.utc(2024, 6, 1),
    to: DateTime.utc(2024, 6, 1, 23, 59),
  );

  /// GoogleMap يمنع [pumpAndSettle] من الانتهاء — نضخ عدداً محدوداً من الإطارات.
  Future<void> settleUi(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// لقطة شاشة اختيارية لـ QA (تعمل على الجهاز/المحاكي مع integration test).
  Future<void> snap(String name) async {
    try {
      await IntegrationTestWidgetsFlutterBinding.instance.takeScreenshot(name);
    } catch (_) {
      // غير متاحة خارج تشغيل integration test على جهاز.
    }
  }

  Widget singleHarness({
    required Locale locale,
    required List<RoutePoint> points,
    List<ReplayExternalEvent> external = const [],
    Size size = const Size(360, 740),
  }) {
    return ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => _LightThemeNotifier()),
        reportRouteProvider(params).overrideWith((ref) async => points),
        replayPeriodExternalEventsProvider(params)
            .overrideWith((ref) async => external),
        routeIntelligenceThresholdsForVehicleProvider(params.vehicleId)
            .overrideWith((ref) => RouteIntelligenceThresholds.defaults),
      ],
      child: MaterialApp(
        locale: locale,
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
        theme: AppTheme.light(isArabic: locale.languageCode == 'ar'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ReplayReportScreen(
            params: params,
            vehicleName: 'QA Test',
          ),
        ),
      ),
    );
  }

  MultiVehicleReplayLoadState multiLoadState(List<MultiVehicleReplayTrack> tracks) {
    final timeline = MultiVehicleReplayTimelineBuilder.build(tracks);
    final summary = MultiReplayKpiCalculator.buildSummary(tracks);
    return MultiVehicleReplayLoadState(
      status: MultiVehicleReplayLoadStatus.success,
      tracks: tracks,
      timeline: timeline,
      selectedDate: DateTime.utc(2024, 6, 1),
      totalPoints: tracks.fold(0, (s, t) => s + t.allPoints.length),
      comparisonSummary: summary,
    );
  }

  MultiVehicleReplayTrack track(
    String id,
    List<RoutePoint> pts, {
    int colorIndex = 0,
    String? loadError,
  }) =>
      MultiVehicleReplayTrack(
        vehicleId: id,
        name: 'V-$id',
        colorIndex: colorIndex,
        allPoints: pts,
        mapPoints: pts,
        loadError: loadError,
      );

  Widget multiHarness({
    required Locale locale,
    required MultiVehicleReplayLoadState load,
    required List<String> vehicleIds,
    Size size = const Size(360, 740),
  }) {
    final day = MultiVehicleReplayFormatters.startOfDay(
      DateTime.utc(2024, 6, 1),
    );
    final request = MultiVehicleReplayRequest(
      vehicleIds: vehicleIds,
      date: day,
    );
    return ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => _LightThemeNotifier()),
        multiVehicleReplayLoaderProvider(request)
            .overrideWith((ref) async => load),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(isArabic: locale.languageCode == 'ar'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: MultiVehicleReplayScreen(
            vehicleIds: vehicleIds,
            initialDate: day,
          ),
        ),
      ),
    );
  }

  group('Replay R1–R10 — emulator QA', () {
    testWidgets('Single: normal route + controls (FR)', (tester) async {
      await tester.pumpWidget(
        singleHarness(locale: const Locale('fr'), points: qaNormalRoute()),
      );
      await settleUi(tester, frames: 50);
      expect(find.byType(ReplayReportScreen), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded), warnIfMissed: false);
      await settleUi(tester, frames: 8);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_rounded), warnIfMissed: false);
      await settleUi(tester);

      await tester.tap(find.byTooltip('Redémarrer'), warnIfMissed: false);
      await settleUi(tester);

      await tester.tap(find.byTooltip('Point suivant'), warnIfMissed: false);
      await settleUi(tester);
      await tester.tap(find.byTooltip('Point précédent'), warnIfMissed: false);
      await settleUi(tester);

      final slider = find.descendant(
        of: find.byType(ReplayReportScreen),
        matching: find.byType(Slider),
      );
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(80, 0),
            warnIfMissed: false);
        await settleUi(tester);
      }
    });

    testWidgets('Single: gap route (AR)', (tester) async {
      await tester.pumpWidget(
        singleHarness(locale: const Locale('ar'), points: qaRouteWithGap()),
      );
      await settleUi(tester, frames: 50);
      final l10n = AppLocalizations(const Locale('ar'));
      expect(find.byTooltip(l10n.replayStepNext), findsOneWidget);
    });

    testWidgets('Single: long route + speed x8', (tester) async {
      await tester.pumpWidget(
        singleHarness(
          locale: const Locale('en'),
          points: qaLongRoute(count: 150),
          size: const Size(320, 568),
        ),
      );
      await settleUi(tester, frames: 60);
      for (final label in ['x1', 'x2', 'x4', 'x8']) {
        final chip = find.text(label);
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip.first, warnIfMissed: false);
          await settleUi(tester, frames: 5);
        }
      }
      await tester.tap(find.byIcon(Icons.play_arrow_rounded), warnIfMissed: false);
      await settleUi(tester, frames: 20);
    });

    testWidgets('Single: snapshot sensors expand', (tester) async {
      await tester.pumpWidget(
        singleHarness(locale: const Locale('en'), points: qaNormalRoute()),
      );
      await settleUi(tester, frames: 50);

      final expand = find.byIcon(Icons.expand_more);
      if (expand.evaluate().isNotEmpty) {
        await tester.tap(expand.first, warnIfMissed: false);
        await settleUi(tester, frames: 20);
      }
    });

    testWidgets('Multi: 2 vehicles (FR)', (tester) async {
      final t0 = DateTime.utc(2024, 6, 1, 9);
      final pts = List.generate(
        20,
        (i) => RoutePoint(
          position: LatLng(33.5 + i * 0.001, -7.6),
          speed: 40,
          course: 0,
          fixTime: t0.add(Duration(minutes: i)),
          ignition: true,
        ),
      );
      final load = multiLoadState([
        track('1', pts),
        track(
          '2',
          pts
              .map(
                (p) => RoutePoint(
                  position: LatLng(
                    p.position.latitude + 0.01,
                    p.position.longitude,
                  ),
                  speed: p.speed,
                  course: p.course,
                  fixTime: p.fixTime,
                  ignition: p.ignition,
                ),
              )
              .toList(),
          colorIndex: 1,
        ),
      ]);
      await tester.pumpWidget(
        multiHarness(
          locale: const Locale('fr'),
          load: load,
          vehicleIds: const ['1', '2'],
        ),
      );
      await settleUi(tester, frames: 55);
      final l10n = AppLocalizations(const Locale('fr'));
      await tester.tap(find.byTooltip(l10n.multiReplayComparison),
          warnIfMissed: false);
      await settleUi(tester, frames: 25);
    });

    testWidgets('Multi: 3 + 5 vehicles, hide, speed colors', (tester) async {
      final t0 = DateTime.utc(2024, 6, 1, 10);
      RoutePoint p(int i, double lat) => RoutePoint(
            position: LatLng(lat, -7.6),
            speed: 50,
            course: 0,
            fixTime: t0.add(Duration(minutes: i)),
            ignition: true,
          );
      List<MultiVehicleReplayTrack> mk(int n) => List.generate(
            n,
            (i) => track(
              '$i',
              List.generate(15, (j) => p(j, 33.5 + i * 0.02 + j * 0.001)),
              colorIndex: i,
            ),
          );

      await tester.pumpWidget(
        multiHarness(
          locale: const Locale('en'),
          load: multiLoadState(mk(3)),
          vehicleIds: const ['0', '1', '2'],
        ),
      );
      await settleUi(tester, frames: 55);
      await tester.pumpWidget(
        multiHarness(
          locale: const Locale('en'),
          load: multiLoadState(mk(5)),
          vehicleIds: const ['0', '1', '2', '3', '4'],
        ),
      );
      await settleUi(tester, frames: 60);
      await snap('r_multi_5');

      final l10n = AppLocalizations(const Locale('en'));
      await tester.tap(find.byTooltip(l10n.multiReplaySpeedColors),
          warnIfMissed: false);
      await settleUi(tester);
      await tester.tap(find.byTooltip(l10n.multiReplayAutoFollow),
          warnIfMissed: false);
      await settleUi(tester);
    });

    testWidgets('Multi: vehicle without data (AR)', (tester) async {
      final t0 = DateTime.utc(2024, 6, 1, 11);
      final pts = [
        RoutePoint(
          position: const LatLng(33.5, -7.6),
          speed: 30,
          course: 0,
          fixTime: t0,
          ignition: true,
        ),
      ];
      final load = multiLoadState([
        track('a', pts),
        track('empty', const [], colorIndex: 1, loadError: 'no_data'),
      ]);
      await tester.pumpWidget(
        multiHarness(
          locale: const Locale('ar'),
          load: load,
          vehicleIds: const ['a', 'empty'],
        ),
      );
      await settleUi(tester, frames: 50);
    });
  });
}

class _LightThemeNotifier extends ThemeNotifier {
  _LightThemeNotifier() : super() {
    state = ThemeMode.light;
  }
}
