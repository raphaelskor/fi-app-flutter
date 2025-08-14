import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentLocation;
  double? _latitude;
  double? _longitude;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentLocation => _currentLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  AuthService() {
    _initializeLocation();
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
      _currentLocation = 'Location permissions are permanently denied, we cannot request permissions.';
      notifyListeners();
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _latitude = position.latitude;
    _longitude = position.longitude;
    _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    if (username == 'user' && password == 'password') {
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Invalid username or password');
    }
  }

  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));
    _isAuthenticated = false;
    notifyListeners();
  }
}
