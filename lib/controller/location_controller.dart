import 'package:geolocator/geolocator.dart';
import '../model/location_model.dart';
import '../services/location_service.dart';

class LocationController {
  final LocationService _locationService = LocationService();

  Future<LocationModel> getCurrentLocation() async {
    Position position = await _locationService.getCurrentLocation();
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return _locationService.calculateDistance(lat1, lon1, lat2, lon2);
  }
}
