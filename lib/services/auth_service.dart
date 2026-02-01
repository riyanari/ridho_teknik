import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = _safeJson(res.body);

    if (res.statusCode == 200) {
      // support: {data:{user,token}} atau {user,token}
      final data = (json['data'] ?? json) as Map<String, dynamic>;
      final token = (data['token'] ?? data['access_token'])?.toString();

      final userJson = (data['user'] ?? data) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      if (token != null && token.isNotEmpty) {
        user.token = "Bearer $token";
      }
      return user;
    }

    final msg = (json['message'] ?? json['error'] ?? 'Login gagal').toString();
    throw Exception('$msg (${res.statusCode})');
  }

  Future<void> logout(String token) async {
    final res = await http.post(
      Uri.parse(ApiConfig.logout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (res.statusCode != 200) {
      final json = _safeJson(res.body);
      final msg = (json['message'] ?? 'Logout gagal').toString();
      throw Exception('$msg (${res.statusCode})');
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
