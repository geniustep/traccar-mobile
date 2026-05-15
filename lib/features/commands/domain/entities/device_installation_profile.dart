import 'package:flutter/foundation.dart';

/// Describes the physical hardware wired into a specific vehicle/device.
///
/// Stored per-device in SharedPreferences by [DeviceInstallationService].
/// Used by [CommandCapabilityService] to gate commands that require
/// specific hardware (relay, SOS button, door sensor, etc.).
@immutable
class DeviceInstallationProfile {
  const DeviceInstallationProfile({
    required this.deviceId,
    this.hasRelay = false,
    this.hasImmobilizer = false,
    this.hasIgnitionInput = false,
    this.hasDoorInput = false,
    this.hasFuelSensor = false,
    this.hasTemperatureSensor = false,
    this.hasSosButton = false,
    this.hasOutput1 = false,
    this.hasOutput2 = false,
    this.smsEnabled = false,
    this.simPhoneNumber,
    this.installationNotes,
    this.lastUpdatedAt,
    this.updatedByUserId,
  });

  final int deviceId;

  /// A relay is wired between the GPS output and the ignition/fuel circuit.
  final bool hasRelay;

  /// A dedicated immobilizer is installed and wired to the GPS output.
  final bool hasImmobilizer;

  /// ACC/ignition sense wire is connected to the GPS input.
  final bool hasIgnitionInput;

  /// Door contact sensor is wired to a GPS digital input.
  final bool hasDoorInput;

  /// Fuel level sensor is wired to the GPS analog input.
  final bool hasFuelSensor;

  /// Temperature sensor is connected to the GPS.
  final bool hasTemperatureSensor;

  /// Physical SOS / panic button is installed and wired.
  final bool hasSosButton;

  /// Digital output #1 is physically wired to an actuator.
  final bool hasOutput1;

  /// Digital output #2 is physically wired to an actuator.
  final bool hasOutput2;

  /// The device SIM supports SMS and the app may send SMS commands.
  final bool smsEnabled;

  /// SIM phone number used for SMS fallback commands.
  final String? simPhoneNumber;

  /// Free-text installation notes visible to technicians.
  final String? installationNotes;

  final DateTime? lastUpdatedAt;
  final String? updatedByUserId;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// True when at least one engine-cut mechanism (relay OR immobilizer) is
  /// physically installed. Used by `engineStop` / `engineResume` commands.
  bool get hasEngineControl => hasRelay || hasImmobilizer;

  /// Returns `true` if the named installation flag is satisfied.
  ///
  /// The virtual flag `'hasEngineControl'` is satisfied when either a relay
  /// OR an immobilizer is installed, making it suitable for generic engine
  /// cut/restore commands that work via either hardware.
  bool satisfies(String flag) => switch (flag) {
        'hasRelay' => hasRelay,
        'hasImmobilizer' => hasImmobilizer,
        'hasEngineControl' => hasEngineControl,
        'hasIgnitionInput' => hasIgnitionInput,
        'hasDoorInput' => hasDoorInput,
        'hasFuelSensor' => hasFuelSensor,
        'hasTemperatureSensor' => hasTemperatureSensor,
        'hasSosButton' => hasSosButton,
        'hasOutput1' => hasOutput1,
        'hasOutput2' => hasOutput2,
        _ => false,
      };

  /// Returns `true` only when every flag in [flags] is satisfied.
  bool satisfiesAll(Set<String> flags) => flags.every(satisfies);

  /// Returns the first flag in [flags] that is NOT satisfied, or `null`.
  String? firstMissing(Set<String> flags) {
    for (final flag in flags) {
      if (!satisfies(flag)) return flag;
    }
    return null;
  }

