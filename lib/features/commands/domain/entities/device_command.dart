import 'package:flutter/material.dart';

import '../../../../core/models/user_role.dart';
import 'traccar_command_mapping.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Six functional sections shown in the commands screen.
enum CommandCategory {
  deviceInformation,
  tracking,
  securityAlerts,
  vehicleControl,
  maintenance,
  advanced;

  String get labelFr => switch (this) {
        deviceInformation => 'Informations appareil',
        tracking => 'Suivi & Tracking',
        securityAlerts => 'Sécurité & Alertes',
        vehicleControl => 'Contrôle du véhicule',
        maintenance => 'Maintenance',
        advanced => 'Avancé',
      };

  String get labelAr => switch (this) {
        deviceInformation => 'معلومات الجهاز',
        tracking => 'التتبع',
        securityAlerts => 'الحماية والتنبيهات',
        vehicleControl => 'التحكم بالمركبة',
        maintenance => 'الصيانة',
        advanced => 'متقدم',
      };

  String get labelEn => switch (this) {
        deviceInformation => 'Device Information',
        tracking => 'Tracking',
        securityAlerts => 'Security & Alerts',
        vehicleControl => 'Vehicle Control',
        maintenance => 'Maintenance',
        advanced => 'Advanced',
      };

  String get labelEs => switch (this) {
        deviceInformation => 'Información del dispositivo',
        tracking => 'Seguimiento',
        securityAlerts => 'Seguridad y alertas',
        vehicleControl => 'Control del vehículo',
        maintenance => 'Mantenimiento',
        advanced => 'Avanzado',
      };

  String label(Locale locale) => switch (locale.languageCode) {
        'ar' => labelAr,
        'fr' => labelFr,
        'es' => labelEs,
        _ => labelEn,
      };

  IconData get icon => switch (this) {
        deviceInformation => Icons.info_outline_rounded,
        tracking => Icons.gps_fixed_rounded,
        securityAlerts => Icons.security_rounded,
        vehicleControl => Icons.car_repair_rounded,
        maintenance => Icons.build_rounded,
        advanced => Icons.terminal_rounded,
      };

  Color get color => switch (this) {
        deviceInformation => const Color(0xFF2196F3),
        tracking => const Color(0xFF4CAF50),
        securityAlerts => const Color(0xFFFF9800),
        vehicleControl => const Color(0xFFF44336),
        maintenance => const Color(0xFF9C27B0),
        advanced => const Color(0xFF607D8B),
      };
}

/// Three-level risk classification.
enum CommandRiskLevel {
  /// Information only — no side-effects, no confirmation needed.
  low,

  /// Changes settings or behaviour — simple confirmation required.
  medium,

  /// Directly affects vehicle or connectivity —
  /// double confirmation + role check required.
  high;

  bool get requiresConfirmation => this != CommandRiskLevel.low;
  bool get isHigh => this == CommandRiskLevel.high;

  String get labelFr => switch (this) {
        low => 'Faible',
        medium => 'Modéré',
        high => 'Élevé',
      };

  String get labelAr => switch (this) {
        low => 'منخفض',
        medium => 'متوسط',
        high => 'عالي',
      };

  String get labelEn => switch (this) {
        low => 'Low',
        medium => 'Medium',
        high => 'High',
      };

  String get labelEs => switch (this) {
        low => 'Bajo',
        medium => 'Medio',
        high => 'Alto',
      };

  String label(Locale locale) => switch (locale.languageCode) {
        'ar' => labelAr,
        'fr' => labelFr,
        'es' => labelEs,
        _ => labelEn,
      };

  Color get color => switch (this) {
        low => const Color(0xFF4CAF50),
        medium => const Color(0xFFFF9800),
        high => const Color(0xFFF44336),
      };
}

/// How the command is transmitted to the device.
enum CommandSendMethod {
  /// Uses a direct Traccar native command type.
  native,

  /// Sent as `type='custom'` with a `data` attribute.
  custom,

  /// Uses a pre-saved command configured in Traccar.
  saved,

  /// Not supported by Traccar or this app.
  unsupported,

  /// Only valid for specific device protocols/brands.
  deviceSpecific;

