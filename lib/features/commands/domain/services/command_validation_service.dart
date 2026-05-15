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
    String languageCode = 'fr',
  }) {
    final cmd = resolved.command;

    // 1. Permission
    if (!cmd.canBeUsedBy(userRole)) {
      return ValidationFailed(
        status: CommandCapabilityStatus.permissionDenied,
        reason: _permissionDeniedReason(languageCode),
      );
    }

    // 2. Installation hardware
    final missing = installation.firstMissing(cmd.requiredInstallationFlags);
    if (missing != null) {
      return ValidationFailed(
        status: CommandCapabilityStatus.notInstalled,
        reason:
            DeviceInstallationProfile.missingFlagReason(missing, languageCode),
      );
    }

    // 3. Online check for HIGH RISK commands (no queue allowed)
    if (!deviceOnline && cmd.requiresOnline && !cmd.supportsQueue) {
      return ValidationFailed(
        status: CommandCapabilityStatus.offlineBlocked,
        reason: _offlineCriticalReason(languageCode),
      );
    }

    // 4. Required parameters
    if (cmd.requiredParameters.isNotEmpty) {
      final missingParams = cmd.requiredParameters
          .where((p) =>
              providedParams == null ||
              !providedParams.containsKey(p) ||
              (providedParams[p]?.toString().isEmpty ?? true))
          .toList();
      if (missingParams.isNotEmpty) {
        return ValidationFailed(
          status: CommandCapabilityStatus.missingParameters,
          reason: _missingParamsReason(languageCode, missingParams),
        );
      }
    }

    // 5. Speed gate
    if (cmd.requiresSpeedCheck && currentSpeedKmh > cmd.maxAllowedSpeedKmh) {
      return ValidationFailed(
        status: CommandCapabilityStatus.blockedBySpeed,
        reason: _speedBlockedReason(
            languageCode, currentSpeedKmh, cmd.maxAllowedSpeedKmh),
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

  // ── Locale-aware reason helpers ─────────────────────────────────────────────

  static String _permissionDeniedReason(String lang) => switch (lang) {
        'ar' => 'ليس لديك صلاحية لهذا الأمر.',
        'fr' => 'Vous n\'avez pas les droits pour cette commande.',
        'es' => 'No tiene permisos para este comando.',
        _ => 'You do not have permission for this command.',
      };

  static String _offlineCriticalReason(String lang) => switch (lang) {
        'ar' => 'الجهاز غير متصل. هذا الأمر الحرج يتطلب اتصالاً نشطاً.',
        'fr' =>
          'L\'appareil est hors ligne. Cette commande critique nécessite une connexion active pour être exécutée.',
        'es' =>
          'El dispositivo está desconectado. Este comando crítico requiere una conexión activa.',
        _ => 'Device is offline. This critical command requires an active connection.',
      };

  static String _missingParamsReason(String lang, List<String> missing) =>
      switch (lang) {
        'ar' =>
          'معلمات مفقودة: ${missing.join(', ')}. يرجى ملء جميع الحقول المطلوبة.',
        'fr' =>
          'Paramètre(s) manquant(s): ${missing.join(', ')}. Veuillez remplir tous les champs requis.',
        'es' =>
          'Parámetro(s) faltante(s): ${missing.join(', ')}. Complete todos los campos requeridos.',
        _ =>
          'Missing parameter(s): ${missing.join(', ')}. Please fill in all required fields.',
      };

  static String _speedBlockedReason(
          String lang, double currentSpeed, double maxSpeed) =>
      switch (lang) {
        'ar' =>
          'المركبة تسير بسرعة ${currentSpeed.toStringAsFixed(0)} كم/س. هذا الأمر محظور فوق ${maxSpeed.toStringAsFixed(0)} كم/س.',
        'fr' =>
          'Le véhicule roule à ${currentSpeed.toStringAsFixed(0)} km/h. Cette commande est bloquée au-dessus de ${maxSpeed.toStringAsFixed(0)} km/h.',
        'es' =>
          'El vehículo circula a ${currentSpeed.toStringAsFixed(0)} km/h. Este comando está bloqueado por encima de ${maxSpeed.toStringAsFixed(0)} km/h.',
        _ =>
          'Vehicle is moving at ${currentSpeed.toStringAsFixed(0)} km/h. This command is blocked above ${maxSpeed.toStringAsFixed(0)} km/h.',
      };
}
