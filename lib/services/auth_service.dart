import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String username, String password) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    if (username == 'user' && password == 'password') {
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    // In a real app, you'd register the user in your backend
    _isAuthenticated = true;
    notifyListeners();
  }
}

