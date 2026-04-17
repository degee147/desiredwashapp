import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AppUser? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthProvider(this._api);

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null && _token != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    _api.setToken(token);
    _token = token;
    try {
      _user = await _api.getProfile();
      notifyListeners();
    } catch (_) {
      await _logout();
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _run(() => _api.signUpWithEmail(
          name: name,
          email: email,
          password: password,
          phone: phone,
        ));
  }

  Future<bool> signInWithEmail(
      {required String email, required String password}) async {
    return _run(() => _api.signInWithEmail(email: email, password: password));
  }

  Future<bool> signInWithGoogle(String idToken,
      {String? name, String? email, String? avatar}) async {
    return _run(() => _api.signInWithSocial(
          provider: 'google',
          idToken: idToken,
          name: name,
          email: email,
          avatarUrl: avatar,
        ));
  }

  Future<bool> signInWithApple(String idToken,
      {String? name, String? email}) async {
    return _run(() => _api.signInWithSocial(
          provider: 'apple',
          idToken: idToken,
          name: name,
          email: email,
        ));
  }

  Future<bool> _run(Future<AuthResult> Function() call) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await call();
      _user = result.user;
      _token = result.token;
      _api.setToken(result.token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result.token);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _logout();
    notifyListeners();
  }

  Future<void> _logout() async {
    _user = null;
    _token = null;
    _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Fetches the latest profile from the backend (balance, zone, address, etc.)
  /// and updates local state. Silently swallowed on error — stale data is
  /// better than a broken screen.
  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      _user = await _api.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  void updateLocalUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
