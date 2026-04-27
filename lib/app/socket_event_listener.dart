import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/traccar_event.dart';
import '../shared/providers/traccar_providers.dart';

/// Shows a short in-app notification when a new Traccar event arrives on the WebSocket.
class SocketEventListener extends ConsumerStatefulWidget {
  const SocketEventListener({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<SocketEventListener> createState() =>
      _SocketEventListenerState();
}

class _SocketEventListenerState extends ConsumerState<SocketEventListener> {
  static const _maxEventAge = Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    ref.listen<List<TraccarEvent>>(liveEventsProvider, (prev, next) {
      if (next.isEmpty) return;
      final e = next.first;
      final age = DateTime.now().difference(e.eventTime.toLocal());
      if (age > _maxEventAge) return;
      if (prev != null &&
          prev.isNotEmpty &&
          prev.first.id == e.id) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${e.eventType.displayName} · ${e.deviceId}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });

    return widget.child ?? const SizedBox.shrink();
  }
}
