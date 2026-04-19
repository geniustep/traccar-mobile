import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _client.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return _client.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  Future<UserModel> getMe() async {
    return _client.get<UserModel>(
      ApiConstants.me,
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _client.post<void>(ApiConstants.logout);
  }
}
