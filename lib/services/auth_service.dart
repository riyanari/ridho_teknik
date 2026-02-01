import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.login);

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final json = _safeJson(res.body);

    if (res.statusCode == 200) {
      // dukung format: {data:{user, token}} atau {user, token}
      final data = (json['data'] ?? json) as Map<String, dynamic>;

      final token = (data['token'] ?? data['access_token'])?.toString();
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;

      final user = UserModel.fromJson(userJson);
      user.token = token != null ? "Bearer $token" : null;
      return user;
    }

    final msg = json['message']?.toString() ?? 'Gagal login (${res.statusCode})';
    throw Exception(msg);
  }

  Future<void> logout(String token) async {
    final url = Uri.parse(ApiConfig.logout);

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to logout: ${res.statusCode}');
    }
  }

  Map<String, dynamic> _safeJson(String s) {
    try {
      final j = jsonDecode(s);
      if (j is Map<String, dynamic>) return j;
      return {'data': j};
    } catch (_) {
      return {'message': s};
    }
  }
}
