import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

class AuthProvider with ChangeNotifier {
  final AuthService service;
  final TokenStore store;

  AuthProvider({required this.service, required this.store});

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final u = await service.login(email: email, password: password);
      _user = u;

      if (u.token != null) await store.saveToken(u.token!);
      await store.saveCredential(email, password);

      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> tryAutoLogin() async {
    final cred = await store.getCredential();
    if (cred == null) return false;

    return await login(
      email: cred['email']!,
      password: cred['password']!,
    );
  }

  Future<void> logout() async {
    try {
      final token = _user?.token;
      if (token != null) await service.logout(token);
    } catch (_) {}

    _user = null;
    await store.clear();
    notifyListeners();
  }
}
