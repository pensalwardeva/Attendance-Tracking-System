// controllers/auth_controller.dart
import 'package:geolocator/geolocator.dart';

import '../model/auth_model.dart';
import '../services/auth_service.dart';


class AuthController {
  final AuthService _authService = AuthService();

  Future<AuthModel?> login(String email, String password) async {
    try {
      AuthModel? user = await _authService.login(email, password);
      if (user != null) {
        return user;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> saveUserLocation(AuthModel user, Position position) async {
    await _authService.saveUserLocation(user.uid, user.email, position);
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
