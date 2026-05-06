import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/response/result.dart';
import '../../domain/entities/command_log_entry.dart';
import '../../domain/repositories/commands_repository.dart';
import '../datasources/commands_remote_datasource.dart';

/// Concrete implementation combining remote API calls with local
/// SharedPreferences persistence for command logs.
class CommandsRepositoryImpl implements CommandsRepository {
  CommandsRepositoryImpl({
    required CommandsRemoteDatasource remote,
    required SharedPreferences prefs,
  })  : _remote = remote,
        _prefs = prefs;

  final CommandsRemoteDatasource _remote;
  final SharedPreferences _prefs;

  /// Max log entries per device (prevents unbounded storage growth).
  static const _maxLogs = 200;

  static String _logsKey(int deviceId) => 'cmd_logs_v2_$deviceId';

  // ── Remote ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<String>, AppException>> getSupportedCommandTypes(
    int deviceId,
  ) =>
      _remote.fetchSupportedTypes(deviceId);

  @override
  Future<Result<void, AppException>> sendCommand({
    required int deviceId,
    required String commandType,
    Map<String, dynamic>? attributes,
  }) =>
      _remote.sendCommand(
        deviceId: deviceId,
        commandType: commandType,
        attributes: attributes,
      );

  // ── Local logs ────────────────────────────────────────────────────────────

  @override
  Future<List<CommandLogEntry>> getCommandLogs(int deviceId) async {
    final raw = _prefs.getString(_logsKey(deviceId));

    // Fallback: try legacy key (pre-v2 schema)
    if (raw == null) {
      return _migrateFromLegacy(deviceId);
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .whereType<Map<String, dynamic>>()
          .map(CommandLogEntry.fromJson)
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCommandLog(CommandLogEntry entry) async {
    final existing = await getCommandLogs(entry.deviceId);

    final idx = existing.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      existing[idx] = entry;
    } else {
      existing.insert(0, entry);
    }

    final trimmed = existing.take(_maxLogs).toList();

    await _prefs.setString(
      _logsKey(entry.deviceId),
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clearCommandLogs(int deviceId) async {
    await _prefs.remove(_logsKey(deviceId));
    // Also remove legacy key if present.
    await _prefs.remove('cmd_logs_$deviceId');
  }

  // ── Migration ─────────────────────────────────────────────────────────────

  /// Reads old-schema logs (key `cmd_logs_$deviceId`) and migrates them to
  /// the new schema. The legacy key is preserved so a downgrade still works.
  Future<List<CommandLogEntry>> _migrateFromLegacy(int deviceId) async {
    final legacyRaw = _prefs.getString('cmd_logs_$deviceId');
    if (legacyRaw == null) return [];
    try {
      final list = jsonDecode(legacyRaw) as List<dynamic>;
      final entries = list
          .whereType<Map<String, dynamic>>()
          .map(CommandLogEntry.fromJson) // fromJson handles legacy fields
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // Persist under new key so next read is fast.
      if (entries.isNotEmpty) {
        await _prefs.setString(
          _logsKey(deviceId),
          jsonEncode(entries.map((e) => e.toJson()).toList()),
        );
      }
      return entries;
    } catch (_) {
      return [];
    }
  }
}
