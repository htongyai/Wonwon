import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService with ChangeNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  LocationPermissionStatus get permissionStatus => _permissionStatus;

  // Convert Position to LatLng for Google Maps
  LatLng? get currentLatLng =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;

  LocationService() {
    // Check permission status on initialization
    _checkPermission();
  }

  // Check if location permissions are granted
  Future<void> _checkPermission() async {
    final locationPermission = await Geolocator.checkPermission();

    switch (locationPermission) {
      case LocationPermission.denied:
        _permissionStatus = LocationPermissionStatus.denied;
        break;
      case LocationPermission.deniedForever:
        _permissionStatus = LocationPermissionStatus.permanentlyDenied;
        break;
      case LocationPermission.whileInUse:
        _permissionStatus = LocationPermissionStatus.whileInUse;
        break;
      case LocationPermission.always:
        _permissionStatus = LocationPermissionStatus.always;
        break;
      case LocationPermission.unableToDetermine:
        _permissionStatus = LocationPermissionStatus.unknown;
        break;
    }

    notifyListeners();
  }

  // Request location permission
  Future<bool> requestPermission() async {
    final permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      _permissionStatus = LocationPermissionStatus.whileInUse;
      notifyListeners();
      return true;
    } else if (permissionStatus.isPermanentlyDenied) {
      _permissionStatus = LocationPermissionStatus.permanentlyDenied;
      notifyListeners();
      return false;
    } else {
      _permissionStatus = LocationPermissionStatus.denied;
      notifyListeners();
      return false;
    }
  }

  // Get current position once
  Future<Position?> getCurrentPosition() async {
    if (_permissionStatus == LocationPermissionStatus.denied ||
        _permissionStatus == LocationPermissionStatus.permanentlyDenied) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      notifyListeners();
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Start tracking user location
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    if (_permissionStatus == LocationPermissionStatus.denied ||
        _permissionStatus == LocationPermissionStatus.permanentlyDenied) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) return false;
    }

    try {
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _currentPosition = position;
        notifyListeners();
      });

      _isTracking = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  // Stop tracking user location
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  // Open app settings if permission is permanently denied
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

// Enum for location permission status
enum LocationPermissionStatus {
  unknown,
  denied,
  permanentlyDenied,
  whileInUse,
  always,
}
