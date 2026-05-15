import 'package:dio/dio.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/user_model.dart';

/// Result of POST /session including optional [jsessionId] from `Set-Cookie`
/// (needed for `wss://.../socket` on some Nginx + Traccar setups).
typedef TraccarLoginResult = ({UserModel user, String? jsessionId});

/// Handles all Traccar session / auth HTTP calls.
///
/// Traccar auth uses:
/// - POST /session  →  Content-Type: application/x-www-form-urlencoded
/// - GET  /session  →  returns current logged-in user
/// - DELETE /session → logout
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Login via POST /session with form-urlencoded body.
  /// Returns user + optional JSESSIONID from `Set-Cookie` (for WebSocket).
  Future<TraccarLoginResult> login(String email, String password) async {
    AppLogger.auth('POST /session (form-urlencoded)');
    final response = await _client.dio.post<dynamic>(
      TraccarEndpoints.sessionCreate,
      data: 'email=${Uri.encodeComponent(email)}'
          '&password=${Uri.encodeComponent(password)}',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        headers: {'Authorization': null},
      ),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected session response');
    }
    final user = UserModel.fromJson(data);
    final jsessionId = _parseJsessionId(response);
    AppLogger.auth('Session created successfully');
    AppLogger.auth('JSESSIONID stored: ${jsessionId != null ? 'yes' : 'no'}');
    return (user: user, jsessionId: jsessionId);
  }

  static String? _parseJsessionId(Response<dynamic> response) {
    // Prefer [Headers.forEach] — some stacks expose set-cookie differently
    // than [map.entries] on Android/HTTP/2.
    String? id;
    response.headers.forEach((name, values) {
      if (name.toLowerCase() != 'set-cookie') return;
      for (final line in values) {
        final m = RegExp(r'JSESSIONID=([^;]+)').firstMatch(line);
        if (m != null) id = m.group(1);
      }
    });
    return id;
  }

  /// Verify stored credentials by fetching the current session.
  ///
  /// Traccar GET /session returns the current user when a valid session or
  /// Basic Auth header is present. We override Content-Type to avoid 415
  /// on servers that reject `application/json` for this endpoint.
  Future<UserModel> getSession() async {
    final result = await _client.get<Map<String, dynamic>>(
      TraccarEndpoints.sessionGet,
      fromJson: (json) => json as Map<String, dynamic>,
      options: Options(contentType: null),
    );
    return UserModel.fromJson(result.getOrThrow());
  }

  /// Logout — invalidates the session on the server.
  Future<void> logout() async {
    (await _client.delete(TraccarEndpoints.sessionDelete)).getOrThrow();
  }
}
