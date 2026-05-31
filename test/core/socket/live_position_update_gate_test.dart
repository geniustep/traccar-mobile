import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/models/traccar_position.dart';
import 'package:elmogps/core/socket/live_position_update_gate.dart';

TraccarPosition _pos(int deviceId, DateTime fixTime) => TraccarPosition(
      id: 1,
      deviceId: deviceId,
      latitude: 33.5,
      longitude: -7.6,
      fixTime: fixTime,
      serverTime: fixTime,
    );

void main() {
  group('LivePositionUpdateGate', () {
    test('accepts first position for device', () {
      final incoming = _pos(1, DateTime.utc(2026, 5, 16, 13, 23, 29));
      expect(
        LivePositionUpdateGate.shouldAcceptLiveUpdate(
          current: null,
          incoming: incoming,
        ),
        isTrue,
      );
    });

    test('accepts newer fixTime', () {
      final current = _pos(1, DateTime.utc(2026, 5, 16, 13, 17, 13));
      final incoming = _pos(1, DateTime.utc(2026, 5, 16, 13, 23, 29));
      expect(
        LivePositionUpdateGate.shouldAcceptLiveUpdate(
          current: current,
          incoming: incoming,
        ),
        isTrue,
      );
    });

    test('rejects older fixTime (buffered point)', () {
      final current = _pos(1, DateTime.utc(2026, 5, 16, 13, 23, 29));
      final incoming = _pos(1, DateTime.utc(2026, 5, 16, 13, 17, 13));
      expect(
        LivePositionUpdateGate.shouldAcceptLiveUpdate(
          current: current,
          incoming: incoming,
        ),
        isFalse,
      );
    });

    test('accepts same fixTime', () {
      final t = DateTime.utc(2026, 5, 16, 13, 23, 29);
      final current = _pos(1, t);
      final incoming = _pos(1, t);
      expect(
        LivePositionUpdateGate.shouldAcceptLiveUpdate(
          current: current,
          incoming: incoming,
        ),
        isTrue,
      );
    });
  });
}
