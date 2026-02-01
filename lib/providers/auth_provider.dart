import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _service = AuthService();
  final TokenStore _store = TokenStore();

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final u = await _service.login(email: email, password: password);
      _user = u;

      if (u.token != null) {
        await _store.saveToken(u.token!);
      }
      await _store.saveCredential(email, password);

      _loading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final cred = await _store.getCredential();
    if (cred == null) return false;

    return await login(
      email: cred['email']!,
      password: cred['password']!,
    );
  }

  Future<void> logout() async {
    try {
      final token = _user?.token;
      if (token != null) {
        await _service.logout(token);
      }
    } catch (_) {}

    _user = null;
    await _store.clear();
    notifyListeners();
  }
}
