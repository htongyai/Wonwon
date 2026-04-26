import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/utils/app_logger.dart';

/// Service that manages user location tracking and permissions
/// Provides methods to get the current location, start/stop continuous location tracking,
/// and handle location permission requests
class LocationService with ChangeNotifier {
  // Subscription to position updates stream
  StreamSubscription<Position>? _positionStreamSubscription;

  // Periodic timer for web location polling
  Timer? _webPollingTimer;

  // Most recent user position data
  Position? _currentPosition;

  // Flag to track whether continuous location updates are active
  bool _isTracking = false;

  // Current state of location permission
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;

  // Cooldown mechanism to prevent infinite retries on GPS-fetch failures.
  // Only applies to fresh-GPS attempts — the cache/last-known/IP paths
  // are not subject to the cooldown so the user always gets *some*
  // position back, even if a recent GPS fetch failed.
  DateTime? _lastFailedAttempt;
  static const Duration _retryCooldown = Duration(seconds: 30);

  // Persistent cache keys. Coords here are written every time we
  // successfully resolve a position via any source (GPS / last-known /
  // IP), and read on every getCurrentPosition() call so the user gets
  // something back instantly while a fresh fetch happens in the
  // background.
  static const String _prefKeyLat = 'location_cache_lat';
  static const String _prefKeyLng = 'location_cache_lng';
  static const String _prefKeyTimestamp = 'location_cache_timestamp_ms';
  static const String _prefKeySource = 'location_cache_source';

  // Cached position considered "fresh enough" — within this window we
  // skip the GPS round-trip entirely. Longer than the GPS cache TTL
  // because users moving across a city is rare in repair-shop
  // discovery context.
  static const Duration _cacheFreshness = Duration(minutes: 30);

  // IP geolocation endpoint. Free tier, HTTPS, no API key required.
  // Used only when GPS / last-known both fail. Returns city-level
  // accuracy (~5-50km) which is good enough for "shops near me" sort.
  static const String _ipGeolocationUrl = 'https://ipapi.co/json/';

