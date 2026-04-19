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
    final response = await _dataSource.login(email, password);
    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final userData = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData).toEntity();

    await _storage.saveAccessToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
    await _storage.saveUserId(user.id);
    await _prefs.setString(StorageKeys.userJson, jsonEncode(userData));

    return (user, accessToken, refreshToken);
  }

  @override
  Future<UserEntity> getMe() async {
    final model = await _dataSource.getMe();
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
  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final json = _prefs.getString(StorageKeys.userJson);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>).toEntity();
    } catch (_) {
      return null;
    }
  }
}
