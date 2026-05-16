import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/core/theme/app_theme.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_controller.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_timeline.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

RoutePoint _pt(DateTime t, {double lat = 33.5}) => RoutePoint(
      position: LatLng(lat, -7.6),
      speed: 42,
      course: 90,
      fixTime: t,
      ignition: true,
    );

MultiVehicleReplayTrack _track(
  String id,
  List<RoutePoint> points, {
  int colorIndex = 0,
  String? name,
}) =>
    MultiVehicleReplayTrack(
      vehicleId: id,
      name: name ?? id,
      colorIndex: colorIndex,
      allPoints: points,
      mapPoints: points,
    );

Widget _legendHarness({
  required Locale locale,
  required List<MultiVehicleReplayTrack> tracks,
  required MultiVehicleReplayPlaybackState playback,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light(isArabic: locale.languageCode == 'ar'),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(360, 740)),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MultiVehicleReplayLegend(
            tracks: tracks,
            playback: playback,
            timeline: playback.timeline,
            onVisibility: (_, __) {},
            onActiveVehicle: (_) {},
            labelsEnabled: false,
            onToggleLabels: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  final t0 = DateTime.utc(2024, 6, 1, 9);

  MultiVehicleReplayPlaybackState playbackFor(List<MultiVehicleReplayTrack> tracks) {
    final timeline = MultiVehicleReplayTimelineBuilder.build(tracks);
    return MultiVehicleReplayPlaybackState(
      timeline: timeline,
      currentIndex: 0,
      activeVehicleId: tracks.first.vehicleId,
      visibility: {for (final t in tracks) t.vehicleId: true},
    );
  }

  Future<void> pumpLegend(
    WidgetTester tester, {
    required Locale locale,
    required List<MultiVehicleReplayTrack> tracks,
    String? activeId,
    Map<String, bool>? visibility,
  }) async {
    var playback = playbackFor(tracks);
    if (activeId != null || visibility != null) {
      playback = MultiVehicleReplayPlaybackState(
        timeline: playback.timeline,
        currentIndex: playback.currentIndex,
        activeVehicleId: activeId ?? playback.activeVehicleId,
        visibility: visibility ?? playback.visibility,
      );
    }
    await tester.pumpWidget(
      _legendHarness(locale: locale, tracks: tracks, playback: playback),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  group('MultiVehicleReplayLegend layout', () {
    testWidgets('FR active vehicle — no overflow on 360×740', (tester) async {
      final tracks = [
        _track(
          '9',
          List.generate(5, (i) => _pt(t0.add(Duration(minutes: i)))),
          name: 'BOXER avec nom très long pour test',
        ),
        _track('11', const [], colorIndex: 1, name: 'clio abdenbi'),
      ];
      await pumpLegend(
        tester,
        locale: const Locale('fr'),
        tracks: tracks,
        activeId: '9',
      );
    });

    testWidgets('AR RTL no-data vehicle — no overflow', (tester) async {
      final tracks = [
        _track('a', [_pt(t0)]),
        _track('empty', const [], colorIndex: 1),
      ];
      await pumpLegend(
        tester,
        locale: const Locale('ar'),
        tracks: tracks,
        visibility: {'a': true, 'empty': true},
      );
    });

    testWidgets('EN hidden vehicle — no overflow', (tester) async {
      final tracks = [
        _track('1', List.generate(3, (i) => _pt(t0.add(Duration(minutes: i))))),
        _track('2', List.generate(3, (i) => _pt(t0.add(Duration(minutes: i)), lat: 34)),
            colorIndex: 1),
      ];
      await pumpLegend(
        tester,
        locale: const Locale('en'),
        tracks: tracks,
        visibility: {'1': true, '2': false},
        activeId: '1',
      );
    });
  });
}
