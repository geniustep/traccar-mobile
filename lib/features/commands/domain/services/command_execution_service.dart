import 'package:uuid/uuid.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/models/user_role.dart';
import '../entities/command_log_entry.dart';
import '../entities/device_command.dart';
import '../entities/device_installation_profile.dart';
import '../entities/resolved_device_command.dart';
import '../repositories/commands_repository.dart';
import 'command_validation_service.dart';

// ── Result types ─────────────────────────────────────────────────────────────

sealed class CommandResult {
  const CommandResult();
}

class CommandSuccess extends CommandResult {
  const CommandSuccess({required this.entry});
  final CommandLogEntry entry;
}

class CommandQueued extends CommandResult {
  const CommandQueued({required this.entry, required this.message});
  final CommandLogEntry entry;
  final String message;
}

class CommandBlockedBySafety extends CommandResult {
  const CommandBlockedBySafety({
    required this.status,
    required this.reason,
  });
  final CommandCapabilityStatus status;
  final String reason;
}

class CommandNeedsConfirmation extends CommandResult {
  const CommandNeedsConfirmation({
    required this.riskLevel,
    this.extraWarning,
  });
  final CommandRiskLevel riskLevel;
  final String? extraWarning;
}

class CommandFailed extends CommandResult {
  const CommandFailed({required this.entry, required this.friendlyMessage});
  final CommandLogEntry entry;
  final String friendlyMessage;
}

// ── Service ──────────────────────────────────────────────────────────────────

/// Orchestrates the full command execution pipeline:
/// validate → build payload → send API → log result.
class CommandExecutionService {
  CommandExecutionService({
    required CommandsRepository repository,
    CommandValidationService? validator,
  })  : _repo = repository,
        _validator = validator ?? const CommandValidationService();

  final CommandsRepository _repo;
  final CommandValidationService _validator;
  final _uuid = const Uuid();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<CommandResult> dispatch({
    required ResolvedDeviceCommand resolved,
    required int deviceId,
    required String deviceName,
    required UserRole userRole,
    required String userId,
    required String userName,
    required bool deviceOnline,
    double currentSpeedKmh = 0.0,
    bool userConfirmed = false,
    Map<String, dynamic>? providedParams,
    DeviceInstallationProfile? installation,
  }) async {
    AppLogger.commands('Command execution: key=${resolved.command.commandKey} deviceId=$deviceId risk=${resolved.command.riskLevel.name}');

    final install =
        installation ?? DeviceInstallationProfile.defaultFor(deviceId);

    // ── Validate ────────────────────────────────────────────────────────────
    final validation = _validator.validate(
      resolved: resolved,
      userRole: userRole,
      deviceOnline: deviceOnline,
      currentSpeedKmh: currentSpeedKmh,
      installation: install,
      userConfirmed: userConfirmed,
      providedParams: providedParams,
    );

    switch (validation) {
      case ValidationFailed(:final status, :final reason):
        AppLogger.commands('Command rejected by validation: key=${resolved.command.commandKey} status=$status');
        // Log every rejected attempt — even safety blocks — so audit trails
        // are complete. Status = rejected.
        final rejectedEntry = CommandLogEntry(
          id: _uuid.v4(),
          deviceId: deviceId,
          deviceName: deviceName,
          commandKey: resolved.command.commandKey,
          commandType: resolved.command.traccarType ?? 'custom',
          labelFr: resolved.command.labelFr,
          category: resolved.command.category,
          riskLevel: resolved.command.riskLevel,
          sendMethod: resolved.command.sendMethod,
          sentAt: DateTime.now(),
          status: CommandStatus.rejected,
          sentByUserId: userId,
          sentByUserName: userName,
          deviceOnlineAtExecution: deviceOnline,
          vehicleSpeedAtExecution: currentSpeedKmh,
          failureReason: reason,
          errorMessage: reason,
          attributes: providedParams ?? {},
        );
        await _repo.saveCommandLog(rejectedEntry);
        return CommandBlockedBySafety(status: status, reason: reason);

      case ValidationNeedsConfirmation(:final riskLevel, :final extraWarning):
        return CommandNeedsConfirmation(
          riskLevel: riskLevel,
          extraWarning: extraWarning,
        );

      case ValidationPassed(:final willBeQueued):
        AppLogger.commands('Command validation passed: key=${resolved.command.commandKey} queued=$willBeQueued');
        return _send(
          resolved: resolved,
          deviceId: deviceId,
          deviceName: deviceName,
          userId: userId,
          userName: userName,
          deviceOnline: deviceOnline,
          currentSpeedKmh: currentSpeedKmh,
          providedParams: providedParams ?? {},
          willBeQueued: willBeQueued,
        );
    }
  }