  String get labelFr => switch (this) {
        native => 'Natif',
        custom => 'Personnalisé',
        saved => 'Sauvegardé',
        unsupported => 'Non supporté',
        deviceSpecific => 'Spécifique modèle',
      };
}

/// Runtime capability status of a command for a specific device + user context.
enum CommandCapabilityStatus {
  /// Fully supported — button is enabled.
  available,

  /// Supported via a custom command — button enabled with 'Custom' badge.
  availableViaCustom,

  /// Supported via a pre-saved Traccar command.
  availableViaSaved,

  /// The device model or protocol does not support this command.
  notSupportedByDevice,

  /// The required hardware is not installed in this vehicle.
  notInstalled,

  /// Blocked because device is offline and command is High Risk.
  offlineBlocked,

  /// Device is offline but command will be queued by Traccar.
  offlineQueued,

  /// Current user does not have the required role.
  permissionDenied,

  /// Vehicle is moving too fast for this High Risk command.
  blockedBySpeed,

  /// Required parameters have not been provided yet.
  missingParameters,

  /// A saved command must be configured in Traccar first.
  requiresSavedCommand,

  /// SMS fallback selected but SIM number is not configured.
  smsNotConfigured;

  bool get isExecutable =>
      this == available ||
      this == availableViaCustom ||
      this == availableViaSaved;

  bool get isQueueable => this == offlineQueued;
  bool get isDisabled => !isExecutable && !isQueueable;

  /// If `true`, show to all roles (including non-admin); if `false`, hide from
  /// basic users since the entry reveals restricted functionality.
  bool get showToAllUsers => this != permissionDenied;
}

// ── DeviceCommand ─────────────────────────────────────────────────────────────

/// A descriptor for a single Traccar command entry in the app catalog.
///
/// Combines display information (labels, icon) with the [TraccarCommandMapping]
/// that contains all send logic and permission rules.
///
/// Instances are constants defined in [CommandCatalog].
@immutable
class DeviceCommand {
  const DeviceCommand({
    required this.mapping,
    required this.labelFr,
    required this.labelAr,
    required this.labelEn,
    required this.labelEs,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionEs,
    required this.icon,
  });

  final TraccarCommandMapping mapping;
  final String labelFr;
  final String labelAr;
  final String labelEn;
  final String labelEs;
  final String descriptionFr;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionEs;
  final IconData icon;

  String label(Locale locale) => switch (locale.languageCode) {
        'ar' => labelAr,
        'fr' => labelFr,
        'es' => labelEs,
        _ => labelEn,
      };

  String description(Locale locale) => switch (locale.languageCode) {
        'ar' => descriptionAr,
        'fr' => descriptionFr,
        'es' => descriptionEs,
        _ => descriptionEn,
      };

  // ── Delegates to mapping ─────────────────────────────────────────────────

  String get commandKey => mapping.appCommandKey;
  String? get traccarType => mapping.traccarType;
  CommandCategory get category => mapping.category;
  CommandRiskLevel get riskLevel => mapping.riskLevel;
  CommandSendMethod get sendMethod => mapping.sendMethod;
  Set<UserRole> get allowedRoles => mapping.allowedRoles;
  Map<String, dynamic> get defaultAttributes => mapping.defaultAttributes;
  List<String> get requiredParameters => mapping.requiredParameters;
  Set<String> get requiredInstallationFlags =>
      mapping.requiredInstallationFlags;
  bool get requiresOnline => mapping.requiresOnline;
  bool get supportsQueue => mapping.supportsQueue;
  bool get supportsSmsFallback => mapping.supportsSmsFallback;
  bool get requiresSpeedCheck => mapping.requiresSpeedCheck;
  double get maxAllowedSpeedKmh => mapping.maxAllowedSpeedKmh;
  String? get warningMessage => mapping.warningMessage;

  bool get isHighRisk => riskLevel.isHigh;
  bool get requiresConfirmation => riskLevel.requiresConfirmation;
  bool canBeUsedBy(UserRole role) => mapping.allowsRole(role);

  @override
  bool operator ==(Object other) =>
      other is DeviceCommand && other.commandKey == commandKey;

  @override
  int get hashCode => commandKey.hashCode;
}
