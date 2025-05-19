import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'package:wonwonw2/data/mock_shops.dart';
import 'package:wonwonw2/services/location_service.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:wonwonw2/screens/shop_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // Bangkok coordinates (default center)
  final LatLng bangkokLocation = const LatLng(13.7563, 100.5018);

  // Controller for Google Map
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Current map center
  LatLng _mapCenter = const LatLng(13.7563, 100.5018);

  // Define map colors
  final Color mapAccentColor = Colors.green;

  // Location service
  late LocationService _locationService;

  // Set of markers to display on the map
  final Set<Marker> _markers = {};

  // User location marker
  Marker? _userMarker;

  // Map of BitmapDescriptor icons for different categories
  final Map<String, BitmapDescriptor> _categoryIcons = {};

  // Selected repair shop
  RepairShop? _selectedShop;

  // Is map following user location
  bool _isFollowingUser = false;

  // Is loading user location
  bool _isLoadingLocation = false;

  // Zoom level
  double _currentZoom = 13.0;

  // Custom marker icon for user location
  BitmapDescriptor? _userLocationIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = locationService; // Use the shared instance
    _loadMarkers();
    _createCustomMarkerIcon();
    _initLocationTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for permission changes when app is resumed
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    final isGranted = await Permission.location.isGranted;
    if (isGranted && !_locationService.isTracking) {
      _startLocationTracking();
    }
  }

  Future<void> _initLocationTracking() async {
    // First try to get user's current position
    final position = await _locationService.getCurrentPosition();
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

  Future<void> _startLocationTracking() async {
    final success = await _locationService.startTracking();
    if (mounted) {
      setState(() {
        _isFollowingUser = success;
      });
    }
  }

  void _onLocationChanged() {
    _updateUserLocationMarker();
    if (_isFollowingUser) {
      _animateToUserLocation();
    }
  }

  Future<void> _createCustomMarkerIcon() async {
    // Create a custom person icon with green background
    final customMarker = await _createUserLocationMarker();
    setState(() {
      _userLocationIcon = customMarker;
    });
    // Update the user marker if location is already available
    if (_locationService.currentLatLng != null) {
      _updateUserLocationMarker();
    }
  }

  Future<BitmapDescriptor> _createUserLocationMarker() async {
    // Canvas size
    const size = 40.0; // Reduced from 120.0 (30% of original size)

    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromCircle(
        center: const Offset(size / 2, size / 2),
        radius: size / 2,
      ),
    );

    // Background circle
    final bgPaint =
        Paint()
          ..color = mapAccentColor.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    // White border
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

    // Draw background circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    // Draw white border
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Draw person icon
    final personIconPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Head (circle)
    canvas.drawCircle(Offset(size / 2, size / 3), size / 8, personIconPaint);

    // Body (rounded rectangle)
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

    // End recording and create image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      // Fallback to default marker if custom creation fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

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

  Future<void> _animateToUserLocation() async {
    final currentLatLng = _locationService.currentLatLng;
    if (currentLatLng != null && _controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: _currentZoom),
        ),
      );
      setState(() {
        _mapCenter = currentLatLng;
      });
    }
  }

  Future<void> _loadMarkers() async {
    // Add shop markers
    for (final shop in MockShops.shops) {
      _markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: shop.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: 'Rating: ${shop.rating}',
          ),
          onTap: () {
            setState(() {
              _selectedShop = shop;
              // Stop following user when a shop is selected
              _isFollowingUser = false;
            });

            // Navigate to shop details screen
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder:
                        (context) => ShopDetailsScreen(
                          shop: shop,
                          userLocation: _locationService.currentLatLng,
                          mapAccentColor: mapAccentColor,
                        ),
                  ),
                )
                .then((_) {
                  // When returning from details, clear selected shop
                  setState(() {
                    _selectedShop = null;
                  });
                });
          },
        ),
      );
    }
    setState(() {});
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showLocationPermissionDialog();
      return;
    }

    final currentLatLng = _locationService.currentLatLng;
    if (currentLatLng != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
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

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('location_permission_required'.tr(context)),
            content: Text('location_permission_explanation'.tr(context)),
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
                  if (_locationService.permissionStatus ==
                      LocationPermissionStatus.permanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await _locationService.requestPermission();
                    _goToCurrentLocation();
                  }
                },
                child: Text('enable'.tr(context)),
              ),
            ],
          ),
    );
  }

  Future<void> _goToShopLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
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
    _controller.complete(controller);
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
    _currentZoom = position.zoom;

    // If map is moved manually, stop following user
    if (_isFollowingUser &&
        _locationService.currentLatLng != null &&
        (_mapCenter.latitude != _locationService.currentLatLng!.latitude ||
            _mapCenter.longitude !=
                _locationService.currentLatLng!.longitude)) {
      setState(() {
        _isFollowingUser = false;
      });
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
          // Map takes full screen
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: 13.0,
            ),
            markers: allMarkers,
            myLocationEnabled:
                false, // We'll handle this ourselves with a custom marker
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

          // Title bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'repair_shops_map'.tr(context),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedShop != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.small(
                heroTag: 'shop_location',
                onPressed: () {
                  if (_selectedShop != null) {
                    _goToShopLocation(_selectedShop!.location);
                  }
                },
                backgroundColor: Colors.white,
                foregroundColor: mapAccentColor,
                child: const Icon(Icons.location_searching),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
              backgroundColor: _isFollowingUser ? mapAccentColor : Colors.white,
              foregroundColor: _isFollowingUser ? Colors.white : mapAccentColor,
              child:
                  _isLoadingLocation
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isFollowingUser ? Colors.white : mapAccentColor,
                          ),
                        ),
                      )
                      : const Icon(Icons.my_location),
              tooltip: 'my_location'.tr(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMapsUrl() async {
    // Use user location if available, otherwise use Bangkok
    final location = _locationService.currentLatLng ?? bangkokLocation;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('could_not_open_map'.tr(context)),
            backgroundColor: mapAccentColor,
          ),
        );
      }
    }
  }
}
