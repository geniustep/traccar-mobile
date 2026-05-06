import 'package:flutter/foundation.dart';

/// Describes which Traccar command types are supported by a specific
/// device brand/model/protocol combination.
///
/// Instances are defined in [DeviceProfilesCatalog].
/// Used by [CommandCapabilityService] as one of the three sources that
/// determine whether a command is available.
@immutable
class DeviceCommandProfile {
  const DeviceCommandProfile({
    required this.brand,
    required this.model,
    required this.protocol,
    this.nativeSupportedTypes = const {},
    this.customCommandTypes = const {},
    this.savedCommandTypes = const {},
    this.unsupportedTypes = const {},
    this.supportsSmsCommands = false,
    this.supportsQueue = true,
    this.notes,
  });

  /// Brand name, e.g. `'Teltonika'`, `'Queclink'`.
  final String brand;

  /// Lower-cased model identifier matching `TraccarDevice.model?.toLowerCase()`.
  final String model;

  /// Traccar protocol name, e.g. `'teltonika'`, `'gt06'`.
  final String protocol;

  /// Traccar native command types this model supports out-of-the-box.
  final Set<String> nativeSupportedTypes;

  /// Types that must be sent as `type='custom'` with a `data` attribute.
  final Set<String> customCommandTypes;

  /// Types that require a pre-saved command in Traccar.
  final Set<String> savedCommandTypes;

  /// Types explicitly NOT supported by this model.
  final Set<String> unsupportedTypes;

  final bool supportsSmsCommands;
  final bool supportsQueue;
  final String? notes;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool supportsNative(String type) => nativeSupportedTypes.contains(type);
  bool supportsCustom(String type) => customCommandTypes.contains(type);
  bool supportsSaved(String type) => savedCommandTypes.contains(type);
  bool isExplicitlyUnsupported(String type) => unsupportedTypes.contains(type);

  bool supportsAny(String type) =>
      nativeSupportedTypes.contains(type) ||
      customCommandTypes.contains(type) ||
      savedCommandTypes.contains(type);

  /// Returns `true` if this profile matches [deviceModel] (case-insensitive).
  bool matchesModel(String? deviceModel) =>
      deviceModel != null &&
      deviceModel.toLowerCase() == model.toLowerCase();
}
