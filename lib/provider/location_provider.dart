import 'package:flutter/material.dart';

import '../controller/location_controller.dart';
import '../model/location_model.dart';


class LocationProvider with ChangeNotifier {
  LocationModel? _currentLocation;
  final LocationController _locationController = LocationController();

  LocationModel? get currentLocation => _currentLocation;

  Future<void> trackLocation() async {
    _currentLocation = await _locationController.getCurrentLocation();
    notifyListeners();
  }

  bool isWithinRange(LocationModel location, double targetLat, double targetLon) {
    double distance = _locationController.calculateDistance(
        location.latitude, location.longitude, targetLat, targetLon);
    return distance <= 50;
  }
}
