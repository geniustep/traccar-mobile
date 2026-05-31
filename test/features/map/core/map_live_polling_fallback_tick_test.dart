import 'dart:async';

import 'package:elmogps/core/socket/socket_provider.dart';
import 'package:elmogps/core/socket/socket_state.dart';
import 'package:elmogps/core/socket/traccar_socket_service.dart';
import 'package:elmogps/core/storage/secure_storage_service.dart';
import 'package:elmogps/features/map/core/map_live_polling_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal socket stub for polling tick tests.
class _StubSocketService extends TraccarSocketService {
  _StubSocketService({required SocketState initial})
      : _state = initial,
        super(
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  SocketState _state;

  @override
  SocketState get currentState => _state;

  set state(SocketState value) => _state = value;

  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}
}

class _PollingHarness extends ConsumerStatefulWidget {
  const _PollingHarness({
    required this.fallback,
    required this.onPollCount,
  });

  final MapLivePollingFallback fallback;
  final ValueNotifier<int> onPollCount;

  @override
  ConsumerState<_PollingHarness> createState() => _PollingHarnessState();
}

class _PollingHarnessState extends ConsumerState<_PollingHarness> {
  @override
  void initState() {
    super.initState();
    widget.fallback.start(ref);
  }

  @override
  void dispose() {
    widget.fallback.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('tick does not poll when socket connected and recent position',
      (tester) async {
    final pollCount = ValueNotifier<int>(0);
    final stub = _StubSocketService(initial: const SocketConnected());
    final t0 = DateTime(2026, 5, 31, 12, 0, 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          traccarSocketServiceProvider.overrideWithValue(stub),
          lastLivePositionReceivedAtProvider
              .overrideWith((ref) => t0.subtract(const Duration(seconds: 3))),
        ],
        child: _PollingHarness(
          fallback: MapLivePollingFallback(
            screen: 'Test',
            onPoll: () => pollCount.value++,
            pollInterval: const Duration(milliseconds: 100),
            now: () => t0,
          ),
          onPollCount: pollCount,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(pollCount.value, 0);
  });

  testWidgets('tick polls when socket disconnected and no recent position',
      (tester) async {
    final pollCount = ValueNotifier<int>(0);
    final stub = _StubSocketService(initial: const SocketDisconnected());
    final t0 = DateTime(2026, 5, 31, 12, 0, 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          traccarSocketServiceProvider.overrideWithValue(stub),
          lastLivePositionReceivedAtProvider.overrideWith((ref) => null),
        ],
        child: _PollingHarness(
          fallback: MapLivePollingFallback(
            screen: 'Test',
            onPoll: () => pollCount.value++,
            pollInterval: const Duration(milliseconds: 100),
            now: () => t0,
          ),
          onPollCount: pollCount,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(pollCount.value, greaterThan(0));
  });

  testWidgets('tick polls live_silent when connected but no position for 20s',
      (tester) async {
    final pollCount = ValueNotifier<int>(0);
    final stub = _StubSocketService(initial: const SocketConnected());
    final t0 = DateTime(2026, 5, 31, 12, 0, 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          traccarSocketServiceProvider.overrideWithValue(stub),
          lastLivePositionReceivedAtProvider.overrideWith(
            (ref) => t0.subtract(const Duration(seconds: 20)),
          ),
        ],
        child: _PollingHarness(
          fallback: MapLivePollingFallback(
            screen: 'Test',
            onPoll: () => pollCount.value++,
            pollInterval: const Duration(milliseconds: 100),
            now: () => t0,
          ),
          onPollCount: pollCount,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(pollCount.value, greaterThan(0));
  });

  testWidgets('stop prevents further polls', (tester) async {
    final pollCount = ValueNotifier<int>(0);
    final stub = _StubSocketService(initial: const SocketDisconnected());
    final t0 = DateTime(2026, 5, 31, 12, 0, 0);
    final fallback = MapLivePollingFallback(
      screen: 'Test',
      onPoll: () => pollCount.value++,
      pollInterval: const Duration(milliseconds: 100),
      now: () => t0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          traccarSocketServiceProvider.overrideWithValue(stub),
          lastLivePositionReceivedAtProvider.overrideWith((ref) => null),
        ],
        child: _PollingHarness(
          fallback: fallback,
          onPollCount: pollCount,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    final countAfterStart = pollCount.value;
    expect(countAfterStart, greaterThan(0));

    fallback.stop();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pollCount.value, countAfterStart);
  });
}