  /// Human-readable French reason for a missing installation flag.
  static String missingFlagReasonFr(String flag) => switch (flag) {
        'hasEngineControl' =>
          'Cette commande nécessite un relais ou un immobiliseur installé '
              'et câblé au véhicule.',
        'hasRelay' =>
          'Cette commande nécessite un relais installé et câblé au véhicule.',
        'hasImmobilizer' =>
          'Cette commande nécessite un immobiliseur installé et câblé.',
        'hasDoorInput' =>
          'Ce commande nécessite un capteur de porte installé.',
        'hasSosButton' => 'Ce commande nécessite un bouton SOS installé.',
        'hasOutput1' =>
          'Ce commande nécessite la sortie 1 installée et câblée.',
        'hasOutput2' =>
          'Ce commande nécessite la sortie 2 installée et câblée.',
        'hasFuelSensor' =>
          'Ce commande nécessite un capteur de carburant installé.',
        'hasTemperatureSensor' =>
          'Ce commande nécessite un capteur de température installé.',
        _ => 'Un équipement requis n\'est pas installé.',
      };

  /// Human-readable Arabic reason for a missing installation flag.
  static String missingFlagReasonAr(String flag) => switch (flag) {
        'hasEngineControl' =>
          'هذا الأمر يتطلب تركيب Relay أو Immobilizer في المركبة.',
        'hasRelay' => 'هذا الأمر يتطلب تركيب وتوصيل Relay في المركبة.',
        'hasImmobilizer' =>
          'هذا الأمر يتطلب تركيب وتوصيل Immobilizer.',
        'hasDoorInput' => 'هذا الأمر يتطلب تركيب حساس باب.',
        'hasSosButton' => 'هذا الأمر يتطلب تركيب زر SOS.',
        'hasOutput1' => 'هذا الأمر يتطلب توصيل Output 1.',
        'hasOutput2' => 'هذا الأمر يتطلب توصيل Output 2.',
        'hasFuelSensor' => 'هذا الأمر يتطلب تركيب حساس وقود.',
        'hasTemperatureSensor' => 'هذا الأمر يتطلب تركيب حساس حرارة.',
        _ => 'مكوّن مطلوب غير متوفر في هذه المركبة.',
      };

  /// Human-readable English reason for a missing installation flag.
  static String missingFlagReasonEn(String flag) => switch (flag) {
        'hasEngineControl' =>
          'This command requires a relay or immobilizer installed and wired to the vehicle.',
        'hasRelay' =>
          'This command requires a relay installed and wired to the vehicle.',
        'hasImmobilizer' =>
          'This command requires an immobilizer installed and wired.',
        'hasDoorInput' =>
          'This command requires an installed door sensor.',
        'hasSosButton' => 'This command requires an installed SOS button.',
        'hasOutput1' =>
          'This command requires output 1 installed and wired.',
        'hasOutput2' =>
          'This command requires output 2 installed and wired.',
        'hasFuelSensor' =>
          'This command requires an installed fuel sensor.',
        'hasTemperatureSensor' =>
          'This command requires an installed temperature sensor.',
        _ => 'A required piece of equipment is not installed.',
      };

  /// Human-readable Spanish reason for a missing installation flag.
  static String missingFlagReasonEs(String flag) => switch (flag) {
        'hasEngineControl' =>
          'Este comando requiere un relé o inmovilizador instalado y conectado al vehículo.',
        'hasRelay' =>
          'Este comando requiere un relé instalado y conectado al vehículo.',
        'hasImmobilizer' =>
          'Este comando requiere un inmovilizador instalado y conectado.',
        'hasDoorInput' =>
          'Este comando requiere un sensor de puerta instalado.',
        'hasSosButton' => 'Este comando requiere un botón SOS instalado.',
        'hasOutput1' =>
          'Este comando requiere la salida 1 instalada y conectada.',
        'hasOutput2' =>
          'Este comando requiere la salida 2 instalada y conectada.',
        'hasFuelSensor' =>
          'Este comando requiere un sensor de combustible instalado.',
        'hasTemperatureSensor' =>
          'Este comando requiere un sensor de temperatura instalado.',
        _ => 'Un equipo requerido no está instalado.',
      };