  // ── Logs ──────────────────────────────────────────────────────────────────

  Future<List<CommandLogEntry>> getLogs(int deviceId) =>
      _repo.getCommandLogs(deviceId);

  Future<void> clearLogs(int deviceId) => _repo.clearCommandLogs(deviceId);

  // ── Private ───────────────────────────────────────────────────────────────

  Future<CommandResult> _send({
    required ResolvedDeviceCommand resolved,
    required int deviceId,
    required String deviceName,
    required String userId,
    required String userName,
    required bool deviceOnline,
    required double currentSpeedKmh,
    required Map<String, dynamic> providedParams,
    required bool willBeQueued,
  }) async {
    final cmd = resolved.command;

    // Build attributes: merge defaults → provided params
    final attrs = <String, dynamic>{
      ...cmd.defaultAttributes,
      ...providedParams,
    };

    // For device-specific / custom commands: ensure 'data' is set
    if (cmd.mapping.isCustomSend && !attrs.containsKey('data')) {
      attrs['data'] = '';
    }

    // ── Create pending log entry ────────────────────────────────────────────
    final entry = CommandLogEntry(
      id: _uuid.v4(),
      deviceId: deviceId,
      deviceName: deviceName,
      commandKey: cmd.commandKey,
      commandType: cmd.traccarType ?? 'custom',
      labelFr: cmd.labelFr,
      category: cmd.category,
      riskLevel: cmd.riskLevel,
      sendMethod: cmd.sendMethod,
      sentAt: DateTime.now(),
      status: willBeQueued ? CommandStatus.queued : CommandStatus.pending,
      sentByUserId: userId,
      sentByUserName: userName,
      deviceOnlineAtExecution: deviceOnline,
      vehicleSpeedAtExecution: currentSpeedKmh,
      attributes: attrs,
    );
    await _repo.saveCommandLog(entry);

    // ── Send via Traccar API ────────────────────────────────────────────────
    final result = await _repo.sendCommand(
      deviceId: deviceId,
      commandType: cmd.traccarType ?? 'custom',
      attributes: attrs,
    );

    return result.when(
      success: (_) async {
        AppLogger.commands('Command API success: key=${cmd.commandKey} deviceId=$deviceId queued=$willBeQueued');
        final done = entry.copyWith(
          status: willBeQueued ? CommandStatus.queued : CommandStatus.success,
        );
        await _repo.saveCommandLog(done);

        if (willBeQueued) {
          return CommandQueued(
            entry: done,
            message: 'La commande a été mise en file d\'attente et sera '
                'exécutée dès la reconnexion de l\'appareil.',
          );
        }
        return CommandSuccess(entry: done);
      },
      failure: (ex) async {
        AppLogger.commandsError('Command API failed: key=${cmd.commandKey} deviceId=$deviceId');
        final friendly = _friendlyError(ex);
        final failed = entry.copyWith(
          status: CommandStatus.failed,
          errorMessage: friendly,
          failureReason: ex.message,
        );
        await _repo.saveCommandLog(failed);
        return CommandFailed(entry: failed, friendlyMessage: friendly);
      },
    );
  }

  /// Converts a raw [AppException] into a user-friendly French message.
  static String _friendlyError(AppException ex) {
    final msg = ex.message.toLowerCase();

    if (msg.contains('saved command not provided') ||
        msg.contains('saved command')) {
      return 'Aucune commande sauvegardée trouvée pour cet appareil. '
          'Un technicien doit d\'abord la configurer dans le tableau de bord.';
    }
    if (msg.contains('unsupported') || msg.contains('not supported')) {
      return 'Cette commande n\'est pas supportée par cet appareil.';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'La connexion a expiré. Vérifiez votre connexion et réessayez.';
    }
    if (msg.contains('unauthorized') || msg.contains('401')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (msg.contains('forbidden') || msg.contains('403')) {
      return 'Vous n\'avez pas les droits pour cette opération.';
    }
    if (msg.contains('no connection') ||
        msg.contains('network') ||
        msg.contains('socket')) {
      return 'Aucune connexion Internet. Vérifiez votre réseau et réessayez.';
    }
    if (msg.contains('bad request') || msg.contains('400')) {
      return 'La commande n\'a pas pu être traitée. '
          'Vérifiez les paramètres et réessayez.';
    }
    if (msg.contains('server error') ||
        msg.contains('500') ||
        msg.contains('503')) {
      return 'Erreur serveur. Veuillez réessayer dans quelques instants.';
    }

    return 'Une erreur inattendue s\'est produite. Réessayez ou contactez '
        'le support technique.';
  }
}
