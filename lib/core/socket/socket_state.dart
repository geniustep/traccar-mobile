/// WebSocket connection state for Traccar real-time stream.
sealed class SocketState {
  const SocketState();
}

/// Not yet connected (initial state)
final class SocketDisconnected extends SocketState {
  const SocketDisconnected();
}

/// Connection attempt in progress
final class SocketConnecting extends SocketState {
  const SocketConnecting();
}

/// Active, healthy connection
final class SocketConnected extends SocketState {
  const SocketConnected();
}

/// Temporary disconnection — automatic reconnect scheduled
final class SocketReconnecting extends SocketState {
  const SocketReconnecting({required this.attempt, required this.maxAttempts});
  final int attempt;
  final int maxAttempts;
}

/// Permanent failure — reconnect limit reached or auth error
final class SocketError extends SocketState {
  const SocketError(this.message);
  final String message;
}
