import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _passKey = 'auth_password';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveCredential(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passKey, password);
  }

  Future<Map<String, String>?> getCredential() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final pass = prefs.getString(_passKey);
    if (email == null || pass == null) return null;
    return {'email': email, 'password': pass};
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passKey);
  }
}
