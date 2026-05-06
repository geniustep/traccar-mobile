import 'package:flutter/foundation.dart';

import 'device_command.dart';

/// A [DeviceCommand] with its computed runtime capability status.
///
/// Created by [CommandCapabilityService] after checking all sources:
/// - Traccar API supported types
/// - DeviceCommandProfile (model-based)
/// - DeviceInstallationProfile (hardware)
/// - Device online/offline state
/// - Current user role
/// - Vehicle speed
@immutable
class ResolvedDeviceCommand {
  const ResolvedDeviceCommand({
    required this.command,
    required this.status,
    this.disableReason,
    this.queueMessage,
  });

  final DeviceCommand command;
  final CommandCapabilityStatus status;

  /// Human-readable French explanation of why the command is disabled.
  /// Non-null when [status] is a disabled/blocked state.
  final String? disableReason;

  /// Message shown when the command is queued (offline queue state).
  final String? queueMessage;

  // ── Convenience delegates ────────────────────────────────────────────────

  String get commandKey => command.commandKey;
  String get labelFr => command.labelFr;
  String get labelAr => command.labelAr;
  String get descriptionFr => command.descriptionFr;
  bool get isExecutable => status.isExecutable;
  bool get isQueueable => status.isQueueable;
  bool get isDisabled => status.isDisabled;
  bool get isAvailable => status == CommandCapabilityStatus.available;
  bool get isAvailableViaCustom =>
      status == CommandCapabilityStatus.availableViaCustom;
  bool get isAvailableViaSaved =>
      status == CommandCapabilityStatus.availableViaSaved;

  /// Returns a copy with an updated [status] and optional [disableReason].
  ResolvedDeviceCommand withStatus(
    CommandCapabilityStatus newStatus, {
    String? reason,
    String? queue,
  }) =>
      ResolvedDeviceCommand(
        command: command,
        status: newStatus,
        disableReason: reason ?? disableReason,
        queueMessage: queue ?? queueMessage,
      );
}
