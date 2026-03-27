import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final json = await api.post(
      ApiConfig.login,
      auth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final token = (data['token'] ?? data['access_token'])?.toString();
    final userJson = (data['user'] ?? data) as Map<String, dynamic>;

    final user = UserModel.fromJson(userJson);

    if (token != null && token.isNotEmpty) {
      user.token = token;
    }

    return user;
  }

  Future<UserModel> me() async {
    final json = await api.get(ApiConfig.me);

    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final user = UserModel.fromJson(data);

    return user;
  }

  Future<void> logout() async {
    await api.post(ApiConfig.logout);
  }
}