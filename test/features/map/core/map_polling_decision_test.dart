import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/features/map/core/map_live_polling_fallback.dart';
import 'package:elmogps/features/map/core/map_polling_decision.dart';

void main() {
  final t0 = DateTime(2026, 5, 31, 12, 0, 0);

  group('MapPollingDecision', () {
    test('WebSocket connected + recent position → skip', () {
      final r = MapPollingDecision(
        socketConnected: true,
        lastLivePositionAt: t0.subtract(const Duration(seconds: 5)),
        now: t0,
      ).evaluate();

      expect(r.action, MapPollingAction.skip);
      expect(r.reason, 'recent_live_position');
    });

    test('WebSocket disconnected + no recent position → poll', () {
      final r = MapPollingDecision(
        socketConnected: false,
        lastLivePositionAt: null,
        now: t0,
      ).evaluate();

      expect(r.action, MapPollingAction.poll);
      expect(r.reason, 'websocket_disconnected');
    });

    test('WebSocket disconnected but recent positions → skip', () {
      final r = MapPollingDecision(
        socketConnected: false,
        lastLivePositionAt: t0.subtract(const Duration(seconds: 2)),
        now: t0,
      ).evaluate();

      expect(r.action, MapPollingAction.skip);
      expect(r.reason, 'recent_live_position');
    });

    test('WebSocket connected but silent >15s → poll live_silent', () {
      final r = MapPollingDecision(
        socketConnected: true,
        lastLivePositionAt: t0.subtract(const Duration(seconds: 20)),
        now: t0,
      ).evaluate();

      expect(r.action, MapPollingAction.poll);
      expect(r.reason, 'live_silent');
    });

    test('app resumed with stale lastAt → poll live_silent when connected', () {
      final r = MapPollingDecision(
        socketConnected: true,
        lastLivePositionAt: t0.subtract(const Duration(minutes: 5)),
        now: t0,
      ).evaluate();

      expect(r.action, MapPollingAction.poll);
      expect(r.reason, 'live_silent');
    });
  });

  group('MapLivePollingFallback', () {
    test('stop clears timer without requiring WidgetRef', () {
      final fallback = MapLivePollingFallback(
        screen: 'Test',
        onPoll: () {},
      );
      fallback.stop(log: false);
      fallback.stop(log: false);
    });
  });
}
