import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../entities/device_installation_profile.dart';

/// Manages [DeviceInstallationProfile] persistence per device.
///
/// Profiles are stored in SharedPreferences as JSON.
/// A missing profile returns a safe default (all flags = false).
class DeviceInstallationService {
  DeviceInstallationService(this._prefs);

  final SharedPreferences _prefs;

  static String _key(int deviceId) => 'install_profile_$deviceId';

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the stored profile for [deviceId], or a safe default.
  DeviceInstallationProfile getProfile(int deviceId) {
    final raw = _prefs.getString(_key(deviceId));
    if (raw == null) return DeviceInstallationProfile.defaultFor(deviceId);
    try {
      return DeviceInstallationProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return DeviceInstallationProfile.defaultFor(deviceId);
    }
  }

  /// Returns profiles for all devices whose IDs are in [deviceIds].
  Map<int, DeviceInstallationProfile> getProfiles(List<int> deviceIds) {
    return {for (final id in deviceIds) id: getProfile(id)};
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Persists [profile] for the device it belongs to.
  Future<void> saveProfile(DeviceInstallationProfile profile) async {
    await _prefs.setString(
      _key(profile.deviceId),
      jsonEncode(profile.toJson()),
    );
  }

  /// Updates specific fields on an existing profile for [deviceId].
  Future<DeviceInstallationProfile> updateProfile(
    int deviceId, {
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
    String? updatedByUserId,
  }) async {
    final existing = getProfile(deviceId);
    final updated = existing.copyWith(
      hasRelay: hasRelay,
      hasImmobilizer: hasImmobilizer,
      hasIgnitionInput: hasIgnitionInput,
      hasDoorInput: hasDoorInput,
      hasFuelSensor: hasFuelSensor,
      hasTemperatureSensor: hasTemperatureSensor,
      hasSosButton: hasSosButton,
      hasOutput1: hasOutput1,
      hasOutput2: hasOutput2,
      smsEnabled: smsEnabled,
      simPhoneNumber: simPhoneNumber,
      installationNotes: installationNotes,
      lastUpdatedAt: DateTime.now(),
      updatedByUserId: updatedByUserId,
    );
    await saveProfile(updated);
    return updated;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> removeProfile(int deviceId) async {
    await _prefs.remove(_key(deviceId));
  }

  /// Clears ALL installation profiles (use with caution).
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('install_profile_'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
