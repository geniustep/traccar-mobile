import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<(UserEntity, String accessToken, String refreshToken)> login({
    required String email,
    required String password,
  });

  Future<UserEntity> getMe();

  Future<void> logout();

  Future<bool> isLoggedIn();

  Future<UserEntity?> getCachedUser();

  /// Re-run POST /session if [JSESSIONID] is missing (e.g. app update) so
  /// [TraccarSocketService] can send `Cookie` on the WebSocket handshake.
  Future<void> ensureTraccarSocketSession();
}
