import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_cache_service.dart';
import 'client_location_cache_service.dart';
import 'client_id_mapping_service.dart';
import 'api_service.dart';

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
      print('🔐 Attempting login with email: $email');

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

      print('🌐 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);

        // Check if response is an object (single user) or array
        Map<String, dynamic> userData;
        if (responseBody is Map<String, dynamic>) {
          // Single user object
          userData = responseBody;
        } else if (responseBody is List<dynamic> && responseBody.isNotEmpty) {
          // Array with user data
          userData = responseBody[0];
        } else {
          throw Exception('Invalid login credentials - no user data found');
        }

        _userData = userData;
        _isAuthenticated = true;

        // Save user data to persistent storage
        await _saveUserData(_userData!);

        print('✅ Login successful for user: ${userData['name']}');
        notifyListeners();
      } else {
        throw Exception(
            'Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or PIN');
      } else {
        throw Exception(
            'Login failed. Please check your connection and try again. Error: $e');
      }
    }
  }

  Future<void> logout() async {
    print('🚪 Logging out user...');

    // Clear all cache data
    try {
      print('🗑️ Clearing all cache data...');

      // Clear daily cache (client data)
      await DailyCacheService.clearAllCache();

      // Clear location cache
      await ClientLocationCacheService.instance.clearAllCache();

      // Clear client ID mappings
      await ClientIdMappingService.instance.clearMappings();

      // Clear API cache
      final apiService = ApiService();
      apiService.clearCache();

      print('✅ All cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing cache during logout: $e');
      // Continue with logout even if cache clearing fails
    }

    // Clear auth state
    _isAuthenticated = false;
    _userData = null;
    await _clearUserData();

    print('✅ Logout completed');
    notifyListeners();
  }
}
