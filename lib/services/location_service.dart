import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service that manages user location tracking and permissions
/// Provides methods to get the current location, start/stop continuous location tracking,
/// and handle location permission requests
class LocationService with ChangeNotifier {
  // Subscription to position updates stream
  StreamSubscription<Position>? _positionStreamSubscription;

  // Most recent user position data
  Position? _currentPosition;

  // Flag to track whether continuous location updates are active
  bool _isTracking = false;

  // Current state of location permission
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;

  // Getters for internal state
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  LocationPermissionStatus get permissionStatus => _permissionStatus;

  /// Convert Position to LatLng for Google Maps compatibility
  LatLng? get currentLatLng =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;

  /// Initialize location service and check permission status
  LocationService() {
    // Check permission status on initialization
    _checkPermission();
  }

  /// Check the current location permission status
  /// Updates the _permissionStatus field and notifies listeners
  Future<void> _checkPermission() async {
    try {
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
    } catch (e) {
      debugPrint('Error checking permission: $e');
      // Default to unknown status if there's an error
      _permissionStatus = LocationPermissionStatus.unknown;
    }

    notifyListeners();
  }

  /// Request location permission from the user
  /// Returns true if permission was granted, false otherwise
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        // Handle web permissions using geolocator directly
        final permission = await Geolocator.requestPermission();

        switch (permission) {
          case LocationPermission.whileInUse:
          case LocationPermission.always:
            _permissionStatus = LocationPermissionStatus.whileInUse;
            notifyListeners();
            return true;
          case LocationPermission.denied:
            _permissionStatus = LocationPermissionStatus.denied;
            notifyListeners();
            return false;
          case LocationPermission.deniedForever:
          case LocationPermission.unableToDetermine:
            _permissionStatus = LocationPermissionStatus.permanentlyDenied;
            notifyListeners();
            return false;
        }
      } else {
        // Mobile platforms use permission_handler
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
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Get the user's current position as a one-time request
  /// Requests permission if needed and returns null if permission denied
  Future<Position?> getCurrentPosition() async {
    // Check if permission is needed before proceeding
    if (_permissionStatus == LocationPermissionStatus.denied ||
        _permissionStatus == LocationPermissionStatus.permanentlyDenied) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) return null;
    }

    try {
      // Request position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update internal state and notify listeners
      _currentPosition = position;
      notifyListeners();
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Start continuous tracking of user location
  /// Returns true if tracking started successfully, false otherwise
  Future<bool> startTracking() async {
    // Don't start tracking if already tracking
    if (_isTracking) return true;

    // Web doesn't support background location tracking in the same way
    if (kIsWeb) {
      try {
        // For web, we'll just get the current position periodically
        await getCurrentPosition();
        _isTracking = true;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error getting web location: $e');
        return false;
      }
    }

    // Check if permission is needed before proceeding
    if (_permissionStatus == LocationPermissionStatus.denied ||
        _permissionStatus == LocationPermissionStatus.permanentlyDenied) {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) return false;
    }

    try {
      // Configure location tracking settings
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters of movement
      );

      // Subscribe to position updates stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        // Update internal state and notify listeners with each new position
        _currentPosition = position;
        notifyListeners();
      });

      // Update tracking state
      _isTracking = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop continuous location tracking
  void stopTracking() {
    // Cancel the subscription if it exists
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Open app settings page to allow user to change location permissions
  Future<void> openAppSettings() async {
    if (!kIsWeb) {
      await Geolocator.openAppSettings();
    }
  }

  /// Clean up resources when the service is no longer needed
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Enum representing the different states of location permission
enum LocationPermissionStatus {
  unknown, // Permission status couldn't be determined
  denied, // Permission was denied by the user
  permanentlyDenied, // Permission was permanently denied by the user
  whileInUse, // Permission granted while app is in use
  always, // Permission granted all the time
}
