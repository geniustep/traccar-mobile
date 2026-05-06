import '../../../../core/models/user_role.dart';
import '../entities/device_command.dart';
import '../entities/device_installation_profile.dart';
import '../entities/resolved_device_command.dart';

/// Result of a pre-execution validation pass.
sealed class ValidationResult {
  const ValidationResult();
}

/// All checks passed — the command may be executed.
class ValidationPassed extends ValidationResult {
  const ValidationPassed({this.willBeQueued = false});

  /// True when the device is offline and the command will be queued.
  final bool willBeQueued;
}

/// A check failed — the command must not be executed.
class ValidationFailed extends ValidationResult {
  const ValidationFailed({
    required this.status,
    required this.reason,
  });

  final CommandCapabilityStatus status;
  final String reason;
}

/// The command requires user confirmation before proceeding.
class ValidationNeedsConfirmation extends ValidationResult {
  const ValidationNeedsConfirmation({
    required this.riskLevel,
    this.extraWarning,
  });

  final CommandRiskLevel riskLevel;
  final String? extraWarning;
}

/// Validates a [ResolvedDeviceCommand] just before execution.
///
/// Called from [CommandExecutionService.dispatch] after the user has
/// selected the command but before any API call is made.
class CommandValidationService {
  const CommandValidationService();

  /// Runs all validation checks in priority order.
  ///
  /// Returns the first failing/warning result, or [ValidationPassed].
  ValidationResult validate({
    required ResolvedDeviceCommand resolved,
    required UserRole userRole,
    required bool deviceOnline,
    required double currentSpeedKmh,
    required DeviceInstallationProfile installation,
    required bool userConfirmed,
    Map<String, dynamic>? providedParams,
  }) {
    final cmd = resolved.command;

    // 1. Permission
    if (!cmd.canBeUsedBy(userRole)) {
      return const ValidationFailed(
        status: CommandCapabilityStatus.permissionDenied,
        reason: 'Vous n\'avez pas les droits pour cette commande.',
      );
    }

    // 2. Installation hardware
    final missing = installation.firstMissing(cmd.requiredInstallationFlags);
    if (missing != null) {
      return ValidationFailed(
        status: CommandCapabilityStatus.notInstalled,
        reason: DeviceInstallationProfile.missingFlagReasonFr(missing),
      );
    }

    // 3. Online check for HIGH RISK commands (no queue allowed)
    if (!deviceOnline && cmd.requiresOnline && !cmd.supportsQueue) {
      return ValidationFailed(
        status: CommandCapabilityStatus.offlineBlocked,
        reason:
            'L\'appareil est hors ligne. Cette commande critique nécessite '
            'une connexion active pour être exécutée.',
      );
    }

    // 4. Required parameters
    if (cmd.requiredParameters.isNotEmpty) {
      final missing = cmd.requiredParameters
          .where((p) =>
              providedParams == null ||
              !providedParams.containsKey(p) ||
              (providedParams[p]?.toString().isEmpty ?? true))
          .toList();
      if (missing.isNotEmpty) {
        return ValidationFailed(
          status: CommandCapabilityStatus.missingParameters,
          reason:
              'Paramètre(s) manquant(s): ${missing.join(', ')}. '
              'Veuillez remplir tous les champs requis.',
        );
      }
    }

    // 5. Speed gate
    if (cmd.requiresSpeedCheck && currentSpeedKmh > cmd.maxAllowedSpeedKmh) {
      return ValidationFailed(
        status: CommandCapabilityStatus.blockedBySpeed,
        reason:
            'Le véhicule roule à ${currentSpeedKmh.toStringAsFixed(0)} km/h. '
            'Cette commande est bloquée au-dessus de '
            '${cmd.maxAllowedSpeedKmh.toStringAsFixed(0)} km/h.',
      );
    }

    // 6. Confirmation gate (Medium/High Risk)
    if (cmd.requiresConfirmation && !userConfirmed) {
      return ValidationNeedsConfirmation(
        riskLevel: cmd.riskLevel,
        extraWarning: cmd.warningMessage,
      );
    }

    // All checks passed
    final willBeQueued = !deviceOnline && cmd.supportsQueue;
    return ValidationPassed(willBeQueued: willBeQueued);
  }
}
