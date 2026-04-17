import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/map_constants.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class AdminMapViewScreen extends StatefulWidget {
  const AdminMapViewScreen({Key? key}) : super(key: key);

  @override
  State<AdminMapViewScreen> createState() => _AdminMapViewScreenState();
}

class _AdminMapViewScreenState extends State<AdminMapViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<RepairShop> _allShops = [];
  List<RepairShop> _filteredShops = [];

  // Filters
  String _statusFilter = 'all'; // all, approved, pending, rejected
  String _categoryFilter = 'all';
  String _searchQuery = '';

  // UI state
  bool _isLoading = true;
  bool _showMap = false;
  bool _hasError = false;
  RepairShop? _selectedShop;
  BitmapDescriptor? _approvedMarker;
  BitmapDescriptor? _pendingMarker;
  BitmapDescriptor? _rejectedMarker;

  final List<String> _categories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  @override
  void initState() {
    super.initState();
    _createMarkerIcons();
    _loadShops();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showMap = true);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  // ── Marker icons ─────────────────────────────────────────────────────

  Future<void> _createMarkerIcons() async {
    final approved = await _buildMarkerIcon(AppConstants.primaryColor);
    final pending = await _buildMarkerIcon(Colors.orange);
    final rejected = await _buildMarkerIcon(Colors.red);
    if (!mounted) return;
    setState(() {
      _approvedMarker = approved;
      _pendingMarker = pending;
      _rejectedMarker = rejected;
    });
    // Re-render markers with custom icons if shops already loaded
    if (_filteredShops.isNotEmpty) _updateMarkers();
  }

  Future<BitmapDescriptor> _buildMarkerIcon(Color color) async {
    const size = 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: size / 2),
    );

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()..color = color.withAlpha(210)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 6,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 8,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  // ── Data loading ─────────────────────────────────────────────────────

  Future<void> _loadShops() async {
    try {
      final snapshot = await _firestore.collection('shops').get();
      final shops = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RepairShop.fromMap(data);
      }).toList();

      if (!mounted) return;
      setState(() {
        _allShops = shops;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _applyFilters() {
    var shops = List<RepairShop>.from(_allShops);

    // Status filter
    if (_statusFilter == 'approved') {
      shops = shops.where((s) => s.approvalStatus == 'approved').toList();
    } else if (_statusFilter == 'pending') {
      shops = shops.where((s) => s.approvalStatus == 'pending').toList();
    } else if (_statusFilter == 'rejected') {
      shops = shops.where((s) => s.approvalStatus == 'rejected').toList();
    }

    // Category filter
    if (_categoryFilter != 'all') {
      shops = shops.where((s) => s.categories.contains(_categoryFilter)).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      shops = shops.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.area.toLowerCase().contains(q) ||
            (s.district?.toLowerCase().contains(q) ?? false) ||
            (s.province?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Clear selected shop if it's no longer in the filtered set
    if (_selectedShop != null &&
        !shops.any((s) => s.id == _selectedShop!.id)) {
      _selectedShop = null;
    }

    if (!mounted) return;
    setState(() {
      _filteredShops = shops;
    });
    _updateMarkers();
  }

  void _updateMarkers() {
    if (!mounted) return;
    final markers = <Marker>{};
    for (final shop in _filteredShops) {
      if (!_isValidCoordinate(shop.latitude, shop.longitude)) continue;

      BitmapDescriptor icon;
      switch (shop.approvalStatus) {
        case 'approved':
          icon = _approvedMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case 'pending':
          icon = _pendingMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case 'rejected':
          icon = _rejectedMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        default:
          icon = _approvedMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }

      markers.add(Marker(
        markerId: MarkerId(shop.id),
        position: LatLng(shop.latitude, shop.longitude),
        icon: icon,
        onTap: () => _onMarkerTap(shop),
        infoWindow: InfoWindow(
          title: shop.name,
          snippet: shop.area,
        ),
      ));
    }
    setState(() => _markers
      ..clear()
      ..addAll(markers));
  }

  void _onMarkerTap(RepairShop shop) {
    setState(() => _selectedShop = shop);
  }

  /// Validates that coordinates are non-zero and within valid ranges.
  bool _isValidCoordinate(double lat, double lng) {
    return !(lat == 0 && lng == 0) &&
        lat >= -90 && lat <= 90 &&
        lng >= -180 && lng <= 180;
  }

  void _fitAllMarkers() {
    if (_filteredShops.isEmpty || _mapController == null) return;

    final validShops = _filteredShops
        .where((s) => _isValidCoordinate(s.latitude, s.longitude))
        .toList();
    if (validShops.isEmpty) return;

    // Single shop or all shops at the same point → zoom directly
    if (validShops.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(validShops.first.latitude, validShops.first.longitude),
        15,
      ));
      return;
    }

    double minLat = validShops.first.latitude;
    double maxLat = validShops.first.latitude;
    double minLng = validShops.first.longitude;
    double maxLng = validShops.first.longitude;

    for (final shop in validShops) {
      if (shop.latitude < minLat) minLat = shop.latitude;
      if (shop.latitude > maxLat) maxLat = shop.latitude;
      if (shop.longitude < minLng) minLng = shop.longitude;
      if (shop.longitude > maxLng) maxLng = shop.longitude;
    }

    // If all shops are at the exact same coordinates, zoom to point
    if (minLat == maxLat && minLng == maxLng) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(minLat, minLng),
        15,
      ));
      return;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      60,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildFilters(context),
        Expanded(
          child: Stack(
            children: [
              // Map
              _showMap
                  ? GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: MapConstants.defaultLocation,
                        zoom: 11,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        controller.setMapStyle(MapConstants.mapStyle).catchError((e) {
                          debugPrint('Failed to set map style: $e');
                        });
                        // Fit all markers after map is ready
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) _fitAllMarkers();
                        });
                      },
                      onTap: (_) => setState(() => _selectedShop = null),
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  : const Center(child: CircularProgressIndicator()),

              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.white54,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Error banner
              if (_hasError && !_isLoading)
                Positioned(
                  top: 12,
                  left: 60,
                  right: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Text(
                          'map_load_error'.tr(context),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Shop count badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.locationDot, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredShops.where((s) => _isValidCoordinate(s.latitude, s.longitude)).length} ${'map_shops_on_map'.tr(context)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fit all button
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _mapActionButton(
                      icon: Icons.fit_screen_rounded,
                      tooltip: 'map_fit_all'.tr(context),
                      onTap: _fitAllMarkers,
                    ),
                    const SizedBox(height: 8),
                    _mapActionButton(
                      icon: Icons.add,
                      tooltip: 'map_zoom_in'.tr(context),
                      onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                    ),
                    const SizedBox(height: 8),
                    _mapActionButton(
                      icon: Icons.remove,
                      tooltip: 'map_zoom_out'.tr(context),
                      onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                    ),
                  ],
                ),
              ),

              // Legend
              Positioned(
                bottom: _selectedShop != null ? 220 : 12,
                left: 12,
                child: _buildLegend(context),
              ),

              // Selected shop card
              if (_selectedShop != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: _buildShopCard(_selectedShop!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: const Color(0xFF475569)),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'map_view_label'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _loadShops();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'map_refresh'.tr(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'map_search_hint'.tr(context),
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status filter
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('admin_filter_all_status'.tr(context), style: const TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'approved', child: Text('admin_filter_approved'.tr(context), style: const TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'pending', child: Text('admin_filter_pending'.tr(context), style: const TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'rejected', child: Text('admin_filter_rejected'.tr(context), style: const TextStyle(fontSize: 13))),
                ],
                onChanged: (v) {
                  _statusFilter = v ?? 'all';
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Category filter
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                value: _categoryFilter,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('admin_filter_all_categories'.tr(context), style: const TextStyle(fontSize: 13))),
                  ..._categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('category_$c'.tr(context), style: const TextStyle(fontSize: 13)),
                      )),
                ],
                onChanged: (v) {
                  _categoryFilter = v ?? 'all';
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(AppConstants.primaryColor, 'admin_filter_approved'.tr(context)),
          const SizedBox(height: 4),
          _legendItem(Colors.orange, 'admin_filter_pending'.tr(context)),
          const SizedBox(height: 4),
          _legendItem(Colors.red, 'admin_filter_rejected'.tr(context)),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 3)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
      ],
    );
  }

  // ── Selected shop card ───────────────────────────────────────────────

  Widget _buildShopCard(RepairShop shop) {
    final statusColor = switch (shop.approvalStatus) {
      'approved' => const Color(0xFF22C55E),
      'pending' => Colors.orange,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
    final statusLabel = switch (shop.approvalStatus) {
      'approved' => 'admin_filter_approved'.tr(context),
      'pending' => 'admin_filter_pending'.tr(context),
      'rejected' => 'admin_filter_rejected'.tr(context),
      _ => shop.approvalStatus,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: shop.photos.isNotEmpty
                ? Image.network(
                    shop.photos.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (shop.description.isNotEmpty)
                  Text(
                    shop.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.area.isNotEmpty ? shop.area : shop.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (shop.rating > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: shop.categories.take(3).map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'category_$c'.tr(context),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => setState(() => _selectedShop = null),
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.store, color: Color(0xFF94A3B8), size: 32),
    );
  }
}
