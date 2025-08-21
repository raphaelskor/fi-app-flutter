import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentLocation;
  double? _latitude;
  double? _longitude;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentLocation => _currentLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  Map<String, dynamic>? get userData => _userData;

  AuthService() {
    _initializeLocation();
    _checkSavedLogin();
  }

  // Check if user is already logged in
  Future<void> _checkSavedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        _userData = json.decode(userDataString);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking saved login: $e');
    }
  }

  // Save user data to persistent storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Clear saved user data
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentLocation = 'Location services are disabled.';
      notifyListeners();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentLocation = 'Location permissions are denied';
        notifyListeners();
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _currentLocation =
          'Location permissions are permanently denied, we cannot request permissions.';
      notifyListeners();
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _latitude = position.latitude;
    _longitude = position.longitude;
    _currentLocation =
        'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
    notifyListeners();
  }

  Future<void> login(String email, String pin) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://n8n.skorcard.app/webhook/e155f504-e34f-43e7-ba3e-5fce035b27c5'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'pin': pin,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData.isNotEmpty) {
          _userData = responseData[0];
          _isAuthenticated = true;

          // Save user data to persistent storage
          await _saveUserData(_userData!);

          notifyListeners();
        } else {
          throw Exception('Invalid login credentials');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or PIN');
      } else {
        throw Exception(
            'Login failed. Please check your connection and try again.');
      }
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userData = null;
    await _clearUserData();
    notifyListeners();
  }
}
