import '../entities/device_command_profile.dart';

/// Static catalog of known [DeviceCommandProfile] entries.
///
/// Used by [CommandCapabilityService] as the model-based support source.
/// Add a new entry for every GPS tracker brand/model you add support for.
class DeviceProfilesCatalog {
  DeviceProfilesCatalog._();

  // ── Teltonika FMC130 ───────────────────────────────────────────────────────
  static const fmc130 = DeviceCommandProfile(
    brand: 'Teltonika',
    model: 'fmc130',
    protocol: 'teltonika',
    nativeSupportedTypes: {
      'positionSingle',
      'positionPeriodic',
      'positionStop',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'getVersion',
      'identification',
      'outputControl',
      'alarmArm',
      'alarmDisarm',
      'alarmSpeed',
      'alarmVibration',
      'alarmDoor',
      'sosNumber',
      'setTimezone',
      'getDeviceStatus',
      'getModemStatus',
    },
    customCommandTypes: {
      'getio',
      'getgps',
      'getgsm',
      'custom',
    },
    unsupportedTypes: {
      'configuration', // APN managed via Teltonika configurator
    },
    supportsSmsCommands: true,
    supportsQueue: true,
  );

  // ── Teltonika FMC150 ───────────────────────────────────────────────────────
  static const fmc150 = DeviceCommandProfile(
    brand: 'Teltonika',
    model: 'fmc150',
    protocol: 'teltonika',
    nativeSupportedTypes: {
      'positionSingle',
      'positionPeriodic',
      'positionStop',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'getVersion',
      'identification',
      'outputControl',
      'alarmArm',
      'alarmDisarm',
      'alarmSpeed',
      'alarmVibration',
      'alarmDoor',
      'sosNumber',
      'setTimezone',
      'getDeviceStatus',
      'getModemStatus',
    },
    customCommandTypes: {
      'getio',
      'getgps',
      'getgsm',
      'custom',
    },
    supportsSmsCommands: true,
    supportsQueue: true,
  );

  // ── Teltonika FMB140 ───────────────────────────────────────────────────────
  static const fmb140 = DeviceCommandProfile(
    brand: 'Teltonika',
    model: 'fmb140',
    protocol: 'teltonika',
    nativeSupportedTypes: {
      'positionSingle',
      'positionPeriodic',
      'positionStop',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'getVersion',
      'identification',
      'outputControl',
      'alarmArm',
      'alarmDisarm',
      'alarmSpeed',
      'alarmVibration',
      'alarmDoor',
      'sosNumber',
      'setTimezone',
      'getDeviceStatus',
      'getModemStatus',
    },
    customCommandTypes: {
      'getio',
      'getgps',
      'getgsm',
      'custom',
    },
    supportsSmsCommands: true,
    supportsQueue: true,
  );

  // ── Teltonika FMC920 ───────────────────────────────────────────────────────
  static const fmc920 = DeviceCommandProfile(
    brand: 'Teltonika',
    model: 'fmc920',
    protocol: 'teltonika',
    nativeSupportedTypes: {
      'positionSingle',
      'positionPeriodic',
      'positionStop',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'getVersion',
      'identification',
      'outputControl',
      'alarmArm',
      'alarmDisarm',
      'alarmSpeed',
      'setTimezone',
      'getDeviceStatus',
      'getModemStatus',
    },
    customCommandTypes: {
      'getio',
      'getgps',
      'getgsm',
      'custom',
    },
    supportsSmsCommands: true,
    supportsQueue: true,
  );

  // ── Queclink GV300 ────────────────────────────────────────────────────────
  static const gv300 = DeviceCommandProfile(
    brand: 'Queclink',
    model: 'gv300',
    protocol: 'gl200',
    nativeSupportedTypes: {
      'positionSingle',
      'positionPeriodic',
      'positionStop',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'getVersion',
      'outputControl',
      'setTimezone',
      'getDeviceStatus',
    },
    supportsSmsCommands: true,
    supportsQueue: true,
  );

  // ── Coban TK103B ──────────────────────────────────────────────────────────
  static const tk103b = DeviceCommandProfile(
    brand: 'Coban',
    model: 'tk103b',
    protocol: 'gt06',
    nativeSupportedTypes: {
      'positionSingle',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'alarmArm',
      'alarmDisarm',
      'setTimezone',
      'getDeviceStatus',
    },
    customCommandTypes: {'custom'},
    unsupportedTypes: {
      'outputControl',
      'getModemStatus',
      'getio',
      'getgps',
      'getgsm',
    },
    supportsSmsCommands: true,
    supportsQueue: false,
    notes: 'GT06 protocol — limited command set. SMS recommended for most operations.',
  );

  // ── Concox GT06N ─────────────────────────────────────────────────────────
  static const gt06n = DeviceCommandProfile(
    brand: 'Concox',
    model: 'gt06n',
    protocol: 'gt06',
    nativeSupportedTypes: {
      'positionSingle',
      'engineStop',
      'engineResume',
      'rebootDevice',
      'alarmArm',
      'alarmDisarm',
      'setTimezone',
      'getDeviceStatus',
    },
    customCommandTypes: {'custom'},
    unsupportedTypes: {
      'outputControl',
      'getModemStatus',
    },
    supportsSmsCommands: true,
    supportsQueue: false,
  );

  // ── All known profiles ────────────────────────────────────────────────────

  static const List<DeviceCommandProfile> all = [
    fmc130,
    fmc150,
    fmb140,
    fmc920,
    gv300,
    tk103b,
    gt06n,
  ];

  // ── Lookup ────────────────────────────────────────────────────────────────

  /// Returns the profile matching [deviceModel] (case-insensitive), or `null`
  /// if the model is unknown — callers fall back to Traccar API types.
  static DeviceCommandProfile? findByModel(String? deviceModel) {
    if (deviceModel == null || deviceModel.isEmpty) return null;
    try {
      return all.firstWhere((p) => p.matchesModel(deviceModel));
    } catch (_) {
      return null;
    }
  }

  /// Returns the known Traccar native types for [deviceModel], or `null`.
  static Set<String>? nativeTypesFor(String? deviceModel) =>
      findByModel(deviceModel)?.nativeSupportedTypes;
}