  // Dio instance with a tight timeout for the IP fallback so we don't
  // block the splash for long if the geolocation API is slow.
  final Dio _ipGeoDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));

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
      appLog('Checking location permission status...');

      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      appLog('Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        _permissionStatus = LocationPermissionStatus.denied;
        notifyListeners();
        return;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();
      appLog('Current permission status: $permission');

      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          _permissionStatus = LocationPermissionStatus.whileInUse;
          break;
        case LocationPermission.denied:
          _permissionStatus = LocationPermissionStatus.denied;
          break;
        case LocationPermission.deniedForever:
        case LocationPermission.unableToDetermine:
          _permissionStatus = LocationPermissionStatus.permanentlyDenied;
          break;
      }

      appLog('Set permission status to: $_permissionStatus');
      notifyListeners();
    } catch (e) {
      appLog('Error checking permission: $e');
      _permissionStatus = LocationPermissionStatus.unknown;
      notifyListeners();
    }
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
      appLog('Error requesting permission: $e');
      return false;
    }
  }

  /// Get the user's current position with a layered fallback strategy
  /// designed to return *something* in nearly every scenario.
  ///
  /// Resolution order (each step fast-paths to return on success):
  ///   1. **Persistent cache** — if we have a cached position less than
  ///      [_cacheFreshness] old, return it immediately and refresh in
  ///      the background. Zero-latency UX for repeat visits.
  ///   2. **OS last-known position** — Geolocator's free, instant cache
  ///      that the OS maintains. Often resolves before GPS even spins
  ///      up, especially on mobile.
  ///   3. **Fresh GPS** — the existing 3-tier accuracy fallback (high
  ///      → medium → low). Best accuracy when it works.
  ///   4. **IP-based geolocation** — last-resort city-level fallback
  ///      via ipapi.co. Solves "Position update is unavailable" on
  ///      localhost dev, GPS-less desktops, and weak-signal areas.
  ///   5. **Stale cache** — if the IP fallback also fails, return any
  ///      cached position we have, no matter how old, rather than
  ///      returning null. Stale coords are far better than no coords
  ///      for the "shops near me" use case.
  ///
  /// Returns null only if permission is denied or every layer above
  /// fails AND we have nothing in cache (truly first-time user with
  /// no GPS, no internet for IP fallback).
  Future<Position?> getCurrentPosition() async {
    // Layer 1: Hand back the cache immediately if it's fresh enough.
    // This makes the splash screen and home page feel instant for
    // returning users. We still kick off a background refresh below
    // so the cache stays current.
    final cached = await _loadCachedPosition();
    if (cached != null && _isCacheFresh(cached.timestamp)) {
      appLog('Location: returning fresh cached position '
          '(${cached.position.latitude}, ${cached.position.longitude}, '
          'source=${cached.source}, age=${DateTime.now().difference(cached.timestamp).inMinutes}min)');
      _currentPosition = cached.position;
      notifyListeners();
      // Refresh in the background — don't await.
      unawaited(_refreshPositionInBackground());
      return cached.position;
    }

    // Permission gate. We try cache *before* this so a denied user
    // who previously granted still gets their last known coords —
    // useful UX, and no privacy issue (we already had consent when we
    // saved them).
    final permission = await _ensurePermission();
    if (permission == null) {
      // Permission denied. Return whatever cache we have rather than
      // nothing — better than a blank "shops near me" experience.
      if (cached != null) {
        appLog('Location: permission denied, returning stale cache');
        _currentPosition = cached.position;
        notifyListeners();
        return cached.position;
      }
      return null;
    }

    // Layer 2: Geolocator's OS-maintained last-known position. Free,
    // instant, and frequently populated even when getCurrentPosition()
    // would fail. Skipped on web (Geolocator's web impl doesn't support
    // it).
    if (!kIsWeb) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          appLog('Location: got OS last-known position '
              '(${lastKnown.latitude}, ${lastKnown.longitude})');
          _currentPosition = lastKnown;
          notifyListeners();
          unawaited(_savePositionToCache(lastKnown, _LocationSource.gps));
          // Still trigger a fresh fetch in the background to update
          // beyond what the OS had cached.
          unawaited(_refreshPositionInBackground());
          return lastKnown;
        }
      } catch (e) {
        appLog('Location: getLastKnownPosition failed (non-fatal): $e');
      }
    }

    // Layer 3: Fresh GPS via the 3-tier accuracy fallback. Honors the
    // cooldown so we don't hammer the GPS chip if it just failed.
    final fresh = await _tryFreshGps();
    if (fresh != null) {
      _currentPosition = fresh;
      notifyListeners();
      unawaited(_savePositionToCache(fresh, _LocationSource.gps));
      return fresh;
    }

    // Layer 4: IP-based geolocation. City-level accuracy. Always
    // attempted when GPS fails, regardless of platform — works
    // identically on web and mobile via plain HTTP.
    final ipPos = await _tryIpGeolocation();
    if (ipPos != null) {
      _currentPosition = ipPos;
      notifyListeners();
      unawaited(_savePositionToCache(ipPos, _LocationSource.ip));
      return ipPos;
    }

    // Layer 5: Stale cache as last resort. We exhausted every live
    // source; falling back to old coords is still better than null
    // for shop-discovery UX.
    if (cached != null) {
      appLog('Location: all live sources failed, returning stale cache '
          '(age=${DateTime.now().difference(cached.timestamp).inMinutes}min)');
      _currentPosition = cached.position;
      notifyListeners();
      return cached.position;
    }

    appLog('Location: every fallback exhausted, returning null');
    return null;
  }

  /// Permission flow for getCurrentPosition. Returns the granted
  /// permission, or null if the user denied / location services are
  /// off. Keeps getCurrentPosition's body readable.
  Future<LocationPermission?> _ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLog('Location services are disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      appLog('Current location permission: $permission');

      if (permission == LocationPermission.denied) {
        appLog('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        appLog('Permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        _permissionStatus = LocationPermissionStatus.denied;
        notifyListeners();
        return null;
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        _permissionStatus = LocationPermissionStatus.permanentlyDenied;
        notifyListeners();
        return null;
      }

      _permissionStatus = LocationPermissionStatus.whileInUse;
      notifyListeners();
      return permission;
    } catch (e) {
      appLog('Permission check threw: $e');
      return null;
    }
  }

  /// Fresh GPS fetch with the existing 3-tier accuracy fallback.
  /// Returns null on total failure. Sets the cooldown on failure so
  /// repeated callers don't spin the GPS chip.
  Future<Position?> _tryFreshGps() async {
    // Honor cooldown on the GPS path only (cache and IP fallback are
    // not subject to it).
    if (_lastFailedAttempt != null) {
      final since = DateTime.now().difference(_lastFailedAttempt!);
      if (since < _retryCooldown) {
        appLog('GPS in cooldown (${_retryCooldown.inSeconds - since.inSeconds}s left), skipping fresh fetch');
        return null;
      }
    }

    appLog('GPS: attempting fresh fetch '
        '(platform=${kIsWeb ? "web" : "mobile"}, url=${Uri.base})');

    if (!kIsWeb) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        appLog('GPS: got mobile position '
            '(${position.latitude}, ${position.longitude})');
        return position;
      } catch (e) {
        appLog('GPS: mobile fetch failed: $e');
        _lastFailedAttempt = DateTime.now();
        return null;
      }
    }

    // Web — try high → medium → low accuracy with shrinking timeouts.
    //
    // Why a hard `Future.timeout` wrapper: Geolocator's web implementation
    // doesn't reliably honor its own `timeLimit` parameter — observed in
    // dev that `LocationAccuracy.low` calls hang forever on Chrome
    // (localhost dev environment, "Position update is unavailable" state).
    // The Dart-level timeout forces an abort so we always fall through
    // to the IP fallback within a bounded time.
    for (final attempt in [
      (LocationAccuracy.high, 6),
      (LocationAccuracy.medium, 4),
      (LocationAccuracy.low, 3),
    ]) {
      try {
        appLog('GPS: trying ${attempt.$1} (${attempt.$2}s timeout)');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: attempt.$1,
          timeLimit: Duration(seconds: attempt.$2),
        ).timeout(
          Duration(seconds: attempt.$2 + 1),
          onTimeout: () => throw TimeoutException(
              'Geolocator hung past ${attempt.$2}s for ${attempt.$1}'),
        );
        appLog('GPS: got web position via ${attempt.$1} '
            '(${position.latitude}, ${position.longitude})');
        return position;
      } catch (e) {
        appLog('GPS: ${attempt.$1} failed: $e');
      }
    }

    appLog('GPS: all web attempts failed (likely "Position update is unavailable"); '
        'IP fallback will run next');
    _lastFailedAttempt = DateTime.now();
    return null;
  }

  /// Fire-and-forget background fetch to keep the cache warm after
  /// returning a cached position. Errors are swallowed.
  Future<void> _refreshPositionInBackground() async {
    try {
      final fresh = await _tryFreshGps();
      if (fresh != null) {
        _currentPosition = fresh;
        notifyListeners();
        await _savePositionToCache(fresh, _LocationSource.gps);
      }
    } catch (e) {
      appLog('Background refresh failed (non-fatal): $e');
    }
  }

  /// IP geolocation fallback. Hits ipapi.co's free JSON endpoint and
  /// turns the city-level lat/lng into a [Position]. Safe to call from
  /// both web and mobile. Returns null on any error.
  Future<Position?> _tryIpGeolocation() async {
    appLog('IP geolocation: attempting fallback via $_ipGeolocationUrl');
    try {
      final response = await _ipGeoDio.get<Map<String, dynamic>>(
        _ipGeolocationUrl,
      );
      final data = response.data;
      if (data == null) {
        appLog('IP geolocation: empty response body');
        return null;
      }

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final city = data['city'] as String?;

      if (lat == null || lng == null) {
        appLog('IP geolocation: response missing lat/lng');
        return null;
      }

      appLog('IP geolocation: resolved to $city ($lat, $lng) '
          '(city-level accuracy ~5-50km)');

      // Synthesize a Position. We mark accuracy at 50000m so any
      // distance-based UI knows this is approximate.
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 50000,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (e) {
      appLog('IP geolocation failed: $e');
      return null;
    }
  }

  /// Read cached position from SharedPreferences. Returns null if no
  /// cache exists or if the stored data is malformed.
  Future<_CachedPosition?> _loadCachedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefKeyLat);
      final lng = prefs.getDouble(_prefKeyLng);
      final ts = prefs.getInt(_prefKeyTimestamp);
      final sourceStr = prefs.getString(_prefKeySource);
      if (lat == null || lng == null || ts == null) return null;

      final source = _LocationSource.values.firstWhere(
        (s) => s.name == sourceStr,
        orElse: () => _LocationSource.gps,
      );

      return _CachedPosition(
        position: Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
          // Use a generic accuracy for cached coords. The original
          // accuracy isn't preserved across the cache; consumers that
          // need precise accuracy should ignore cache hits.
          accuracy: source == _LocationSource.ip ? 50000 : 100,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
        source: source,
      );
    } catch (e) {
      appLog('Cache load failed: $e');
      return null;
    }
  }

  /// Persist a position to SharedPreferences for future fast-path
  /// resolution.
  Future<void> _savePositionToCache(
      Position position, _LocationSource source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyLat, position.latitude);
      await prefs.setDouble(_prefKeyLng, position.longitude);
      await prefs.setInt(
          _prefKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_prefKeySource, source.name);
    } catch (e) {
      appLog('Cache save failed (non-fatal): $e');
    }
  }

  bool _isCacheFresh(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) < _cacheFreshness;
  }

  /// Start continuous tracking of user location
  /// Returns true if tracking started successfully, false otherwise
  Future<bool> startTracking() async {
    // Don't start tracking if already tracking
    if (_isTracking) return true;

    if (kIsWeb) {
      try {
        await getCurrentPosition();
        _isTracking = true;
        _webPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
          await getCurrentPosition();
        });
        notifyListeners();
        return true;
      } catch (e) {
        appLog('Error getting web location: $e');
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
      appLog('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop continuous location tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _webPollingTimer?.cancel();
    _webPollingTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Clear the cooldown for testing purposes
  void clearCooldown() {
    _lastFailedAttempt = null;
    appLog('Location cooldown cleared');
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

/// Where a cached position came from. Distinguishes high-accuracy GPS
/// from city-level IP geolocation so consumers can decide whether the
/// coords are precise enough for their use case.
enum _LocationSource { gps, ip, manual }

/// Wrapper around a cached [Position] with provenance metadata.
class _CachedPosition {
  final Position position;
  final DateTime timestamp;
  final _LocationSource source;

  _CachedPosition({
    required this.position,
    required this.timestamp,
    required this.source,
  });
}
