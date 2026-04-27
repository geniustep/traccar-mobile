import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _ao = AndroidOptions(encryptedSharedPreferences: true);

  // ── Traccar Basic-Auth credentials ─────────────────────────────────────────

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: StorageKeys.traccarEmail,    value: email,    aOptions: _ao);
    await _storage.write(key: StorageKeys.traccarPassword, value: password, aOptions: _ao);
  }

  Future<String?> getEmail()    => _storage.read(key: StorageKeys.traccarEmail,    aOptions: _ao);
  Future<String?> getPassword() => _storage.read(key: StorageKeys.traccarPassword, aOptions: _ao);

  /// Returns `Authorization: Basic ...` header value, or null if not logged in.
  Future<String?> getBasicAuthHeader() async {
    final email    = await getEmail();
    final password = await getPassword();
    if (email == null || password == null) return null;
    final encoded = base64.encode(utf8.encode('$email:$password'));
    return 'Basic $encoded';
  }

  Future<bool> hasCredentials() async {
    final email = await getEmail();
    return email != null && email.isNotEmpty;
  }

  Future<void> saveUserId(String id) =>
      _storage.write(key: StorageKeys.traccarUserId, value: id, aOptions: _ao);

  Future<String?> getUserId() =>
      _storage.read(key: StorageKeys.traccarUserId, aOptions: _ao);

  /// `JSESSIONID` from Traccar `Set-Cookie` after POST /session (used for WebSocket).
  Future<void> saveJsessionId(String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: StorageKeys.traccarJsessionId, aOptions: _ao);
    } else {
      await _storage.write(
        key: StorageKeys.traccarJsessionId,
        value: value,
        aOptions: _ao,
      );
    }
  }

  Future<String?> getJsessionId() =>
      _storage.read(key: StorageKeys.traccarJsessionId, aOptions: _ao);

  // ── Legacy token methods (kept so existing code doesn't break) ─────────────

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token, aOptions: _ao);

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken, aOptions: _ao);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token, aOptions: _ao);

  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken, aOptions: _ao);

  Future<void> clearAll() => _storage.deleteAll(aOptions: _ao);
}
