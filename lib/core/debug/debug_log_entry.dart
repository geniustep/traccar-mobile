/// One line stored by [DebugLogStore] for the in-app Debug Console.
class DebugLogEntry {
  const DebugLogEntry({
    required this.at,
    required this.tag,
    required this.message,
    this.isError = false,
    this.durationMs,
    this.source,
    this.category = DebugLogCategory.general,
  });

  final DateTime at;
  final String tag;
  final String message;
  final bool isError;
  final int? durationMs;
  final String? source;
  final DebugLogCategory category;

  String get line {
    final t =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}';
    return '[$t][$tag] $message';
  }

  /// Performance classification based on duration.
  PerformanceLevel? get performanceLevel {
    if (durationMs == null) return null;
    if (durationMs! > 8000) return PerformanceLevel.criticalSlow;
    if (durationMs! > 3000) return PerformanceLevel.slow;
    if (durationMs! > 1000) return PerformanceLevel.medium;
    return PerformanceLevel.normal;
  }
}

enum DebugLogCategory {
  general,
  navigation,
  api,
  websocket,
  fcm,
  alerts,
  dashboard,
  performance,
}

enum PerformanceLevel {
  normal,
  medium,
  slow,
  criticalSlow;

  String get label => switch (this) {
        normal => 'normal',
        medium => 'medium',
        slow => 'slow',
        criticalSlow => 'critical slow',
      };
}
