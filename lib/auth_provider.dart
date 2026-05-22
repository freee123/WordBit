import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  String? _username;
  bool _loading = false;
  String? _error;

  String? get username => _username;
  bool get isLoggedIn => ApiClient.isLoggedIn;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.login(username, password);
      _username = username;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.register(username, password);
      _username = username;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    _username = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
