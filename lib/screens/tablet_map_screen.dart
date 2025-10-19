import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:wonwonw2/services/location_service.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';

/// Tablet Map Screen that displays repair shops on Google Maps
/// Provides interactive markers, location tracking, and navigation to shop details
class TabletMapScreen extends StatefulWidget {
  const TabletMapScreen({Key? key}) : super(key: key);

  @override
  State<TabletMapScreen> createState() => _TabletMapScreenState();
}

class _TabletMapScreenState extends State<TabletMapScreen>
    with WidgetsBindingObserver, WidgetDisposalMixin<TabletMapScreen> {
  // Custom map style JSON string
  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#bac6b9"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#d5d5d5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9b37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''';

  final LocationService _locationService = locationService;
  final ShopService _shopService = ShopService();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<RepairShop> _shops = [];
  bool _isLoading = true;
  bool _isLocationLoading = true;
  bool _isShopsLoading = true;
  bool _isPermissionGranted = false;
  bool _isSidebarCollapsed = false;

  Position? _userPosition;
  String? _userDistrict;

  // Map settings
  MapType _mapType = MapType.normal;
  bool _isTrafficEnabled = false;

  @override
  void onInitState() {
    super.onInitState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _loadShops();
  }

  @override
  void onDispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onDispose();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      _getUserLocation();
    } else {
      final result = await Permission.location.request();
      if (result.isGranted) {
        setState(() {
          _isPermissionGranted = true;
        });
        _getUserLocation();
      } else {
        setState(() {
          _isLocationLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _isLocationLoading = false;
      });

      // Move camera to user location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position!.latitude, position!.longitude),
          ),
        );
      }

      // Get district name
      try {
        final placemarks = await placemarkFromCoordinates(
          position!.latitude,
          position!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          setState(() {
            _userDistrict =
                placemark.locality ??
                placemark.administrativeArea ??
                'Unknown location';
          });
        }
      } catch (e) {
        appLog('Error getting placemark: $e');
        setState(() {
          _userDistrict = 'Location found';
        });
      }
    } catch (e) {
      appLog('Error getting location: $e');
      setState(() {
        _isLocationLoading = false;
        _userDistrict = 'Location unavailable';
      });
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _isShopsLoading = true;
    });

    try {
      final shops = await _shopService.getAllShops();
      setState(() {
        _shops = shops;
        _isShopsLoading = false;
        _isLoading = false;
      });
      _createMarkers();
    } catch (e) {
      appLog('Error loading shops: $e');
      setState(() {
        _isShopsLoading = false;
        _isLoading = false;
      });
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    for (final shop in _shops) {
      markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          infoWindow: InfoWindow(title: shop.name, snippet: shop.address),
          onTap: () {
            _showShopDetails(shop);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showShopDetails(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: GoogleFonts.inter(
                      fontSize: DesignTokens.fontSizeLg,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    shop.address,
                    style: GoogleFonts.inter(
                      fontSize: DesignTokens.fontSizeSm,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeSm,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${shop.priceRange}',
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeSm,
                          color: Colors.green[600],
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ShopDetailScreen(shopId: shop.id),
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Add to saved shops logic here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left sidebar with controls (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 0 : 300,
            child:
                _isSidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildTabletSidebar(),
          ),
          // Main map area
          Expanded(
            child: Column(
              children: [
                // Header with search and toggle button
                _buildTabletHeader(),
                // Map
                Expanded(child: _buildTabletMap()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Row(
              children: [
                Text(
                  'Map Controls',
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeLg,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = true;
                    });
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              children: [
                // Location status
                _buildLocationStatus(),
                const SizedBox(height: DesignTokens.spacingLg),
                // Map type controls
                _buildMapTypeControls(),
                const SizedBox(height: DesignTokens.spacingLg),
                // Shop list
                _buildShopList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLocationLoading
                      ? Icons.location_searching
                      : _userPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color:
                      _isLocationLoading
                          ? Colors.orange
                          : _userPosition != null
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  'Location Status',
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              _isLocationLoading
                  ? 'Finding your location...'
                  : _userDistrict ?? 'Location unavailable',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeSm,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Type',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Wrap(
              spacing: DesignTokens.spacingSm,
              children: [
                _buildMapTypeButton('Normal', MapType.normal, Icons.map),
                _buildMapTypeButton(
                  'Satellite',
                  MapType.satellite,
                  Icons.satellite,
                ),
                _buildMapTypeButton('Hybrid', MapType.hybrid, Icons.layers),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Row(
              children: [
                Checkbox(
                  value: _isTrafficEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isTrafficEnabled = value ?? false;
                    });
                  },
                ),
                const Text('Show Traffic'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeButton(String label, MapType type, IconData icon) {
    final isSelected = _mapType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeSm,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Shops (${_shops.length})',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            if (_isShopsLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppConstants.primaryColor,
                        child: Text(
                          shop.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        shop.name,
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      ),
                      subtitle: Text(
                        shop.address,
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeXs,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[600]),
                          const SizedBox(width: 2),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: DesignTokens.fontSizeXs,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(shop.latitude, shop.longitude),
                          ),
                        );
                        _showShopDetails(shop);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      padding: DesignTokens.getResponsivePadding(ResponsiveSize.screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Row(
        children: [
          // Toggle sidebar button
          if (_isSidebarCollapsed)
            IconButton(
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = false;
                });
              },
              icon: const Icon(Icons.menu),
            ),
          // Title
          Text(
            'Repair Shop Map',
            style: GoogleFonts.inter(
              fontSize: DesignTokens.fontSizeXl,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const Spacer(),
          // Add shop button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddShopScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletMap() {
    if (!_isPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              'Location permission required',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            ElevatedButton(
              onPressed: _checkLocationPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        controller.setMapStyle(_mapStyle);

        // Move to user location if available
        if (_userPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_userPosition!.latitude, _userPosition!.longitude),
            ),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target:
            _userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : const LatLng(
                  13.7563,
                  100.5018,
                ), // Bangkok coordinates as fallback
        zoom: 12.0,
      ),
      markers: _markers,
      mapType: _mapType,
      trafficEnabled: _isTrafficEnabled,
      myLocationEnabled: _isPermissionGranted,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: true,
    );
  }
}
