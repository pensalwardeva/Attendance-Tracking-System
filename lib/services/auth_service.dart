// services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../model/auth_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthModel?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        return AuthModel(uid: user.uid, email: email);
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> saveUserLocation(String uid, String email, Position position) async {
    await _firestore.collection('user_locations').add({
      'uid': uid,
      'email': email,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'login_time': Timestamp.now(),
    });
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
