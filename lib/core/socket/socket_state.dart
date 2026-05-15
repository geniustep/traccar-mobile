/// WebSocket connection state for ELMOGPS real-time stream.
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
  const SocketReconnecting({
    required this.attempt,
    required this.maxAttempts,
    this.nextRetrySeconds = 0,
  });
  final int attempt;
  final int maxAttempts;
  final int nextRetrySeconds;
}

/// Permanent failure — reconnect limit reached or auth error
final class SocketError extends SocketState {
  const SocketError(this.message);
  final String message;
}

/// Structured diagnostic snapshot for Debug Console.
class WebSocketDiagnostics {
  WebSocketDiagnostics();

  String endpoint = '';
  String authMode = 'none';
  bool cookiePresent = false;
  int? lastHttpStatus;
  int retryAttempt = 0;
  int maxRetries = 10;
  int nextRetrySeconds = 0;
  DateTime? lastConnectedAt;
  DateTime? lastErrorAt;
  String? lastError;
  String connectionState = 'disconnected';

  String get statusLabel {
    switch (connectionState) {
      case 'connected':
        return 'Connected';
      case 'connecting':
        return 'Connecting';
      case 'reconnecting':
        return 'Reconnecting';
      case 'failed':
        return 'Failed';
      case 'disconnected':
        return 'Disconnected';
      default:
        return 'Offline';
    }
  }

  String get structuredLog {
    final buf = StringBuffer('[WebSocket] ');
    if (lastHttpStatus != null) {
      buf.write('Failed: status=$lastHttpStatus ');
    }
    buf.write('endpoint=$endpoint ');
    buf.write('authMode=$authMode ');
    buf.write('cookiePresent=$cookiePresent ');
    buf.write('retry=$retryAttempt/$maxRetries ');
    if (nextRetrySeconds > 0) {
      buf.write('nextRetry=${nextRetrySeconds}s');
    }
    return buf.toString();
  }
}
