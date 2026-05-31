import 'package:elmogps/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Emulator QA for [MapAuditLogger] — device 11, Live Map + Vehicle Tracking.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFrames(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitSeconds(int seconds) async {
    await Future<void>.delayed(Duration(seconds: seconds));
  }

  Future<void> openVehicle11(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nav_dest_vehicles')));
    await pumpFrames(tester, frames: 50);
    final card = find.byKey(const Key('vehicle_card_11'));
    await tester.scrollUntilVisible(card, 400, scrollable: find.byType(Scrollable).first);
    await pumpFrames(tester, frames: 10);
    await tester.tap(card);
    await pumpFrames(tester, frames: 25);
  }

  testWidgets('MapAudit vehicle 11 live map and tracking', (tester) async {
    app.main();
    await tester.pump();

    var loggedIn = false;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byKey(const Key('nav_dest_map')).evaluate().isNotEmpty) {
        loggedIn = true;
        break;
      }
    }
    expect(loggedIn, isTrue, reason: 'Log in on the emulator before running this test');

    // --- Live Map + Follow ON/OFF ---
    await openVehicle11(tester);
    await tester.tap(find.byKey(const Key('vehicle_detail_view_on_map_btn')));
    await pumpFrames(tester, frames: 35);

    final followBtn = find.byKey(const Key('map_live_follow_btn'));
    expect(followBtn, findsOneWidget);
    await tester.tap(followBtn);
    await waitSeconds(60);
    await pumpFrames(tester, frames: 5);
    await tester.tap(followBtn);
    await waitSeconds(30);
    await pumpFrames(tester, frames: 5);

    // --- Vehicle Tracking + Follow ON/OFF ---
    await openVehicle11(tester);
    await tester.tap(find.byKey(const Key('vehicle_detail_track_btn')));
    await pumpFrames(tester, frames: 35);

    final trackFollow = find.byKey(const Key('tracking_follow_btn'));
    expect(trackFollow, findsOneWidget);
    await tester.tap(trackFollow);
    await waitSeconds(60);
    await pumpFrames(tester, frames: 5);
    await tester.tap(trackFollow);
    await waitSeconds(30);
    await pumpFrames(tester, frames: 5);

    // --- Dispose ---
    await tester.pageBack();
    await pumpFrames(tester, frames: 10);
    await tester.pageBack();
    await pumpFrames(tester, frames: 10);
    await tester.tap(find.byKey(const Key('nav_dest_map')));
    await pumpFrames(tester, frames: 5);
    await tester.pageBack();
    await pumpFrames(tester, frames: 10);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
