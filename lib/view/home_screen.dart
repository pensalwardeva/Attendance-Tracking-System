import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firestore_services.dart';
import 'login_screen.dart';

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  Position? _currentPosition;
  bool _isWithinRange = true;
  Duration logoutGracePeriod = Duration(minutes: 2);
  Duration checkInterval = Duration(minutes: 5); // Check location every 5 minutes

  @override
  void initState() {
    super.initState();
    _checkLocationAndStartTracking();
    _checkLocationPeriodically(); // Start periodic location checking
  }

  Future<void> _checkLocationAndStartTracking() async {
    bool hasPermission = await _checkPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission is denied. Please enable it.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Position position = await _getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestoreService.saveUserLocation(
        user.uid,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentPosition!.altitude,
        _currentPosition!.heading,
        _currentPosition!.speed,
        _currentPosition!.accuracy,
        _currentPosition!.headingAccuracy,
        _currentPosition!.speedAccuracy,
        _currentPosition!.altitudeAccuracy,
      );
    }

    await _checkUserLocation();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    );
  }

  double _calculateDistance(Position position1, Position position2) {
    return Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
  }

  Future<void> _checkUserLocation() async {
    if (_currentPosition == null) return;

    final designatedLocations = await _firestoreService.getDesignatedLocations();
    bool isWithinRange = false;

    for (var locationDoc in designatedLocations) {
      final location = locationDoc.data();
      final latitude = location?['latitude'] as double? ?? 0;
      final longitude = location?['longitude'] as double? ?? 0;

      final designatedPosition = Position(
        latitude: latitude,
        longitude: longitude,
        altitude: 0,
        heading: 0,
        speed: 0,
        accuracy: 0,
        headingAccuracy: 0,
        speedAccuracy: 0,
        timestamp: DateTime.now(),
        altitudeAccuracy: 0,
      );

      final distance = _calculateDistance(
        _currentPosition!,
        designatedPosition,
      );

      // Adjusted the threshold to 100 meters for tolerance
      if (distance <= 100) {
        isWithinRange = true;
        break;
      }
    }

    // Grace period implementation
    if (!isWithinRange) {
      if (_isWithinRange) {
        // Start grace period timer
        _isWithinRange = false;
        await Future.delayed(logoutGracePeriod);

        // Check if the user is still out of range after the grace period
        if (!_isWithinRange) {
          await _auth.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Login(),
            ),
          );
        }
      }
    } else {
      _isWithinRange = true; // User is back in range
    }
  }

  // Periodically check location every 5 minutes
  Future<void> _checkLocationPeriodically() async {
    while (true) {
      await Future.delayed(checkInterval); // Wait for the specified interval
      await _checkUserLocation();
    }
  }

  Future<void> _saveNewLocation() async {
    if (_currentPosition == null) return;

    final newLocation = {
      'type': 'client', // or 'office' based on context
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
    };

    bool saveLocation = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save New Location'),
        content: Text('Do you want to save this new location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (saveLocation) {
      await _firestoreService.saveNewLocation(newLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white, // This will change the back arrow color to white
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _currentPosition != null
                  ? Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Current Position:',
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Latitude: ${_currentPosition!.latitude}\nLongitude: ${_currentPosition!.longitude}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : CircularProgressIndicator(),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _checkUserLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                ),
                child: Text('Check Location'),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveNewLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                ),
                child: Text('Save New Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
