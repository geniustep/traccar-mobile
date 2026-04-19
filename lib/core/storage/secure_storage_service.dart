import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _options = AndroidOptions(encryptedSharedPreferences: true);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token, aOptions: _options);

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken, aOptions: _options);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token, aOptions: _options);

  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken, aOptions: _options);

  Future<void> saveUserId(String id) =>
      _storage.write(key: StorageKeys.userId, value: id, aOptions: _options);

  Future<String?> getUserId() =>
      _storage.read(key: StorageKeys.userId, aOptions: _options);

  Future<void> clearAll() => _storage.deleteAll(aOptions: _options);
}
