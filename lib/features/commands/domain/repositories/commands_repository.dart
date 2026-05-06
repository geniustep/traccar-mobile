import '../../../../core/error/app_exception.dart';
import '../../../../core/response/result.dart';
import '../entities/command_log_entry.dart';

/// Contract for the commands feature data layer.
abstract class CommandsRepository {
  /// Returns command type strings supported by [deviceId] from Traccar API.
  ///
  /// An empty list means no info available — callers should allow all commands
  /// and let the API reject unsupported ones gracefully.
  Future<Result<List<String>, AppException>> getSupportedCommandTypes(
    int deviceId,
  );

  /// Sends a command via `POST /commands/send`.
  ///
  /// Returns [Result.success] on HTTP 200/202, [Result.failure] otherwise.
  Future<Result<void, AppException>> sendCommand({
    required int deviceId,
    required String commandType,
    Map<String, dynamic>? attributes,
  });

  // ── Command history ───────────────────────────────────────────────────────

  Future<List<CommandLogEntry>> getCommandLogs(int deviceId);

  Future<void> saveCommandLog(CommandLogEntry entry);

  Future<void> clearCommandLogs(int deviceId);
}
