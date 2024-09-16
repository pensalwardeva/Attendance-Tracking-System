import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserLocation(
      String uid,
      double latitude,
      double longitude,
      double altitude,
      double heading,
      double speed,
      double accuracy,
      double headingAccuracy,
      double speedAccuracy,
      double altitudeAccuracy,
      ) async {
    await _firestore.collection('user_locations').add({
      'uid': uid,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'headingAccuracy': headingAccuracy,
      'speedAccuracy': speedAccuracy,
      'altitudeAccuracy': altitudeAccuracy,
      'login_time': Timestamp.now(),
    });
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDesignatedLocations() async {
    try {
      final snapshot = await _firestore.collection('designated_locations').get();
      return snapshot.docs;
    } catch (e) {
      print('Error getting designated locations: $e');
      return [];
    }
  }

  Future<void> saveNewLocation(Map<String, dynamic> newLocation) async {
    try {
      await _firestore.collection('designated_locations').add(newLocation);
    } catch (e) {
      print('Error saving new location: $e');
    }
  }
}