import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/storage_keys.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource, this._storage, this._prefs);

  final AuthRemoteDataSource _dataSource;
  final SecureStorageService _storage;
  final SharedPreferences _prefs;

  @override
  Future<(UserEntity, String, String)> login({
    required String email,
    required String password,
  }) async {
    // 1. Verify credentials by calling POST /session
    final result = await _dataSource.login(email, password);
    final userModel = result.user;

    // 2. Persist credentials for Basic auth + JSESSIONID for WebSocket
    await _storage.saveCredentials(email, password);
    await _storage.saveUserId(userModel.id.toString());
    await _storage.saveJsessionId(result.jsessionId);

    // 3. Cache user JSON locally
    await _prefs.setString(StorageKeys.userJson, jsonEncode(userModel.toJson()));

    final user = userModel.toEntity();
    // Return dummy token strings — Traccar uses Basic auth, no real tokens
    return (user, email, password);
  }

  @override
  Future<UserEntity> getMe() async {
    final model = await _dataSource.getSession();
    await _prefs.setString(StorageKeys.userJson, jsonEncode(model.toJson()));
    return model.toEntity();
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } catch (_) {}
    await _storage.clearAll();
    await _prefs.remove(StorageKeys.userJson);
  }

  @override
  Future<bool> isLoggedIn() => _storage.hasCredentials();

  @override
  Future<void> ensureTraccarSocketSession() async {
    if (await _storage.getJsessionId() != null) return;
    final email = await _storage.getEmail();
    final password = await _storage.getPassword();
    if (email == null || password == null) return;
    try {
      final r = await _dataSource.login(email, password);
      await _storage.saveJsessionId(r.jsessionId);
    } catch (_) {
      // WebSocket will still use Basic auth if possible.
    }
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final json = _prefs.getString(StorageKeys.userJson);
    if (json == null) return null;
    try {
      return UserModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      ).toEntity();
    } catch (_) {
      return null;
    }
  }
}