  /// Returns a localized missing-flag reason based on [languageCode].
  static String missingFlagReason(String flag, String languageCode) =>
      switch (languageCode) {
        'ar' => missingFlagReasonAr(flag),
        'fr' => missingFlagReasonFr(flag),
        'es' => missingFlagReasonEs(flag),
        _ => missingFlagReasonEn(flag),
      };

  // ── Default / factory ─────────────────────────────────────────────────────

  /// Returns a safe default profile with everything disabled.
  static DeviceInstallationProfile defaultFor(int deviceId) =>
      DeviceInstallationProfile(deviceId: deviceId);

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'hasRelay': hasRelay,
        'hasImmobilizer': hasImmobilizer,
        'hasIgnitionInput': hasIgnitionInput,
        'hasDoorInput': hasDoorInput,
        'hasFuelSensor': hasFuelSensor,
        'hasTemperatureSensor': hasTemperatureSensor,
        'hasSosButton': hasSosButton,
        'hasOutput1': hasOutput1,
        'hasOutput2': hasOutput2,
        'smsEnabled': smsEnabled,
        if (simPhoneNumber != null) 'simPhoneNumber': simPhoneNumber,
        if (installationNotes != null) 'installationNotes': installationNotes,
        if (lastUpdatedAt != null)
          'lastUpdatedAt': lastUpdatedAt!.toIso8601String(),
        if (updatedByUserId != null) 'updatedByUserId': updatedByUserId,
      };

  factory DeviceInstallationProfile.fromJson(Map<String, dynamic> json) =>
      DeviceInstallationProfile(
        deviceId: json['deviceId'] as int,
        hasRelay: json['hasRelay'] as bool? ?? false,
        hasImmobilizer: json['hasImmobilizer'] as bool? ?? false,
        hasIgnitionInput: json['hasIgnitionInput'] as bool? ?? false,
        hasDoorInput: json['hasDoorInput'] as bool? ?? false,
        hasFuelSensor: json['hasFuelSensor'] as bool? ?? false,
        hasTemperatureSensor: json['hasTemperatureSensor'] as bool? ?? false,
        hasSosButton: json['hasSosButton'] as bool? ?? false,
        hasOutput1: json['hasOutput1'] as bool? ?? false,
        hasOutput2: json['hasOutput2'] as bool? ?? false,
        smsEnabled: json['smsEnabled'] as bool? ?? false,
        simPhoneNumber: json['simPhoneNumber'] as String?,
        installationNotes: json['installationNotes'] as String?,
        lastUpdatedAt: json['lastUpdatedAt'] == null
            ? null
            : DateTime.tryParse(json['lastUpdatedAt'] as String),
        updatedByUserId: json['updatedByUserId'] as String?,
      );

  DeviceInstallationProfile copyWith({
    bool? hasRelay,
    bool? hasImmobilizer,
    bool? hasIgnitionInput,
    bool? hasDoorInput,
    bool? hasFuelSensor,
    bool? hasTemperatureSensor,
    bool? hasSosButton,
    bool? hasOutput1,
    bool? hasOutput2,
    bool? smsEnabled,
    String? simPhoneNumber,
    String? installationNotes,
    DateTime? lastUpdatedAt,
    String? updatedByUserId,
  }) =>
      DeviceInstallationProfile(
        deviceId: deviceId,
        hasRelay: hasRelay ?? this.hasRelay,
        hasImmobilizer: hasImmobilizer ?? this.hasImmobilizer,
        hasIgnitionInput: hasIgnitionInput ?? this.hasIgnitionInput,
        hasDoorInput: hasDoorInput ?? this.hasDoorInput,
        hasFuelSensor: hasFuelSensor ?? this.hasFuelSensor,
        hasTemperatureSensor:
            hasTemperatureSensor ?? this.hasTemperatureSensor,
        hasSosButton: hasSosButton ?? this.hasSosButton,
        hasOutput1: hasOutput1 ?? this.hasOutput1,
        hasOutput2: hasOutput2 ?? this.hasOutput2,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        simPhoneNumber: simPhoneNumber ?? this.simPhoneNumber,
        installationNotes: installationNotes ?? this.installationNotes,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      );
}
