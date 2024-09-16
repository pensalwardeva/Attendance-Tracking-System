// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../controller/auth_controller.dart';
import '../model/auth_model.dart';


class AuthProvider with ChangeNotifier {
  AuthModel? _user;
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  AuthModel? get user => _user;
  bool get isLoading => _isLoading;

  // Add isLoggedIn getter
  bool get isLoggedIn => _user != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authController.login(email, password);
    } catch (e) {
      _isLoading = false;
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveLocation(Position position) async {
    if (_user != null) {
      await _authController.saveUserLocation(_user!, position);
    }
  }

  Future<void> logout() async {
    await _authController.logout();
    _user = null;
    notifyListeners();
  }
}
