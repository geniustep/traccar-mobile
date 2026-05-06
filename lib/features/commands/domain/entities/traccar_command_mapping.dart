import 'package:flutter/foundation.dart';

import '../../../../core/models/user_role.dart';
import 'device_command.dart';

/// Static descriptor that maps an app-internal command key to a Traccar
/// command type and all associated send metadata.
///
/// Instances live in [CommandCatalog] — never constructed per request.
@immutable
class TraccarCommandMapping {
  const TraccarCommandMapping({
    required this.appCommandKey,
    required this.category,
    required this.riskLevel,
    required this.sendMethod,
    required this.allowedRoles,
    this.traccarType,
    this.requiredParameters = const [],
    this.defaultAttributes = const {},
    this.requiredInstallationFlags = const {},
    this.requiresOnline = true,
    this.supportsQueue = true,
    this.supportsSmsFallback = false,
    this.requiresSpeedCheck = false,
    this.maxAllowedSpeedKmh = 5.0,
    this.warningMessage,
  });

  /// Internal key used by the app (matches column in the mapping matrix).
  final String appCommandKey;

  /// Traccar command type sent to `POST /commands/send`.
  /// `null` when [sendMethod] is [CommandSendMethod.unsupported].
  final String? traccarType;

  final CommandCategory category;
  final CommandRiskLevel riskLevel;
  final CommandSendMethod sendMethod;

  /// Set of roles that may see and execute this command.
  final Set<UserRole> allowedRoles;

  /// Parameter keys that must be supplied before the command can be sent.
  final List<String> requiredParameters;

  /// Attributes merged into the API request body by default.
  final Map<String, dynamic> defaultAttributes;

  /// [DeviceInstallationProfile] boolean flags that must ALL be `true`.
  /// e.g. `{'hasRelay'}` or `{'hasOutput1'}`.
  final Set<String> requiredInstallationFlags;

  /// Command is blocked when device is offline if this is `true`
  /// AND [supportsQueue] is `false`.
  final bool requiresOnline;

  /// Traccar can queue this command for delivery when device comes back online.
  /// Must be `false` for all High Risk commands.
  final bool supportsQueue;

  /// An SMS fallback path exists for this command.
  final bool supportsSmsFallback;

  /// If `true`, execution is blocked when speed > [maxAllowedSpeedKmh].
  final bool requiresSpeedCheck;
  final double maxAllowedSpeedKmh;

  /// Extra warning text shown in the confirmation dialog.
  final String? warningMessage;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isCustomSend =>
      sendMethod == CommandSendMethod.custom ||
      sendMethod == CommandSendMethod.deviceSpecific;

  bool get isSavedSend => sendMethod == CommandSendMethod.saved;

  /// High Risk + requiresOnline + !supportsQueue → always blocked offline.
  bool get blocksWhenOffline => requiresOnline && !supportsQueue;

  bool allowsRole(UserRole role) => allowedRoles.contains(role);
}
