import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/map_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonwonw2/services/location_service.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Map Screen that displays repair shops on Google Maps
/// Provides interactive markers, location tracking, and navigation to shop details
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;

  // Current map center position
  LatLng _mapCenter = MapConstants.defaultLocation;

  // Map accent color for custom markers and UI elements
  final Color mapAccentColor = const Color(0xFFC3C130);

  // Location service for tracking user position
  late LocationService _locationService;

  // Set of shop markers to display on the map
  final Set<Marker> _markers = {};

  // User location marker (separate from shop markers)
  Marker? _userMarker;

  // Currently selected repair shop
  RepairShop? _selectedShop;

  // Flag to track if map is automatically following user location
  bool _isFollowingUser = false;

  // Flag to show loading state during location fetching
  bool _isLoadingLocation = false;

  // Current zoom level of the map
  double _currentZoom = 13.0;

  // Custom marker icon for user location
  BitmapDescriptor? _userLocationIcon;

  // Flag to track if map style is loaded
  bool _isMapStyleLoaded = false;

  // Completely hide map and show preloader
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle changes (to check permissions when app resumes)
    WidgetsBinding.instance.addObserver(this);
    _locationService = locationService;
    _loadMarkers();
    _createCustomMarkerIcon();
    _initLocationTracking();

    // Allow a short delay before starting to show the map
    // This gives the map time to initialize properly before being visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showMap = true;
        });
      }
    });

    // Safety timeout to prevent infinite loading
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && !_isMapStyleLoaded) {
        setState(() {
          _isMapStyleLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _locationService.removeListener(_onLocationChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for permission changes when app is resumed from background
      _checkPermissionsOnResume();
    }
  }

  /// Check if location permissions were granted while app was in background
  Future<void> _checkPermissionsOnResume() async {
    if (kIsWeb) {
      if (!_locationService.isTracking) _startLocationTracking();
      return;
    }
    final isGranted = await Permission.location.isGranted;
    if (isGranted && !_locationService.isTracking) {
      _startLocationTracking();
    }
  }

  /// Initialize location tracking with user's current position
  Future<void> _initLocationTracking() async {
    // First try to get user's current position
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
      });
      _updateUserLocationMarker();
      _animateToUserLocation();
    }

    // Then start continuous tracking
    _startLocationTracking();

    // Listen for location changes
    _locationService.addListener(_onLocationChanged);
  }

  /// Start tracking user location updates
  Future<void> _startLocationTracking() async {
    final success = await _locationService.startTracking();
    if (mounted) {
      setState(() {
        _isFollowingUser = success;
      });
    }
  }

  /// Handle location changes from location service
  void _onLocationChanged() {
    _updateUserLocationMarker();
    if (_isFollowingUser) {
      _animateToUserLocation();
    }
  }

  /// Create a custom marker icon for user's location
  Future<void> _createCustomMarkerIcon() async {
    final customMarker = await _createUserLocationMarker();
    if (!mounted) return;
    setState(() {
      _userLocationIcon = customMarker;
    });
    // Update the user marker if location is already available
    if (_locationService.currentLatLng != null) {
      _updateUserLocationMarker();
    }
  }

  /// Generate a custom user location marker with a person icon
  Future<BitmapDescriptor> _createUserLocationMarker() async {
    // Canvas size (reduced to 40.0 - smaller than original size)
    const size = 40.0;

    // Create a picture recorder to draw the custom marker
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromCircle(
        center: const Offset(size / 2, size / 2),
        radius: size / 2,
      ),
    );

    // Background circle paint
    final bgPaint =
        Paint()
          ..color = mapAccentColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    // White border paint
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

    // Draw background circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    // Draw white border
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Paint for the person icon
    final personIconPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Draw head (circle)
    canvas.drawCircle(Offset(size / 2, size / 3), size / 8, personIconPaint);

    // Draw body (rounded rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size / 2 - size / 10,
        size / 3 + size / 8,
        size / 5,
        size / 3,
      ),
      Radius.circular(size / 10),
    );
    canvas.drawRRect(bodyRect, personIconPaint);

    // End recording and convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      // Fallback to default marker if custom creation fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  /// Update the user's location marker with current position
  void _updateUserLocationMarker() {
    final currentLatLng = _locationService.currentLatLng;
    if (currentLatLng != null) {
      setState(() {
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: currentLatLng,
          icon:
              _userLocationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'your_location'.tr(context)),
          zIndex: 2, // Make user marker appear above other markers
        );
      });
    }
  }

  void _animateToUserLocation() {
    final currentLatLng = _locationService.currentLatLng;
    if (currentLatLng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: _currentZoom),
        ),
      );
      setState(() {
        _mapCenter = currentLatLng;
      });
    }
  }

  /// Load all repair shop markers onto the map
  Future<void> _loadMarkers() async {
    try {
      final shopService = ShopService();
      final shops = await shopService.getAllShops();
      if (!mounted) return;

      for (final shop in shops) {
        _markers.add(
          Marker(
            markerId: MarkerId(shop.id),
            position: LatLng(shop.latitude, shop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: shop.name,
              snippet: 'rating_label'.tr(context).replaceAll('{rating}', '${shop.rating}'),
            ),
            onTap: () {
              setState(() {
                _selectedShop = shop;
                _isFollowingUser = false;
              });

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShopDetailScreen(shopId: shop.id),
                ),
              );
            },
          ),
        );
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showLocationPermissionDialog();
      return;
    }

    final currentLatLng = _locationService.currentLatLng;
    if (currentLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 15.0),
        ),
      );
      setState(() {
        _isFollowingUser = true;
        _mapCenter = currentLatLng;
        _currentZoom = 15.0;
        _isLoadingLocation = false;
      });
    } else {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// Show dialog requesting location permission
  void _showLocationPermissionDialog() {
    final isPermanentlyDenied = _locationService.permissionStatus ==
        LocationPermissionStatus.permanentlyDenied;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('location_permission_required'.tr(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('location_permission_explanation'.tr(context)),
                if (isPermanentlyDenied) ...[
                  const SizedBox(height: 16),
                  Text(
                    'location_enable_instructions'.tr(context),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mapAccentColor,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (isPermanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await _locationService.requestPermission();
                    _goToCurrentLocation();
                  }
                },
                child: Text(
                  isPermanentlyDenied
                      ? 'open_settings'.tr(context)
                      : 'enable'.tr(context),
                ),
              ),
            ],
          ),
    );
  }

  void _goToShopLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.0),
      ),
    );
    setState(() {
      _isFollowingUser = false;
      _mapCenter = location;
      _currentZoom = 15.0;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller
        .setMapStyle(MapConstants.mapStyle)
        .then((_) {
          if (mounted) {
            setState(() {
              _isMapStyleLoaded = true;
            });
          }
        })
        .catchError((error) {
          appLog("Error setting map style: $error");
          if (mounted) {
            setState(() {
              _isMapStyleLoaded = true;
            });
          }
        });
    _loadMarkers();
  }

  /// Called when the map camera position changes
  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
    _currentZoom = position.zoom;

    if (_isFollowingUser && _locationService.currentLatLng != null) {
      final userLat = _locationService.currentLatLng!.latitude;
      final userLng = _locationService.currentLatLng!.longitude;
      if ((_mapCenter.latitude - userLat).abs() > 0.0001 ||
          (_mapCenter.longitude - userLng).abs() > 0.0001) {
        setState(() {
          _isFollowingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create complete markers set including user location if available
    final allMarkers = Set<Marker>.from(_markers);
    if (_userMarker != null) {
      allMarkers.add(_userMarker!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map container - completely hidden until _showMap is true
          if (_showMap)
            Visibility(
              visible: _isMapStyleLoaded,
              maintainState: true,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _mapCenter,
                  zoom: 13.0,
                ),
                markers: allMarkers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: _onMapCreated,
                onCameraMove: _onCameraMove,
                trafficEnabled: false,
                buildingsEnabled: true,
                padding: const EdgeInsets.only(
                  left: 0,
                  top: 80,
                  right: 0,
                  bottom: 0,
                ),
              ),
            ),

          // Loading overlay
          if (!_isMapStyleLoaded)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'loading_map'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.darkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Floating action buttons for map navigation - only show when map is loaded
      floatingActionButton:
          _isMapStyleLoaded
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add Shop button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: 'add_shop',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddShopScreen(),
                          ),
                        );
                      },
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  // Show shop location button only when a shop is selected
                  if (_selectedShop != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton.small(
                        heroTag: 'shop_location',
                        onPressed: () {
                          if (_selectedShop != null) {
                            _goToShopLocation(
                              LatLng(
                                _selectedShop!.latitude,
                                _selectedShop!.longitude,
                              ),
                            );
                          }
                        },
                        backgroundColor: Colors.white,
                        foregroundColor: mapAccentColor,
                        child: const Icon(Icons.location_searching),
                      ),
                    ),
                  // My location button with loading indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: 'my_location',
                      onPressed:
                          _isLoadingLocation ? null : _goToCurrentLocation,
                      backgroundColor:
                          _isFollowingUser ? mapAccentColor : Colors.white,
                      foregroundColor:
                          _isFollowingUser ? Colors.white : mapAccentColor,
                      child:
                          _isLoadingLocation
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isFollowingUser
                                        ? Colors.white
                                        : mapAccentColor,
                                  ),
                                ),
                              )
                              : const Icon(Icons.my_location),
                      tooltip: 'my_location'.tr(context),
                    ),
                  ),
                ],
              )
              : null,
    );
  }

  /// Launch Google Maps app with current location
}
