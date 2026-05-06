import 'device_command.dart';

/// Execution status of a dispatched command.
enum CommandStatus {
  /// Accepted by the API but no device acknowledgement yet.
  pending,

  /// Successfully sent / acknowledged.
  success,

  /// API rejected the command or device returned an error.
  failed,

  /// No response received within the timeout window.
  timeout,

  /// Command was placed in Traccar's queue (device was offline).
  queued,

  /// Explicitly rejected by a local safety rule before reaching the API.
  rejected,
}

/// An immutable record of one command dispatch stored in the local history.
class CommandLogEntry {
  const CommandLogEntry({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.commandKey,
    required this.commandType,
    required this.labelFr,
    required this.category,
    required this.riskLevel,
    required this.sendMethod,
    required this.sentAt,
    required this.status,
    this.sentByUserId,
    this.sentByUserName,
    this.errorMessage,
    this.failureReason,
    this.rawResponse,
    this.deviceOnlineAtExecution,
    this.vehicleSpeedAtExecution,
    this.attributes = const {},
  });

  final String id;
  final int deviceId;
  final String deviceName;

  /// App-internal command key (e.g. `'engineStop'`).
  final String commandKey;

  /// Traccar command type string sent to the API.
  final String commandType;

  /// French label captured at send time so history remains readable
  /// even if the catalog changes later.
  final String labelFr;

  final CommandCategory category;
  final CommandRiskLevel riskLevel;
  final CommandSendMethod sendMethod;
  final DateTime sentAt;
  final CommandStatus status;

  final String? sentByUserId;
  final String? sentByUserName;

  /// User-friendly error message (never a raw API exception).
  final String? errorMessage;

  /// Technical failure reason — shown only to technicians/admins.
  final String? failureReason;

  /// Raw Traccar API response body for debugging.
  final String? rawResponse;

  /// Whether the device was online at the time of execution.
  final bool? deviceOnlineAtExecution;

  /// Vehicle speed (km/h) at the time of execution.
  final double? vehicleSpeedAtExecution;

  final Map<String, dynamic> attributes;

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'commandKey': commandKey,
        'commandType': commandType,
        'labelFr': labelFr,
        'category': category.name,
        'riskLevel': riskLevel.name,
        'sendMethod': sendMethod.name,
        'sentAt': sentAt.toIso8601String(),
        'status': status.name,
        if (sentByUserId != null) 'sentByUserId': sentByUserId,
        if (sentByUserName != null) 'sentByUserName': sentByUserName,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (failureReason != null) 'failureReason': failureReason,
        if (rawResponse != null) 'rawResponse': rawResponse,
        if (deviceOnlineAtExecution != null)
          'deviceOnlineAtExecution': deviceOnlineAtExecution,
        if (vehicleSpeedAtExecution != null)
          'vehicleSpeedAtExecution': vehicleSpeedAtExecution,
        'attributes': attributes,
      };

  factory CommandLogEntry.fromJson(Map<String, dynamic> json) =>
      CommandLogEntry(
        id: json['id'] as String,
        deviceId: json['deviceId'] as int,
        deviceName: json['deviceName'] as String,
        // commandKey may be absent in older entries — fall back to commandType.
        commandKey:
            json['commandKey'] as String? ?? json['commandType'] as String,
        commandType: json['commandType'] as String,
        labelFr: json['labelFr'] as String,
        category: _parseCategory(json['category'] as String?),
        riskLevel: _parseRiskLevel(
          json['riskLevel'] as String? ?? json['risk'] as String?,
        ),
        sendMethod: CommandSendMethod.values.firstWhere(
          (e) => e.name == json['sendMethod'],
          orElse: () => CommandSendMethod.native,
        ),
        sentAt: DateTime.parse(json['sentAt'] as String),
        status: CommandStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CommandStatus.failed,
        ),
        sentByUserId: json['sentByUserId'] as String?,
        sentByUserName: json['sentByUserName'] as String?,
        errorMessage: json['errorMessage'] as String?,
        failureReason: json['failureReason'] as String?,
        rawResponse: json['rawResponse'] as String?,
        deviceOnlineAtExecution:
            json['deviceOnlineAtExecution'] as bool?,
        vehicleSpeedAtExecution:
            (json['vehicleSpeedAtExecution'] as num?)?.toDouble(),
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  // ── Legacy migration helpers ──────────────────────────────────────────────

  /// Maps old 2-value `category` names to the new 6-value enum.
  static CommandCategory _parseCategory(String? name) {
    if (name == null) return CommandCategory.deviceInformation;
    return switch (name) {
      // New values
      'deviceInformation' => CommandCategory.deviceInformation,
      'tracking' => CommandCategory.tracking,
      'securityAlerts' => CommandCategory.securityAlerts,
      'vehicleControl' => CommandCategory.vehicleControl,
      'maintenance' => CommandCategory.maintenance,
      'advanced' => CommandCategory.advanced,
      // Legacy values (before v2 schema)
      'control' => CommandCategory.vehicleControl,
      'query' => CommandCategory.deviceInformation,
      _ => CommandCategory.deviceInformation,
    };
  }

  /// Maps old 3-value `risk` names to the new 3-value `riskLevel`.
  static CommandRiskLevel _parseRiskLevel(String? name) {
    if (name == null) return CommandRiskLevel.low;
    return switch (name) {
      // New values
      'low' => CommandRiskLevel.low,
      'medium' => CommandRiskLevel.medium,
      'high' => CommandRiskLevel.high,
      // Legacy values
      'safe' => CommandRiskLevel.low,
      'warning' => CommandRiskLevel.medium,
      'critical' => CommandRiskLevel.high,
      _ => CommandRiskLevel.low,
    };
  }

  // ── Copy ─────────────────────────────────────────────────────────────────

  CommandLogEntry copyWith({
    CommandStatus? status,
    String? errorMessage,
    String? failureReason,
    String? rawResponse,
    bool? deviceOnlineAtExecution,
    double? vehicleSpeedAtExecution,
  }) =>
      CommandLogEntry(
        id: id,
        deviceId: deviceId,
        deviceName: deviceName,
        commandKey: commandKey,
        commandType: commandType,
        labelFr: labelFr,
        category: category,
        riskLevel: riskLevel,
        sendMethod: sendMethod,
        sentAt: sentAt,
        status: status ?? this.status,
        sentByUserId: sentByUserId,
        sentByUserName: sentByUserName,
        errorMessage: errorMessage ?? this.errorMessage,
        failureReason: failureReason ?? this.failureReason,
        rawResponse: rawResponse ?? this.rawResponse,
        deviceOnlineAtExecution:
            deviceOnlineAtExecution ?? this.deviceOnlineAtExecution,
        vehicleSpeedAtExecution:
            vehicleSpeedAtExecution ?? this.vehicleSpeedAtExecution,
        attributes: attributes,
      );
}
