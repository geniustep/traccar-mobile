import '../models/traccar_position.dart';

/// Decides whether an incoming socket position should update live UI state.
///
/// Buffered/out-of-order fixes from the device must not move the live marker
/// backward; they may still be stored elsewhere (route history, replay API).
abstract final class LivePositionUpdateGate {
  LivePositionUpdateGate._();

  /// Returns true when [incoming] should replace [current] as the live fix.
  static bool shouldAcceptLiveUpdate({
    TraccarPosition? current,
    required TraccarPosition incoming,
  }) {
    if (current == null) return true;
    if (incoming.deviceId != current.deviceId) return true;
    return !incoming.fixTime.isBefore(current.fixTime);
  }
}
