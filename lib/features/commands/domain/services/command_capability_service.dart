import '../../../../core/models/user_role.dart';
import '../catalog/command_catalog.dart';
import '../catalog/device_profiles_catalog.dart';
import '../entities/device_command.dart';
import '../entities/device_command_profile.dart';
import '../entities/device_installation_profile.dart';
import '../entities/resolved_device_command.dart';

/// Resolves the runtime [CommandCapabilityStatus] for every command by
/// merging four sources of truth:
///
/// 1. [DeviceCommandProfile]  — what the device model/protocol supports.
/// 2. Traccar API types       — what the server says is available.
/// 3. [DeviceInstallationProfile] — what is physically wired in the vehicle.
/// 4. Context                 — user role, device online state, speed.
class CommandCapabilityService {
  const CommandCapabilityService();

  /// Returns a resolved list of all commands for the given context.
  ///
  /// Filters out [CommandCapabilityStatus.permissionDenied] entries from
  /// non-privileged users so they are not visible.
  List<ResolvedDeviceCommand> resolveAll({
    required UserRole userRole,
    required bool deviceOnline,
    required double currentSpeedKmh,
    required List<String> traccarSupportedTypes,
    required DeviceInstallationProfile installation,
    String? deviceModel,
    String languageCode = 'fr',
  }) {
    final profile = DeviceProfilesCatalog.findByModel(deviceModel);
    final resolved = <ResolvedDeviceCommand>[];

    for (final cmd in CommandCatalog.all) {
      final r = _resolve(
        command: cmd,
        userRole: userRole,
        deviceOnline: deviceOnline,
        currentSpeedKmh: currentSpeedKmh,
        traccarSupportedTypes: traccarSupportedTypes,
        installation: installation,
        profile: profile,
        languageCode: languageCode,
      );
      // Hide permissionDenied from viewer and operator — they should never
      // see commands they cannot use. Technicians see admin-only commands
      // as disabled (with reason), so they are aware they exist.
      if (r.status == CommandCapabilityStatus.permissionDenied &&
          !userRole.isAtLeastTechnician) {
        continue;
      }
      resolved.add(r);
    }
    return resolved;
  }

  /// Returns resolved commands grouped by [CommandCategory].
  Map<CommandCategory, List<ResolvedDeviceCommand>> resolveByCategory({
    required UserRole userRole,
    required bool deviceOnline,
    required double currentSpeedKmh,
    required List<String> traccarSupportedTypes,
    required DeviceInstallationProfile installation,
    String? deviceModel,
    String languageCode = 'fr',
  }) {
    final all = resolveAll(
      userRole: userRole,
      deviceOnline: deviceOnline,
      currentSpeedKmh: currentSpeedKmh,
      traccarSupportedTypes: traccarSupportedTypes,
      installation: installation,
      deviceModel: deviceModel,
      languageCode: languageCode,
    );

    final map = <CommandCategory, List<ResolvedDeviceCommand>>{};
    for (final category in CommandCategory.values) {
      final cmds = all.where((r) => r.command.category == category).toList();
      if (cmds.isNotEmpty) map[category] = cmds;
    }
    return map;
  }

  // ── Private resolution logic ───────────────────────────────────────────────

