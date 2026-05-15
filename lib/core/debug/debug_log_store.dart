import 'package:flutter/foundation.dart';

import 'debug_log_entry.dart';

/// In-memory ring buffer of recent log lines (debug builds only).
final class DebugLogStore extends ChangeNotifier {
  DebugLogStore._();
  static final DebugLogStore instance = DebugLogStore._();

  static const int maxEntries = 500;
  static const int maxApiEntries = 50;
  static const int maxSlowRequests = 30;

  final List<DebugLogEntry> _entries = [];
  final List<DebugLogEntry> _apiEntries = [];
  final List<DebugLogEntry> _slowRequests = [];
  final List<String> _navigationHistory = [];

  List<DebugLogEntry> get entries => List.unmodifiable(_entries);
  List<DebugLogEntry> get apiEntries => List.unmodifiable(_apiEntries);
  List<DebugLogEntry> get slowRequests => List.unmodifiable(_slowRequests);

  List<DebugLogEntry> get comparisonEntries => _entries
      .where((e) => e.tag == 'Comparison')
      .toList(growable: false);
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  String? currentRoute;
  String? previousRoute;

  // ── FCM state ──
  String fcmPermissionStatus = 'unknown';
  bool fcmTokenRegistered = false;
  String? fcmLastMessageType;
  String? fcmLastAlertId;
  String? fcmLastRefreshResult;

  // ── Alerts state ──
  int alertsLoadedCount = 0;
  int alertsUnreadCount = 0;
  String? alertsLastRefreshSource;
  int? alertsLastRefreshDurationMs;
  String? alertsLastFcmAlertId;

  // ── Dashboard perf ──
  int? dashboardRefreshDurationMs;
  int duplicateRequestWarnings = 0;

  void add(DebugLogEntry entry) {
    if (!kDebugMode) return;
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }

    if (entry.category == DebugLogCategory.api) {
      _apiEntries.add(entry);
      while (_apiEntries.length > maxApiEntries) {
        _apiEntries.removeAt(0);
      }

      if (entry.durationMs != null && entry.durationMs! > 1000) {
        _slowRequests.add(entry);
        while (_slowRequests.length > maxSlowRequests) {
          _slowRequests.removeAt(0);
        }
      }
    }

    if (entry.tag == 'Comparison') {
      if (entry.durationMs != null && entry.durationMs! > 1000) {
        _slowRequests.add(entry);
        while (_slowRequests.length > maxSlowRequests) {
          _slowRequests.removeAt(0);
        }
      }
    }

    if (entry.category == DebugLogCategory.navigation) {
      final route = _extractRoute(entry.message);
      if (route != null) {
        previousRoute = currentRoute;
        currentRoute = route;
        _navigationHistory.insert(0, '${_formatTime(entry.at)} $route');
        if (_navigationHistory.length > 10) {
          _navigationHistory.removeLast();
        }
      }
    }

    notifyListeners();
  }

  void clear() {
    if (!kDebugMode) return;
    _entries.clear();
    _apiEntries.clear();
    _slowRequests.clear();
    _navigationHistory.clear();
    currentRoute = null;
    previousRoute = null;
    notifyListeners();
  }

  String? _extractRoute(String message) {
    final match = RegExp(r'Entered:\s*(\S+)').firstMatch(message);
    return match?.group(1);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
