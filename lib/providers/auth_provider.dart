import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({
    required this.service,
    required this.store,
  });

  final AuthService service;
  final TokenStore store;

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  bool _initialized = false;
  bool get initialized => _initialized;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      final user = await service.login(
        email: email,
        password: password,
      );

      _user = user;

      if (user.token != null && user.token!.isNotEmpty) {
        await store.saveToken(user.token!);
      }

      await store.saveEmail(email);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    _errorMessage = null;
    _setLoading(true);

    try {
      final token = await store.getToken();

      if (token == null || token.isEmpty) {
        _initialized = true;
        return false;
      }

      final user = await service.me();
      user.token = token;
      _user = user;
      _initialized = true;
      return true;
    } catch (e) {
      _user = null;
      _initialized = true;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await store.clear();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      final token = await store.getToken();
      if (token != null && token.isNotEmpty) {
        await service.logout();
      }
    } catch (_) {
      // tetap clear session lokal walaupun API logout gagal
    }

    _user = null;
    _errorMessage = null;
    await store.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}