  ResolvedDeviceCommand _resolve({
    required DeviceCommand command,
    required UserRole userRole,
    required bool deviceOnline,
    required double currentSpeedKmh,
    required List<String> traccarSupportedTypes,
    required DeviceInstallationProfile installation,
    DeviceCommandProfile? profile,
    String languageCode = 'fr',
  }) {
    // ── Step 1: Permission check ───────────────────────────────────────────
    if (!command.canBeUsedBy(userRole)) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.permissionDenied,
        disableReason: _permissionDeniedReason(languageCode),
      );
    }

    // ── Step 2: Model-based support check ─────────────────────────────────
    if (command.traccarType != null && profile != null) {
      if (profile.isExplicitlyUnsupported(command.traccarType!)) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.notSupportedByDevice,
          disableReason: _notSupportedByModelReason(languageCode),
        );
      }
    }

    // ── Step 3: Traccar API support check ─────────────────────────────────
    if (command.traccarType != null &&
        traccarSupportedTypes.isNotEmpty &&
        !traccarSupportedTypes.contains(command.traccarType) &&
        command.traccarType != 'custom') {
      // If neither model profile nor Traccar reports this type, mark unsupported.
      // Exception: 'custom' type is always accepted by Traccar.
      if (profile == null || !profile.supportsAny(command.traccarType!)) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.notSupportedByDevice,
          disableReason: _notSupportedByPlatformReason(languageCode),
        );
      }
    }

    // ── Step 4: Installation check ────────────────────────────────────────
    final flags = command.requiredInstallationFlags;
    if (flags.isNotEmpty) {
      final missing = installation.firstMissing(flags);
      if (missing != null) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.notInstalled,
          disableReason:
              DeviceInstallationProfile.missingFlagReason(missing, languageCode),
        );
      }
    }

    // ── Step 5: Offline / queue check ─────────────────────────────────────
    if (!deviceOnline && command.requiresOnline) {
      if (!command.supportsQueue) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.offlineBlocked,
          disableReason: _offlineBlockedReason(languageCode),
        );
      }
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.offlineQueued,
        queueMessage: _offlineQueuedReason(languageCode),
      );
    }

    // ── Step 6: Speed safety check ────────────────────────────────────────
    if (command.requiresSpeedCheck &&
        currentSpeedKmh > command.maxAllowedSpeedKmh) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.blockedBySpeed,
        disableReason: _speedBlockedReason(
            languageCode, currentSpeedKmh, command.maxAllowedSpeedKmh),
      );
    }

    // ── Step 7: Determine send method status ──────────────────────────────
    if (command.sendMethod == CommandSendMethod.saved) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.availableViaSaved,
      );
    }

    if (command.sendMethod == CommandSendMethod.custom ||
        command.sendMethod == CommandSendMethod.deviceSpecific) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.availableViaCustom,
      );
    }

    if (command.sendMethod == CommandSendMethod.unsupported) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.notSupportedByDevice,
        disableReason: _unsupportedByAppReason(languageCode),
      );
    }

    // ── Step 8: Available ────────────────────────────────────────────────
    return ResolvedDeviceCommand(
      command: command,
      status: CommandCapabilityStatus.available,
    );
  }

  // ── Locale-aware reason helpers ─────────────────────────────────────────────

  static String _permissionDeniedReason(String lang) => switch (lang) {
        'ar' => 'ليس لديك صلاحية لهذا الأمر.',
        'fr' => 'Vous n\'avez pas les droits pour cette commande.',
        'es' => 'No tiene permisos para este comando.',
        _ => 'You do not have permission for this command.',
      };

  static String _notSupportedByModelReason(String lang) => switch (lang) {
        'ar' => 'هذا الأمر غير مدعوم من هذا الطراز.',
        'fr' => 'Cette commande n\'est pas supportée par ce modèle d\'appareil.',
        'es' => 'Este comando no es compatible con este modelo de dispositivo.',
        _ => 'This command is not supported by this device model.',
      };

  static String _notSupportedByPlatformReason(String lang) => switch (lang) {
        'ar' => 'هذا الأمر غير متاح وفقاً للنظام.',
        'fr' => 'Cette commande n\'est pas disponible selon la plateforme ELMOGPS.',
        'es' => 'Este comando no está disponible según la plataforma.',
        _ => 'This command is not available on this platform.',
      };

  static String _offlineBlockedReason(String lang) => switch (lang) {
        'ar' => 'الجهاز غير متصل. لا يمكن تنفيذ هذا الأمر بدون اتصال نشط.',
        'fr' =>
          'L\'appareil est hors ligne. Cette commande ne peut pas être exécutée sans connexion active.',
        'es' =>
          'El dispositivo está desconectado. Este comando no se puede ejecutar sin conexión activa.',
        _ => 'Device is offline. This command cannot be executed without an active connection.',
      };

  static String _offlineQueuedReason(String lang) => switch (lang) {
        'ar' => 'الجهاز غير متصل. سيتم إرسال الأمر عند إعادة الاتصال.',
        'fr' =>
          'L\'appareil est hors ligne. La commande sera envoyée dès qu\'il se reconnecte.',
        'es' =>
          'El dispositivo está desconectado. El comando se enviará cuando se reconecte.',
        _ => 'Device is offline. The command will be sent when it reconnects.',
      };

  static String _speedBlockedReason(
          String lang, double currentSpeed, double maxSpeed) =>
      switch (lang) {
        'ar' =>
          'المركبة تتحرك بسرعة ${currentSpeed.toStringAsFixed(0)} كم/س. هذا الأمر محظور فوق ${maxSpeed.toStringAsFixed(0)} كم/س.',
        'fr' =>
          'Le véhicule se déplace à ${currentSpeed.toStringAsFixed(0)} km/h. Cette commande est bloquée au-dessus de ${maxSpeed.toStringAsFixed(0)} km/h.',
        'es' =>
          'El vehículo se mueve a ${currentSpeed.toStringAsFixed(0)} km/h. Este comando está bloqueado por encima de ${maxSpeed.toStringAsFixed(0)} km/h.',
        _ =>
          'Vehicle is moving at ${currentSpeed.toStringAsFixed(0)} km/h. This command is blocked above ${maxSpeed.toStringAsFixed(0)} km/h.',
      };

  static String _unsupportedByAppReason(String lang) => switch (lang) {
        'ar' => 'هذا الأمر غير مدعوم من هذا التطبيق.',
        'fr' => 'Cette commande n\'est pas supportée par cette application.',
        'es' => 'Este comando no es compatible con esta aplicación.',
        _ => 'This command is not supported by this application.',
      };
}
