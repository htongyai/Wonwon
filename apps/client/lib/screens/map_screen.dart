import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/map_constants.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/models/repair_category.dart';
import 'package:shared/services/location_service.dart';
import 'package:shared/services/service_providers.dart';
import 'package:shared/services/shop_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/screens/shop_detail_screen.dart';
import 'package:wonwon_client/screens/add_shop_screen.dart';
import 'package:wonwon_client/widgets/shop_card.dart';

/// Full-screen map with draggable bottom sheet for shop list.
/// Floating search bar and category filter at top.
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // ---------------------------------------------------------------------------
  // Controllers & services
  // ---------------------------------------------------------------------------
  GoogleMapController? _mapController;
  late LocationService _locationService;
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  Timer? _searchDebounce;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  LatLng _mapCenter = MapConstants.defaultLocation;
  final Set<Marker> _markers = {};
  Marker? _userMarker;
  BitmapDescriptor? _userLocationIcon;

  List<RepairShop> _allShops = [];
  List<RepairShop> _filteredShops = [];
  final Map<String, double> _distanceCache = {};
  LatLng? _lastDistanceCachePosition;
  RepairShop? _selectedShop;

  bool _isFollowingUser = false;
  bool _isLoadingLocation = false;
  bool _isLoadingShops = true;
  bool _isMapStyleLoaded = false;
  bool _showMap = false;
  bool _isSheetExpanded = false;
  double _currentZoom = 13.0;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  bool _isNavigating = false;

  final Color _accent = AppConstants.primaryColor;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = locationService;
    _loadShops();
    _createCustomMarkerIcon();
    _initLocationTracking();

    // Track sheet position to sync the arrow icon direction
    _sheetController.addListener(() {
      if (!_sheetController.isAttached) return;
      final expanded = _sheetController.size > 0.2;
      if (expanded != _isSheetExpanded && mounted) {
        setState(() => _isSheetExpanded = expanded);
      }
    });

    // Delay map widget creation by one frame to avoid jank during the initial
    // screen transition / route animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showMap = true);
    });
    // Fallback timeout: if the map style callback (_onMapCreated) hasn't fired
    // after 3 seconds (e.g. slow network, offline tiles), remove the loading
    // overlay so the user isn't stuck on a blank screen.
    Future.delayed(AppConstants.mapStyleFallbackTimeout, () {
      if (mounted && !_isMapStyleLoaded) {
        setState(() => _isMapStyleLoaded = true);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _locationService.removeListener(_onLocationChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissionsOnResume();
  }

  // ---------------------------------------------------------------------------
  // Location helpers
  // ---------------------------------------------------------------------------
  Future<void> _checkPermissionsOnResume() async {
    if (kIsWeb) {
      if (!_locationService.isTracking) _startLocationTracking();
      return;
    }
    final isGranted = await Permission.location.isGranted;
    if (isGranted && !_locationService.isTracking) _startLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
      });
      _updateUserLocationMarker();
      _animateToUserLocation();
    }
    _startLocationTracking();
    _locationService.addListener(_onLocationChanged);
  }

  Future<void> _startLocationTracking() async {
    final success = await _locationService.startTracking();
    if (mounted) setState(() => _isFollowingUser = success);
  }

  void _onLocationChanged() {
    _updateUserLocationMarker();
    if (_isFollowingUser) _animateToUserLocation();
  }

  Future<void> _createCustomMarkerIcon() async {
    final customMarker = await _createUserLocationMarker();
    if (!mounted) return;
    setState(() => _userLocationIcon = customMarker);
    if (_locationService.currentLatLng != null) _updateUserLocationMarker();
  }

  Future<BitmapDescriptor> _createUserLocationMarker() async {
    const size = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromCircle(
        center: const Offset(size / 2, size / 2),
        radius: size / 2,
      ),
    );

    final bgPaint = Paint()
      ..color = _accent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bgPaint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    final personPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 3), size / 8, personPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size / 2 - size / 10, size / 3 + size / 8, size / 5, size / 3),
        Radius.circular(size / 10),
      ),
      personPaint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  void _updateUserLocationMarker() {
    final pos = _locationService.currentLatLng;
    if (pos != null && mounted) {
      setState(() {
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: pos,
          icon: _userLocationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'your_location'.tr(context)),
          zIndex: 2,
        );
      });
    }
  }

  void _animateToUserLocation() {
    final pos = _locationService.currentLatLng;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: pos, zoom: _currentZoom)),
      );
      if (mounted) setState(() => _mapCenter = pos);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      setState(() => _isLoadingLocation = false);
      _showLocationPermissionDialog();
      return;
    }
    final pos = _locationService.currentLatLng;
    if (pos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 15)),
      );
      setState(() {
        _isFollowingUser = true;
        _mapCenter = pos;
        _currentZoom = 15.0;
        _isLoadingLocation = false;
      });
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showLocationPermissionDialog() {
    final isPermanentlyDenied = _locationService.permissionStatus ==
        LocationPermissionStatus.permanentlyDenied;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    fontSize: 13, color: Colors.grey[700], height: 1.5),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (isPermanentlyDenied) {
                await openAppSettings();
              } else {
                await _locationService.requestPermission();
                if (mounted) _goToCurrentLocation();
              }
            },
            child: Text(isPermanentlyDenied
                ? 'open_settings'.tr(context)
                : 'enable'.tr(context)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shop data
  // ---------------------------------------------------------------------------
  final ShopService _shopService = ShopService();

  Future<void> _loadShops() async {
    try {
      final shops = await _shopService.getAllShops();
      if (!mounted) return;
      setState(() {
        _allShops = shops;
        _isLoadingShops = false;
      });
      _applyFilters();
    } catch (e) {
      appLog('Error loading shops: $e');
      if (mounted) setState(() => _isLoadingShops = false);
    }
  }

  void _applyFilters() {
    List<RepairShop> result = List.from(_allShops);

    // Category filter
    if (_selectedCategoryId != 'all') {
      result = result
          .where((s) => s.categories.contains(_selectedCategoryId))
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.area.toLowerCase().contains(q) ||
            (s.district?.toLowerCase().contains(q) ?? false) ||
            (s.province?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    setState(() {
      _filteredShops = result;
    });
    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    _markers.clear();
    for (final shop in _filteredShops) {
      _markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () => _onMarkerTapped(shop),
        ),
      );
    }
    setState(() {});
  }

  void _onMarkerTapped(RepairShop shop) {
    setState(() {
      _selectedShop = shop;
      _isFollowingUser = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(shop.latitude, shop.longitude),
          zoom: 15,
        ),
      ),
    );
    // Collapse the bottom sheet to peek when showing preview card
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.12,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _dismissSelectedShop() {
    setState(() => _selectedShop = null);
  }

  /// Toggle the bottom sheet between collapsed (0.12) and expanded (0.4).
  void _toggleSheet() {
    if (!_sheetController.isAttached) return;
    final target = _isSheetExpanded ? 0.12 : 0.4;
    setState(() => _isSheetExpanded = !_isSheetExpanded);
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToShopDetail(RepairShop shop) async {
    if (_isNavigating) return;
    _isNavigating = true;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shop.id)),
    );

    _isNavigating = false;
  }

  Widget _buildPreviewDistance(RepairShop shop) {
    final km = _getDistanceKm(shop);
    if (km == null) return const SizedBox.shrink();
    final String text;
    if (km < 1) {
      text = '${(km * 1000).round()} m';
    } else if (km < 10) {
      text = '${km.toStringAsFixed(1)} km';
    } else {
      text = '${km.round()} km';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  double? _getDistanceKm(RepairShop shop) {
    final userPos = _locationService.currentLatLng;
    if (userPos == null) return null;
    // Invalidate cache if user moved significantly
    if (_lastDistanceCachePosition == null ||
        (_lastDistanceCachePosition!.latitude - userPos.latitude).abs() > 0.001 ||
        (_lastDistanceCachePosition!.longitude - userPos.longitude).abs() > 0.001) {
      _distanceCache.clear();
      _lastDistanceCachePosition = userPos;
    }
    return _distanceCache.putIfAbsent(shop.id, () {
      final meters = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude,
        shop.latitude, shop.longitude,
      );
      return meters / 1000;
    });
  }

  // ---------------------------------------------------------------------------
  // Map callbacks
  // ---------------------------------------------------------------------------
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(MapConstants.mapStyle).then((_) {
      if (mounted) setState(() => _isMapStyleLoaded = true);
    }).catchError((error) {
      appLog('Error setting map style: $error');
      if (mounted) setState(() => _isMapStyleLoaded = true);
    });
    // Rebuild markers if shops already loaded
    if (_allShops.isNotEmpty) _rebuildMarkers();
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
    _currentZoom = position.zoom;
    final latLng = _locationService.currentLatLng;
    if (_isFollowingUser && latLng != null) {
      final uLat = latLng.latitude;
      final uLng = latLng.longitude;
      if ((_mapCenter.latitude - uLat).abs() > 0.0001 ||
          (_mapCenter.longitude - uLng).abs() > 0.0001) {
        if (mounted) setState(() => _isFollowingUser = false);
      }
    }
  }

  void _onMapTap(LatLng _) => _dismissSelectedShop();

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final allMarkers = Set<Marker>.from(_markers);
    if (_userMarker != null) allMarkers.add(_userMarker!);

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // -- Full-screen Google Map --
          if (_showMap)
            Visibility(
              visible: _isMapStyleLoaded,
              maintainState: true,
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _mapCenter, zoom: 13),
                markers: allMarkers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: _onMapCreated,
                onCameraMove: _onCameraMove,
                onTap: _onMapTap,
                trafficEnabled: false,
                buildingsEnabled: true,
                padding: EdgeInsets.only(top: 80, bottom: bottomPadding + 120),
              ),
            ),

          // -- Loading overlay --
          if (!_isMapStyleLoaded)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'loading_map'.tr(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.darkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // -- Floating search bar --
          if (_isMapStyleLoaded) _buildSearchBar(),

          // -- Selected shop preview card --
          if (_selectedShop != null && _isMapStyleLoaded)
            _buildShopPreviewCard(),

          // -- Draggable bottom sheet --
          if (_isMapStyleLoaded) _buildDraggableSheet(),

          // -- FABs: My Location + Add Shop --
          if (_isMapStyleLoaded) _buildFabs(isLoggedIn),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Floating Search Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    final categories = RepairCategory.getCategories();

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _searchDebounce?.cancel();
                _searchDebounce = Timer(AppConstants.searchDebounce, () {
                  if (mounted) _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'search'.tr(context),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategoryId == cat.id;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCategoryId = cat.id);
                      _applyFilters();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _accent
                              : const Color(0xFFE8E8E8),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          'category_${cat.id}'.tr(context),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF555555),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selected shop preview card (floating at bottom)
  // ---------------------------------------------------------------------------
  Widget _buildShopPreviewCard() {
    final shop = _selectedShop!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 130,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _navigateToShopDetail(shop),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail with rating overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFF0F0F0),
                          child: shop.photos.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: shop.photos.first,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 144,
                                  memCacheHeight: 144,
                                  placeholder: (_, __) => const ColoredBox(color: Color(0xFFF0F0F0)),
                                  errorWidget: (_, __, ___) => const Icon(Icons.store_rounded,
                                      color: Color(0xFFBDBDBD), size: 28),
                                )
                              : const Icon(Icons.store_rounded,
                                  color: Color(0xFFBDBDBD), size: 28),
                        ),
                      ),
                      if (shop.rating > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.93),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFB800), size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF9E9E9E)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _shopLocationText(shop),
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF757575)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildPreviewDistance(shop),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dismiss button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _dismissSelectedShop,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shopLocationText(RepairShop shop) {
    if (shop.district != null && shop.district!.isNotEmpty) {
      return '${shop.district}, ${shop.province ?? ''}';
    }
    if (shop.area.isNotEmpty) return shop.area;
    return shop.address;
  }

  // ---------------------------------------------------------------------------
  // Draggable bottom sheet
  // ---------------------------------------------------------------------------
  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.12, 0.4, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle + header — tappable to toggle sheet
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSheet,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Wider, more visible drag handle
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            _isLoadingShops
                                ? 'loading'.tr(context)
                                : 'shops_count'.tr(context).replaceAll('{count}', '${_filteredShops.length}'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          if (!_isLoadingShops)
                            AnimatedRotation(
                              turns: _isSheetExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Color(0xFF999999),
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              // Shop list
              Expanded(
                child: _isLoadingShops
                    ? Center(
                        child: CircularProgressIndicator(
                            color: _accent, strokeWidth: 2.5))
                    : _filteredShops.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'no_shops_found'.tr(context),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            itemCount: _filteredShops.length,
                            itemBuilder: (context, index) {
                              final shop = _filteredShops[index];
                              return ShopCard(
                                shop: shop,
                                compact: true,
                                distanceKm: _getDistanceKm(shop),
                                onTap: () => _navigateToShopDetail(shop),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FABs
  // ---------------------------------------------------------------------------
  Widget _buildFabs(bool isLoggedIn) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 16,
      bottom: bottomPadding + 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Shop (auth-only)
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.small(
                heroTag: 'add_shop',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddShopScreen()),
                  );
                },
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
                elevation: 3,
                child: const Icon(Icons.add_rounded, size: 22),
              ),
            ),
          // My location
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
            backgroundColor: _isFollowingUser ? _accent : Colors.white,
            foregroundColor: _isFollowingUser ? Colors.white : _accent,
            elevation: 3,
            child: _isLoadingLocation
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _isFollowingUser ? Colors.white : _accent),
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}
