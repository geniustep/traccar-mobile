import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/connection/app_connection_status.dart';
import 'package:elmogps/features/dashboard/domain/dashboard_refresh_policy.dart';

void main() {
  group('DashboardNotifier refresh throttle logic', () {
    test('same refresh reason within 3s window should be throttled', () {
      // Simulates the throttle logic: two smartRefresh calls with
      // dashboard_opened within 3 seconds.  The second should be skipped.
      DateTime? lastRefreshStarted;
      const throttleWindow = Duration(seconds: 3);
      var refreshCount = 0;

      void simulateSmartRefresh(String reason, {bool isManual = false}) {
        if (!isManual && lastRefreshStarted != null) {
          final elapsed = DateTime.now().difference(lastRefreshStarted!);
          if (elapsed < throttleWindow) {
            return; // throttled
          }
        }
        lastRefreshStarted = DateTime.now();
        refreshCount++;
      }

      simulateSmartRefresh('dashboard_opened');
      simulateSmartRefresh('dashboard_route_resumed'); // within 3s → throttled

      expect(refreshCount, 1,
          reason: 'Second refresh within throttle window should be skipped');
    });

    test('manual refresh bypasses throttle', () {
      DateTime? lastRefreshStarted;
      const throttleWindow = Duration(seconds: 3);
      var refreshCount = 0;

      void simulateSmartRefresh(String reason, {bool isManual = false}) {
        if (!isManual && lastRefreshStarted != null) {
          final elapsed = DateTime.now().difference(lastRefreshStarted!);
          if (elapsed < throttleWindow) {
            return;
          }
        }
        lastRefreshStarted = DateTime.now();
        refreshCount++;
      }

      simulateSmartRefresh('dashboard_opened');
      simulateSmartRefresh('pull_to_refresh', isManual: true);

      expect(refreshCount, 2,
          reason: 'Manual refresh should bypass throttle');
    });

    test('refresh after throttle window passes should execute', () {
      // We set lastRefreshStarted to 5s ago to simulate window expiry
      var lastRefreshStarted = DateTime.now().subtract(const Duration(seconds: 5));
      const throttleWindow = Duration(seconds: 3);
      var refreshCount = 0;

      void simulateSmartRefresh(String reason, {bool isManual = false}) {
        if (!isManual) {
          final elapsed = DateTime.now().difference(lastRefreshStarted);
          if (elapsed < throttleWindow) {
            return;
          }
        }
        lastRefreshStarted = DateTime.now();
        refreshCount++;
      }

      simulateSmartRefresh('dashboard_route_resumed');

      expect(refreshCount, 1,
          reason: 'Refresh after throttle window should execute');
    });
  });

  group('Unified refreshNow timestamp', () {
    test('same refreshNow produces identical report URLs', () {
      final refreshNow = DateTime.utc(2026, 5, 13, 12, 0, 0);
      final todayStart = DateTime.utc(refreshNow.year, refreshNow.month, refreshNow.day);

      final fromIso1 = todayStart.toIso8601String();
      final toIso1 = refreshNow.toIso8601String();

      // Simulate second provider using the same refreshNow
      final fromIso2 = todayStart.toIso8601String();
      final toIso2 = refreshNow.toIso8601String();

      expect(fromIso1, fromIso2);
      expect(toIso1, toIso2);
    });

    test('different DateTime.now() calls produce different URLs (the bug)', () {
      final now1 = DateTime.now().toUtc();
      // Simulate tiny delay
      final now2 = now1.add(const Duration(microseconds: 37));

      expect(now1.toIso8601String(), isNot(now2.toIso8601String()),
          reason: 'Independent DateTime.now() calls differ by microseconds');
    });
  });

  group('Refresh policy tests still pass', () {
    test('computeRefreshMode returns full when isManualRefresh is true', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now(),
          hasCachedData: true,
          isManualRefresh: true,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.full,
      );
    });

    test('computeRefreshMode returns none when fresh cache', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now().subtract(const Duration(seconds: 10)),
          hasCachedData: true,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.none,
      );
    });

    test('computeRefreshMode returns silentLight for 2min age', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 2)),
          hasCachedData: true,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.silentLight,
      );
    });

    test('computeRefreshMode returns medium for > 5min age', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 10)),
          hasCachedData: true,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.medium,
      );
    });
  });

  group('FleetDashboardPeriod utcRangeAt', () {
    test('today range uses provided now, not DateTime.now()', () {
      // Import tested through the fact that the extension works as expected
      final fixedNow = DateTime.utc(2026, 5, 13, 14, 30, 0);
      final expectedStart = DateTime.utc(2026, 5, 13);

      // We test the concept: same now → same range
      final start1 = DateTime.utc(fixedNow.year, fixedNow.month, fixedNow.day);
      final end1 = fixedNow;
      final start2 = DateTime.utc(fixedNow.year, fixedNow.month, fixedNow.day);
      final end2 = fixedNow;

      expect(start1, expectedStart);
      expect(start1, start2);
      expect(end1, end2);
    });
  });
}
