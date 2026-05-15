import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/connection/app_connection_status.dart';
import 'package:elmogps/features/dashboard/domain/dashboard_refresh_policy.dart';

void main() {
  group('computeRefreshMode', () {
    test('returns full when isManualRefresh is true', () {
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

    test('returns full when hasCachedData is false', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now(),
          hasCachedData: false,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.full,
      );
    });

    test('returns full when lastRefreshAt is null', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: null,
          hasCachedData: true,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.full,
      );
    });

    test('returns none when data is less than 30 seconds old', () {
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

    test('returns silentLight when data is between 30s and 5min old', () {
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

    test('returns medium when data is older than 5 minutes', () {
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

    test('returns silentLight when liveStatus is degraded and data is 1min old',
        () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 1)),
          hasCachedData: true,
          isManualRefresh: false,
          liveStatus: LiveSyncStatus.degraded,
        ),
        DashboardRefreshMode.silentLight,
      );
    });

    test('manual refresh always returns full regardless of freshness', () {
      expect(
        computeRefreshMode(
          lastRefreshAt: DateTime.now().subtract(const Duration(seconds: 5)),
          hasCachedData: true,
          isManualRefresh: true,
          liveStatus: LiveSyncStatus.connected,
        ),
        DashboardRefreshMode.full,
      );
    });
  });

  group('computeBackgroundResumeMode', () {
    test('returns none when background duration < 30s', () {
      expect(
        computeBackgroundResumeMode(
          backgroundDuration: const Duration(seconds: 15),
          hasCachedData: true,
        ),
        DashboardRefreshMode.none,
      );
    });

    test('returns full when no cached data', () {
      expect(
        computeBackgroundResumeMode(
          backgroundDuration: const Duration(minutes: 1),
          hasCachedData: false,
        ),
        DashboardRefreshMode.full,
      );
    });

    test('returns silentLight when background 30s-5min with cache', () {
      expect(
        computeBackgroundResumeMode(
          backgroundDuration: const Duration(minutes: 2),
          hasCachedData: true,
        ),
        DashboardRefreshMode.silentLight,
      );
    });

    test('returns medium when background 5-15min with cache', () {
      expect(
        computeBackgroundResumeMode(
          backgroundDuration: const Duration(minutes: 10),
          hasCachedData: true,
        ),
        DashboardRefreshMode.medium,
      );
    });

    test('returns full when background > 15min with cache', () {
      expect(
        computeBackgroundResumeMode(
          backgroundDuration: const Duration(minutes: 20),
          hasCachedData: true,
        ),
        DashboardRefreshMode.full,
      );
    });
  });

  group('route resume scenarios (same policy, reason: dashboard_route_resumed)', () {
    test('route resume with fresh data (< 30s) → none', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(seconds: 14)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.connected,
      );
      expect(mode, DashboardRefreshMode.none);
    });

    test('route resume with 1min-old data → silentLight', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(seconds: 82)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.connected,
      );
      expect(mode, DashboardRefreshMode.silentLight);
    });

    test('route resume with 6min-old data → medium', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 6)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.connected,
      );
      expect(mode, DashboardRefreshMode.medium);
    });

    test('route resume without cache → full', () {
      final mode = computeRefreshMode(
        lastRefreshAt: null,
        hasCachedData: false,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.connected,
      );
      expect(mode, DashboardRefreshMode.full);
    });

    test('route resume does not force full (isManual=false)', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(seconds: 5)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.connected,
      );
      expect(mode, isNot(DashboardRefreshMode.full));
    });

    test('route resume with degraded live and 2min data → silentLight', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 2)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.degraded,
      );
      expect(mode, DashboardRefreshMode.silentLight);
    });

    test('route resume with disconnected live and 8min data → medium', () {
      final mode = computeRefreshMode(
        lastRefreshAt: DateTime.now().subtract(const Duration(minutes: 8)),
        hasCachedData: true,
        isManualRefresh: false,
        liveStatus: LiveSyncStatus.disconnected,
      );
      expect(mode, DashboardRefreshMode.medium);
    });
  });
}
