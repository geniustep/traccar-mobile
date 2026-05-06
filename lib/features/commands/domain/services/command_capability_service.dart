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
  }) {
    final all = resolveAll(
      userRole: userRole,
      deviceOnline: deviceOnline,
      currentSpeedKmh: currentSpeedKmh,
      traccarSupportedTypes: traccarSupportedTypes,
      installation: installation,
      deviceModel: deviceModel,
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
  }) {
    // ── Step 1: Permission check ───────────────────────────────────────────
    if (!command.canBeUsedBy(userRole)) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.permissionDenied,
        disableReason: 'Vous n\'avez pas les droits pour cette commande.',
      );
    }

    // ── Step 2: Model-based support check ─────────────────────────────────
    if (command.traccarType != null && profile != null) {
      if (profile.isExplicitlyUnsupported(command.traccarType!)) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.notSupportedByDevice,
          disableReason:
              'Cette commande n\'est pas supportée par ce modèle d\'appareil.',
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
          disableReason:
              'Cette commande n\'est pas disponible selon le serveur Traccar.',
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
          disableReason: DeviceInstallationProfile.missingFlagReasonFr(missing),
        );
      }
    }

    // ── Step 5: Offline / queue check ─────────────────────────────────────
    if (!deviceOnline && command.requiresOnline) {
      if (!command.supportsQueue) {
        return ResolvedDeviceCommand(
          command: command,
          status: CommandCapabilityStatus.offlineBlocked,
          disableReason:
              'L\'appareil est hors ligne. Cette commande ne peut pas être '
              'exécutée sans connexion active.',
        );
      }
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.offlineQueued,
        queueMessage:
            'L\'appareil est hors ligne. La commande sera envoyée dès '
            'qu\'il se reconnecte.',
      );
    }

    // ── Step 6: Speed safety check ────────────────────────────────────────
    if (command.requiresSpeedCheck &&
        currentSpeedKmh > command.maxAllowedSpeedKmh) {
      return ResolvedDeviceCommand(
        command: command,
        status: CommandCapabilityStatus.blockedBySpeed,
        disableReason:
            'Le véhicule se déplace à ${currentSpeedKmh.toStringAsFixed(0)} km/h. '
            'Cette commande est bloquée au-dessus de '
            '${command.maxAllowedSpeedKmh.toStringAsFixed(0)} km/h.',
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
        disableReason: 'Cette commande n\'est pas supportée par cette application.',
      );
    }

    // ── Step 8: Available ────────────────────────────────────────────────
    return ResolvedDeviceCommand(
      command: command,
      status: CommandCapabilityStatus.available,
    );
  }
}
