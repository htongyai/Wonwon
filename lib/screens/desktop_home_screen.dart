import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/settings_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/advanced_search_bar.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:wonwonw2/services/location_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';

class DesktopHomeScreen extends StatefulWidget {
  final bool? isMainSidebarCollapsed;

  const DesktopHomeScreen({Key? key, this.isMainSidebarCollapsed})
    : super(key: key);

  @override
  _DesktopHomeScreenState createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen>
    with
        WidgetDisposalMixin<DesktopHomeScreen>,
        SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  late LocationService _locationService;
  List<RepairShop> _shops = [];
  List<RepairShop> _filteredShops = [];
  bool _isLoading = true;
  bool _isLocationLoading = true;
  bool _isShopsLoading = true;
  bool _isLanguageLoading = true;
  bool _isCategorySidebarCollapsed = false;
  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  String? _selectedSubServiceId;

  Position? _userPosition;
  String? _userDistrict;

  @override
  void onInitState() {
    // Get shared location service instance
    _locationService = locationService;

    _animationController = createAnimationController(
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();

    // Load all data concurrently
    _initializeData();

    AppLocalizationsService().localeStream.listen((locale) async {
      if (mounted) {
        setState(() {
          _currentLanguage = locale.languageCode;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    // Load all data concurrently with location timeout
    try {
      await Future.wait([
        _getUserLocationWithTimeout(),
        _loadShops(),
        _loadCurrentLanguage(),
      ]);
    } catch (e) {
      appLog('Error during data initialization: $e');
      // Force completion on error
      setState(() {
        _isLocationLoading = false;
        _isShopsLoading = false;
        _isLanguageLoading = false;
        _isLoading = false;
      });
    }

    // Check if all data is loaded
    _checkIfAllDataLoaded();
  }

  void _checkIfAllDataLoaded() {
    if (!_isLocationLoading && !_isShopsLoading && !_isLanguageLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void onDispose() {
    // Remove the listener but don't dispose the service since it's shared
    _locationService.removeListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    // Update location display when location service updates
    _updateLocationDisplay();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final locale = await AppLocalizationsService.getLocale();
      setState(() {
        _currentLanguage = locale.languageCode;
        _isLanguageLoading = false;
      });
      _checkIfAllDataLoaded();
    } catch (e) {
      appLog('Error loading language: $e');
      setState(() {
        _isLanguageLoading = false;
      });
      _checkIfAllDataLoaded();
    }
  }

  /// Get user location with 10-second timeout
  Future<void> _getUserLocationWithTimeout() async {
    try {
      // Try to get location with 10-second timeout
      await _getUserLocation().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      appLog(
        'Desktop Home Screen: Location request timed out after 10 seconds - showing shop list anyway',
      );
      setState(() {
        _isLocationLoading = false;
        _locationPermissionDenied = true;
        _userDistrict = 'Location timeout - showing all shops';
      });
    } catch (e) {
      appLog('Desktop Home Screen: Error getting location: $e');
      setState(() {
        _isLocationLoading = false;
        _locationPermissionDenied = true;
        _userDistrict = 'Location unavailable - showing all shops';
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      appLog('Desktop Home Screen: Starting location fetch...');

      // Set initial state
      setState(() {
        _userDistrict = 'Getting location...';
      });

      // Add listener to location service
      _locationService.addListener(_onLocationChanged);

      // Try to get current position from location service
      appLog('Desktop Home Screen: Getting position from location service...');
      appLog(
        'Desktop Home Screen: Location service tracking: ${_locationService.isTracking}',
      );
      appLog(
        'Desktop Home Screen: Location service current position: ${_locationService.currentPosition}',
      );

      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        appLog(
          'Desktop Home Screen: Got position from service: ${position.latitude}, ${position.longitude}',
        );
        _userPosition = position;
        await _updateLocationDisplay();
      } else {
        appLog(
          'Desktop Home Screen: Location service returned null, trying direct approach...',
        );
        // If location service fails, try direct geolocator approach
        await _getLocationDirectly();
      }

      setState(() {
        _isLocationLoading = false;
      });
      _checkIfAllDataLoaded();
    } catch (e) {
      appLog('Desktop Home Screen: Error getting location: $e');
      setState(() {
        // Provide more user-friendly error message with helpful context
        if (e.toString().contains('Position update is unavailable')) {
          _userDistrict = 'Location unavailable (try HTTPS)';
        } else if (e.toString().contains('denied')) {
          _userDistrict = 'Location access denied';
        } else if (e.toString().contains('timeout')) {
          _userDistrict = 'Location timeout - try again';
        } else {
          _userDistrict = 'Location unavailable';
        }
        _isLocationLoading = false;
      });
      _checkIfAllDataLoaded();
    }
  }

  Future<void> _getLocationDirectly() async {
    try {
      appLog('Desktop Home Screen: Trying direct geolocator approach...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLog('Desktop Home Screen: Location service disabled');
        setState(() {
          _locationPermissionDenied = true;
          _userDistrict = 'Location disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      appLog('Desktop Home Screen: Permission status: $permission');

      if (permission == LocationPermission.denied) {
        appLog('Desktop Home Screen: Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          appLog('Desktop Home Screen: Permission denied');
          setState(() {
            _locationPermissionDenied = true;
            _userDistrict = 'Location denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        appLog('Desktop Home Screen: Permission denied forever');
        setState(() {
          _locationPermissionDenied = true;
          _userDistrict = 'Location denied forever';
        });
        return;
      }

      // Get current position with timeout
      appLog('Desktop Home Screen: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      appLog(
        'Desktop Home Screen: Got position directly: ${position.latitude}, ${position.longitude}',
      );
      setState(() {
        _userPosition = position;
      });

      await _updateLocationDisplay();
    } catch (e) {
      appLog('Desktop Home Screen: Error getting location directly: $e');
      setState(() {
        // Provide more user-friendly error message with helpful context
        if (e.toString().contains('Position update is unavailable')) {
          _userDistrict = 'Location unavailable (try HTTPS)';
        } else if (e.toString().contains('denied')) {
          _userDistrict = 'Location access denied';
        } else if (e.toString().contains('timeout')) {
          _userDistrict = 'Location timeout - try again';
        } else {
          _userDistrict = 'Location unavailable';
        }
      });
    }
  }

  Future<void> _updateLocationDisplay() async {
    if (_userPosition == null) {
      appLog(
        'Desktop Home Screen: No user position available for display update',
      );
      return;
    }

    try {
      appLog(
        'Desktop Home Screen: Updating location display for ${_userPosition!.latitude}, ${_userPosition!.longitude}',
      );

      // Get city and district name with retry mechanism
      List<Placemark> placemarks = [];

      // Try geocoding with retry (up to 3 attempts)
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          appLog(
            'Desktop Home Screen: Geocoding attempt $attempt for ${_userPosition!.latitude}, ${_userPosition!.longitude}',
          );
          placemarks = await placemarkFromCoordinates(
            _userPosition!.latitude,
            _userPosition!.longitude,
          );
          appLog(
            'Desktop Home Screen: Got ${placemarks.length} placemarks on attempt $attempt',
          );

          // Check if we got meaningful data
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            appLog(
              'Desktop Home Screen: Placemark data - locality: "${placemark.locality}", country: "${placemark.country}", administrativeArea: "${placemark.administrativeArea}"',
            );

            // Check if we have any meaningful location data
            if ((placemark.locality != null &&
                    placemark.locality!.isNotEmpty) ||
                (placemark.country != null && placemark.country!.isNotEmpty) ||
                (placemark.administrativeArea != null &&
                    placemark.administrativeArea!.isNotEmpty)) {
              break;
            } else {
              appLog(
                'Desktop Home Screen: Placemark has no meaningful data, retrying...',
              );
            }
          } else {
            appLog('Desktop Home Screen: No placemarks returned, retrying...');
          }
        } catch (geocodingError) {
          appLog(
            'Desktop Home Screen: Geocoding error on attempt $attempt: $geocodingError',
          );
          if (attempt == 3) {
            // Final attempt failed, try manual location lookup
            final manualLocation = _getManualLocation(
              _userPosition!.latitude,
              _userPosition!.longitude,
            );
            if (manualLocation != null) {
              setState(() {
                _userDistrict =
                    '$manualLocation\n${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
              });
              appLog(
                'Desktop Home Screen: Using manual location after geocoding failure: $manualLocation',
              );
            } else {
              // Show coordinates as final fallback
              setState(() {
                _userDistrict =
                    '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
              });
            }
            return;
          }
          // Wait before retrying (increasing delay)
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        appLog(
          'Desktop Home Screen: Got placemark - locality: ${placemark.locality}, subLocality: ${placemark.subLocality}, administrativeArea: ${placemark.administrativeArea}, country: ${placemark.country}',
        );

        String locationText = '';

        // Try multiple location fields for better results - prioritize city and country
        String cityCountryText = '';
        String coordinatesText =
            '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';

        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          cityCountryText = placemark.locality!; // City name

          // Add country if available
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            cityCountryText += ', ${placemark.country}';
          }
        } else if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          cityCountryText = placemark.administrativeArea!; // State/Province

          // Add country if available
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            cityCountryText += ', ${placemark.country}';
          }
        } else if (placemark.country != null && placemark.country!.isNotEmpty) {
          cityCountryText = placemark.country!; // Country as fallback
        }

        // Combine city/country with coordinates
        if (cityCountryText.isNotEmpty) {
          locationText = '$cityCountryText\n$coordinatesText';
        } else {
          locationText = coordinatesText;
        }

        setState(() {
          _userDistrict = locationText;
        });

        appLog('Desktop Home Screen: Location set to: $locationText');
      } else {
        // Try alternative geocoding approach if no placemarks
        appLog(
          'Desktop Home Screen: No placemarks found, trying alternative approach',
        );
        await _tryAlternativeGeocoding();
      }
    } catch (e) {
      appLog('Desktop Home Screen: Error updating location display: $e');
      setState(() {
        _userDistrict =
            '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _tryAlternativeGeocoding() async {
    try {
      appLog('Desktop Home Screen: Trying alternative geocoding approach');

      // Try with different geocoding parameters
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _userPosition!.latitude,
        _userPosition!.longitude,
      );

      appLog(
        'Desktop Home Screen: Alternative geocoding got ${placemarks.length} placemarks',
      );

      // Also try reverse geocoding with different approach
      if (placemarks.isEmpty) {
        appLog('Desktop Home Screen: Trying reverse geocoding as fallback');
        try {
          // Try with a small offset to see if we get better results
          placemarks = await placemarkFromCoordinates(
            _userPosition!.latitude + 0.001,
            _userPosition!.longitude + 0.001,
          );
          appLog(
            'Desktop Home Screen: Offset geocoding got ${placemarks.length} placemarks',
          );
        } catch (e) {
          appLog('Desktop Home Screen: Offset geocoding failed: $e');
        }
      }

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        String locationText = '';

        // Try to extract meaningful location data
        String cityCountryText = '';
        String coordinatesText =
            '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';

        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          cityCountryText = placemark.locality!;
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            cityCountryText += ', ${placemark.country}';
          }
        } else if (placemark.country != null && placemark.country!.isNotEmpty) {
          cityCountryText = placemark.country!;
        }

        // Combine city/country with coordinates
        if (cityCountryText.isNotEmpty) {
          locationText = '$cityCountryText\n$coordinatesText';
        } else {
          locationText = coordinatesText;
        }

        setState(() {
          _userDistrict = locationText;
        });
        appLog(
          'Desktop Home Screen: Alternative geocoding successful: $locationText',
        );
      } else {
        // Try manual location lookup for common areas
        final manualLocation = _getManualLocation(
          _userPosition!.latitude,
          _userPosition!.longitude,
        );
        if (manualLocation != null) {
          setState(() {
            _userDistrict =
                '$manualLocation\n${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
          });
          appLog('Desktop Home Screen: Using manual location: $manualLocation');
        } else {
          // Final fallback to coordinates
          setState(() {
            _userDistrict =
                '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
          });
          appLog(
            'Desktop Home Screen: Alternative geocoding failed, using coordinates',
          );
        }
      }
    } catch (e) {
      appLog('Desktop Home Screen: Alternative geocoding error: $e');
      // Final fallback to coordinates
      setState(() {
        _userDistrict =
            '${_userPosition!.latitude.toStringAsFixed(4)}, ${_userPosition!.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Widget _buildLocationText(String locationText) {
    // Check if the text contains a newline (city/country above coordinates)
    if (locationText.contains('\n')) {
      final parts = locationText.split('\n');
      final cityCountry = parts[0];
      final coordinates = parts[1];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cityCountry,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.darkColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            coordinates,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Single line text (loading or error states)
      return Text(
        locationText,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppConstants.darkColor,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String? _getManualLocation(double latitude, double longitude) {
    // Manual location lookup for common areas in Thailand
    // Bangkok area coordinates
    if (latitude >= 13.6 &&
        latitude <= 13.9 &&
        longitude >= 100.4 &&
        longitude <= 100.7) {
      return 'Bangkok, Thailand';
    }
    // Chiang Mai area
    if (latitude >= 18.7 &&
        latitude <= 19.0 &&
        longitude >= 98.9 &&
        longitude <= 99.1) {
      return 'Chiang Mai, Thailand';
    }
    // Phuket area
    if (latitude >= 7.8 &&
        latitude <= 8.1 &&
        longitude >= 98.2 &&
        longitude <= 98.5) {
      return 'Phuket, Thailand';
    }
    // Pattaya area
    if (latitude >= 12.8 &&
        latitude <= 13.1 &&
        longitude >= 100.8 &&
        longitude <= 101.1) {
      return 'Pattaya, Thailand';
    }
    // Hua Hin area
    if (latitude >= 12.4 &&
        latitude <= 12.7 &&
        longitude >= 99.9 &&
        longitude <= 100.2) {
      return 'Hua Hin, Thailand';
    }

    // For the specific coordinates you showed (13.7382, 100.5770)
    if ((latitude - 13.7382).abs() < 0.01 &&
        (longitude - 100.5770).abs() < 0.01) {
      return 'Bangkok, Thailand';
    }

    return null; // No manual location found
  }

  Widget _buildCollapsedCategories() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: RepairCategory.getCategories().length,
      itemBuilder: (context, index) {
        final category = RepairCategory.getCategories()[index];
        final isSelected = _selectedCategoryId == category.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                if (category.id == 'all') {
                  _clearFilters();
                } else if (isSelected) {
                  // If already selected, deselect and show all
                  _clearFilters();
                } else {
                  // Select the new category
                  _filterShopsByCategory(category.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(category.id),
                    color:
                        isSelected ? Colors.white : AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadShops() async {
    try {
      setState(() {
        _isShopsLoading = true;
      });

      final shops = await _shopService.getAllShops();
      setState(() {
        _shops = shops;
        _filteredShops = shops;
        _isShopsLoading = false;
      });

      // Apply any existing filters after loading
      if (_selectedCategoryId != 'all' || _searchQuery.isNotEmpty) {
        _applySearchFilter();
      }

      _checkIfAllDataLoaded();
    } catch (e) {
      appLog('Error loading shops: $e');
      setState(() {
        _isShopsLoading = false;
      });
      _checkIfAllDataLoaded();
    }
  }

  Future<void> _refreshShops() async {
    await _loadShops();
  }


  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.build, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 32),

            // Loading text
            Text(
              'loading_app'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              'preparing_your_experience'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicators
            Column(
              children: [
                _buildLoadingItem(
                  'loading_location'.tr(context),
                  _isLocationLoading,
                ),
                const SizedBox(height: 12),
                _buildLoadingItem('loading_shops'.tr(context), _isShopsLoading),
                const SizedBox(height: 12),
                _buildLoadingItem(
                  'loading_language'.tr(context),
                  _isLanguageLoading,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Performance loading widget
            const PerformanceLoadingWidget(size: 40, showProgress: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem(String text, bool isLoading) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child:
              isLoading
                  ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                  )
                  : const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: isLoading ? AppConstants.darkColor : Colors.grey[600],
            fontWeight: isLoading ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _filterShopsByCategory(String categoryId) {
    if (categoryId == 'all') {
      setState(() {
        _filteredShops = _shops;
        _selectedCategoryId = 'all';
        _selectedSubServiceId = null;
      });
    } else {
      setState(() {
        _filteredShops =
            _shops
                .where((shop) => shop.categories.contains(categoryId))
                .toList();
        _selectedCategoryId = categoryId;
        _selectedSubServiceId = null;
      });
    }
    // Apply search filter after category filter
    _applySearchFilter();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      // If no search query, keep current category/sub-service filters
      if (_selectedCategoryId == 'all') {
        _filteredShops = _shops;
      } else if (_selectedSubServiceId != null &&
          _selectedSubServiceId != 'all') {
        _filteredShops =
            _shops
                .where(
                  (shop) =>
                      shop.subServices.containsKey(_selectedCategoryId) &&
                      shop.subServices[_selectedCategoryId]!.contains(
                        _selectedSubServiceId,
                      ),
                )
                .toList();
      } else {
        _filteredShops =
            _shops
                .where((shop) => shop.categories.contains(_selectedCategoryId))
                .toList();
      }
    } else {
      // Apply fuzzy search query to current filtered results
      final searchResults = ServiceManager().advancedSearchService.fuzzySearch(
        _searchQuery,
        _shops,
      );

      // Apply category filter to search results
      if (_selectedCategoryId != 'all') {
        _filteredShops =
            searchResults
                .where((shop) => shop.categories.contains(_selectedCategoryId))
                .toList();
      } else {
        _filteredShops = searchResults;
      }

      // Apply sub-service filter if selected
      if (_selectedSubServiceId != null && _selectedSubServiceId != 'all') {
        _filteredShops =
            _filteredShops
                .where(
                  (shop) =>
                      shop.subServices.containsKey(_selectedCategoryId) &&
                      shop.subServices[_selectedCategoryId]!.contains(
                        _selectedSubServiceId,
                      ),
                )
                .toList();
      }
    }
  }

  void _filterShopsBySubService(String subServiceId) {
    setState(() {
      _selectedSubServiceId = subServiceId;
    });
    // Apply search filter after sub-service filter
    _applySearchFilter();
  }

  void _clearFilters() {
    setState(() {
      _filteredShops = _shops;
      _selectedCategoryId = 'all';
      _selectedSubServiceId = null;
      _searchQuery = '';
    });
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'clothing':
        return FontAwesomeIcons.shirt;
      case 'footwear':
        return FontAwesomeIcons.shoePrints;
      case 'watch':
        return FontAwesomeIcons.clock;
      case 'bag':
        return FontAwesomeIcons.briefcase;
      case 'appliance':
        return FontAwesomeIcons.plug;
      case 'electronics':
        return FontAwesomeIcons.laptop;
      default:
        return FontAwesomeIcons.screwdriverWrench;
    }
  }


  Widget _buildSubServiceItem(
    String subServiceId,
    String name,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _filterShopsBySubService(subServiceId),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppConstants.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected
                        ? AppConstants.primaryColor
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              name,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppConstants.darkColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubServicesHorizontalList() {
    if (_selectedCategoryId == 'all') return const SizedBox.shrink();

    final allSubServices = RepairSubService.getSubServices();
    final subServices = allSubServices[_selectedCategoryId] ?? [];
    if (subServices.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subServices.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            final isSelected =
                _selectedSubServiceId == null || _selectedSubServiceId == 'all';
            return _buildHorizontalSubServiceItem(
              'all',
              'all_sub_services'.tr(context),
              isSelected,
            );
          }

          final subService = subServices[index - 1];
          final isSelected = _selectedSubServiceId == subService.id;
          return _buildHorizontalSubServiceItem(
            subService.id,
            subService.name.tr(context),
            isSelected,
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSubServiceItem(
    String subServiceId,
    String name,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _filterShopsBySubService(subServiceId),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppConstants.primaryColor
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? AppConstants.primaryColor
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              name,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppConstants.darkColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton:
          ServiceProvider.authStateOf(context).isLoggedIn
              ? FloatingActionButton(
                heroTag: 'add_shop_desktop',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddShopScreen(),
                    ),
                  );
                },
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'add_shop'.tr(context),
              )
              : null,
      body:
          _isLoading
              ? _buildLoadingScreen()
              : Row(
                children: [
                  // Left sidebar - Categories and filters
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isCategorySidebarCollapsed ? 80 : 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header with collapse button
                        Container(
                          padding: const EdgeInsets.all(24),
                          child:
                              _isCategorySidebarCollapsed
                                  ? Column(
                                    children: [
                                      // Category icon when collapsed
                                      Icon(
                                        FontAwesomeIcons.layerGroup,
                                        color: AppConstants.primaryColor,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 16),
                                      // Expand button below
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isCategorySidebarCollapsed =
                                                !_isCategorySidebarCollapsed;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.chevron_right,
                                          color: AppConstants.primaryColor,
                                        ),
                                        tooltip: 'Expand categories',
                                      ),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'categories'.tr(context),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.darkColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'select_category'.tr(context),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isCategorySidebarCollapsed =
                                                !_isCategorySidebarCollapsed;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.chevron_left,
                                          color: AppConstants.primaryColor,
                                        ),
                                        tooltip: 'Collapse categories',
                                      ),
                                    ],
                                  ),
                        ),

                        // Categories grid
                        Expanded(
                          child:
                              _isCategorySidebarCollapsed
                                  ? _buildCollapsedCategories()
                                  : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Column(
                                      children: [
                                        // Categories grid
                                        Expanded(
                                          flex: 2,
                                          child: GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  childAspectRatio: 1.2,
                                                  crossAxisSpacing: 12,
                                                  mainAxisSpacing: 12,
                                                ),
                                            itemCount:
                                                RepairCategory.getCategories()
                                                    .length,
                                            itemBuilder: (context, index) {
                                              final category =
                                                  RepairCategory.getCategories()[index];
                                              return _buildCategoryCard(
                                                category,
                                              );
                                            },
                                          ),
                                        ),

                                        // Categories only - sub-services moved to main content area
                                      ],
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: Column(
                      children: [
                        // Top bar with search and location
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Search bar
                              Expanded(
                                flex: 2,
                                child: AdvancedSearchBar(
                                  onSearch: (query) {
                                    setState(() {
                                      _searchQuery = query;
                                    });
                                    _applySearchFilter();
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    setState(() {
                                      _searchQuery = suggestion;
                                    });
                                    _applySearchFilter();
                                  },
                                  searchService:
                                      ServiceManager().advancedSearchService,
                                  shops: _shops,
                                  hintText: 'search_shops'.tr(context),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Location info
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.locationDot,
                                        color: AppConstants.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            _userDistrict ==
                                                    'getting_location'.tr(
                                                      context,
                                                    )
                                                ? Row(
                                                  children: [
                                                    const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              AppConstants
                                                                  .primaryColor,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'getting_location'.tr(
                                                        context,
                                                      ),
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                AppConstants
                                                                    .darkColor,
                                                          ),
                                                    ),
                                                  ],
                                                )
                                                : _buildLocationText(
                                                  _userDistrict ??
                                                      'Getting location...',
                                                ),
                                      ),
                                      if (_userDistrict != null &&
                                          _userDistrict !=
                                              'getting_location'.tr(context))
                                        IconButton(
                                          onPressed: _getUserLocation,
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 16,
                                            color: AppConstants.primaryColor,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          tooltip: 'refresh_location'.tr(
                                            context,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Settings button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    // Navigate to settings
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.gear,
                                    color: AppConstants.darkColor,
                                    size: 18,
                                  ),
                                  tooltip: 'settings'.tr(context),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Refresh button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _refreshShops,
                                  icon: const FaIcon(
                                    FontAwesomeIcons.arrowsRotate,
                                    color: AppConstants.darkColor,
                                    size: 18,
                                  ),
                                  tooltip: 'refresh'.tr(context),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Add shop button
                              if (ServiceProvider.authStateOf(
                                context,
                              ).isLoggedIn)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const AddShopScreen(),
                                      ),
                                    );
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.plus,
                                    size: 14,
                                  ),
                                  label: Text('add_shop'.tr(context)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Sub-categories section (above shop grid)
                        if (_selectedCategoryId != 'all') ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'sub_services'.tr(context),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.darkColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSubServicesHorizontalList(),
                              ],
                            ),
                          ),
                        ],

                        // Shops grid
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(24),
                            child:
                                _filteredShops.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            _selectedCategoryId != 'all'
                                                ? FontAwesomeIcons.filter
                                                : FontAwesomeIcons.search,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedCategoryId != 'all'
                                                ? 'no_shops_in_category'.tr(
                                                  context,
                                                )
                                                : 'no_shops_found'.tr(context),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (_selectedCategoryId != 'all') ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'try_different_category'.tr(
                                                context,
                                              ),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: _clearFilters,
                                              child: Text(
                                                'show_all_shops'.tr(context),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppConstants.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                    : GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                _getShopGridCrossAxisCount(),
                                            childAspectRatio:
                                                _getShopGridAspectRatio(),
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                      itemCount: _filteredShops.length,
                                      itemBuilder: (context, index) {
                                        return _buildShopCard(
                                          _filteredShops[index],
                                        );
                                      },
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  int _getShopGridCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate available width for shop cards
    double availableWidth = screenWidth;

    // Subtract main sidebar width if not collapsed
    if (widget.isMainSidebarCollapsed != true) {
      availableWidth -= 280; // Main sidebar width
    }

    // Subtract category sidebar width if not collapsed
    if (!_isCategorySidebarCollapsed) {
      availableWidth -= 320; // Category sidebar width
    }

    // Subtract padding and margins
    availableWidth -= 64; // Container padding (32px each side)

    // Define optimal card width range (280-350px per card)
    const double minCardWidth = 280;
    const double maxCardWidth = 350;
    const double spacing = 16; // Grid spacing

    // Calculate how many cards can fit
    int maxColumns =
        ((availableWidth + spacing) / (minCardWidth + spacing)).floor();
    int minColumns =
        ((availableWidth + spacing) / (maxCardWidth + spacing)).floor();

    // Ensure we have at least 1 column and at most 6 columns
    int columns = maxColumns.clamp(1, 6);

    // If cards would be too wide, use more columns
    double cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;
    if (cardWidth > maxCardWidth && columns < 6) {
      columns = minColumns.clamp(1, 6);
    }

    return columns;
  }

  double _getShopGridAspectRatio() {
    final crossAxisCount = _getShopGridCrossAxisCount();
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate available width for shop cards
    double availableWidth = screenWidth;

    // Subtract sidebar widths
    if (widget.isMainSidebarCollapsed != true) {
      availableWidth -= 280;
    }
    if (!_isCategorySidebarCollapsed) {
      availableWidth -= 320;
    }
    availableWidth -= 64; // Container padding

    // Calculate actual card width
    const double spacing = 16;
    double cardWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    // Maintain consistent aspect ratio based on card content
    // Card content: Image (150px) + Content (~120px) + Padding (~20px) = ~290px height
    // Optimal aspect ratio keeps cards looking balanced
    double targetHeight = 290;
    double aspectRatio = cardWidth / targetHeight;

    // For single column, use a different ratio to prevent cards from being too tall
    if (crossAxisCount == 1) {
      aspectRatio = aspectRatio.clamp(
        1.2,
        2.0,
      ); // Wider cards for single column
    } else {
      aspectRatio = aspectRatio.clamp(
        0.8,
        1.4,
      ); // Normal range for multi-column
    }

    return aspectRatio;
  }

  Widget _buildCategoryCard(RepairCategory category) {
    final isSelected = _selectedCategoryId == category.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Add a small delay to prevent freezing
          await Future.delayed(const Duration(milliseconds: 100));
          if (category.id == 'all') {
            _clearFilters();
          } else if (isSelected) {
            // If already selected, deselect and show all
            _clearFilters();
          } else {
            // Select the new category
            _filterShopsByCategory(category.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? AppConstants.primaryColor
                      : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                _getCategoryIcon(category.id),
                color: isSelected ? Colors.white : AppConstants.primaryColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                category.name.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppConstants.darkColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(RepairShop shop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              // Get the currently selected category for context
              final selectedCategory =
                  _selectedCategoryId != 'all' ? _selectedCategoryId : null;

              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ShopDetailScreen(
                        shopId: shop.id,
                        selectedCategory: selectedCategory,
                      ),
                ),
              );

              // Handle returning with category filter
              if (result is Map<String, dynamic> &&
                  result.containsKey('filterCategory')) {
                final category = result['filterCategory'] as String;
                _filterShopsByCategory(category);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop image with gradient background
                Hero(
                  tag: 'shop-image-${shop.id}',
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryColor.withOpacity(0.8),
                          AppConstants.primaryColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image with fallback
                          shop.photos.isNotEmpty
                              ? getCachedImage(
                                imageUrl: shop.photos.first,
                                imageType: ImageType.shop,
                                priority: MemoryPriority.normal,
                                fit: BoxFit.cover,
                                errorWidget: AssetHelpers.getShopPlaceholder(
                                  shop.name,
                                  containerWidth: containerWidth,
                                  containerHeight: 120,
                                ),
                                placeholder: Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ),
                              )
                              : AssetHelpers.getShopPlaceholder(
                                shop.name,
                                containerWidth: containerWidth,
                                containerHeight: 120,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Shop details
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and rating row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: GoogleFonts.montserrat(
                                  fontSize:
                                      ResponsiveSize.getResponsiveFontSize(
                                        16,
                                        containerWidth,
                                      ),
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.darkColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        ResponsiveSize.getResponsiveFontSize(
                                          13,
                                          containerWidth,
                                        ),
                                    color: AppConstants.darkColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Service information
                        Row(
                          children: [
                            Icon(
                              Icons.build,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.subServices.isNotEmpty
                                    ? '${shop.subServices.values.first.length} services'
                                    : 'No subservices',
                                style: GoogleFonts.montserrat(
                                  fontSize:
                                      ResponsiveSize.getResponsiveFontSize(
                                        12,
                                        containerWidth,
                                      ),
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.address,
                                style: GoogleFonts.montserrat(
                                  fontSize:
                                      ResponsiveSize.getResponsiveFontSize(
                                        12,
                                        containerWidth,
                                      ),
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // View Details button
                        Container(
                          width: double.infinity,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppConstants.primaryColor,
                                AppConstants.primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ShopDetailScreen(shopId: shop.id),
                                  ),
                                );
                                if (result is Map<String, dynamic> &&
                                    result.containsKey('filterCategory')) {
                                  final category =
                                      result['filterCategory'] as String;
                                  _filterShopsByCategory(category);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Text(
                                  'View Details',
                                  style: GoogleFonts.montserrat(
                                    fontSize:
                                        ResponsiveSize.getResponsiveFontSize(
                                          13,
                                          containerWidth,
                                        ),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
