// Home Screen - WonWon Repair Shop Directory
// Clean, modern Airbnb-style layout with responsive design.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/services/shop_service.dart';
import 'package:shared/services/notification_controller.dart';
import 'package:shared/utils/app_logger.dart';

import 'package:wonwon_client/screens/shop_detail_screen.dart';
import 'package:wonwon_client/screens/add_shop_screen.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/widgets/shop_card.dart';
import 'package:wonwon_client/widgets/category_chips.dart';
import 'package:wonwon_client/widgets/notification_icon.dart';
import 'package:wonwon_client/widgets/filter_bar.dart';
import 'package:wonwon_client/models/shop_filter.dart';
import 'package:wonwon_client/services/recent_searches.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShopService _shopService = ShopService();

  List<RepairShop> _allShops = [];
  List<RepairShop> _filteredShops = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  String? _selectedSubServiceId;
  bool _isNavigating = false;
  ShopFilter _filter = const ShopFilter();

  Position? _userPosition;
  String _districtName = '';
  String _fullLocationName = '';
  bool _locationLoading = true;
  final Map<String, double> _distanceCache = {};

  StreamSubscription<User?>? _authSubscription;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<String> _recentSearches = const [];
  bool _showRecentSearches = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
        });
      }
    });
    _searchFocus.addListener(_onSearchFocusChange);
    _loadRecentSearches();
    _initialize();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final recents = await RecentSearches().load();
    if (!mounted) return;
    setState(() => _recentSearches = recents);
  }

  void _onSearchFocusChange() {
    if (!mounted) return;
    setState(() {
      _showRecentSearches =
          _searchFocus.hasFocus && _searchController.text.trim().isEmpty;
    });
  }

  void _applyRecentSearch(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    _searchFocus.unfocus();
    setState(() => _showRecentSearches = false);
    RecentSearches().add(query);
    _loadRecentSearches();
  }

  Future<void> _initialize() async {
    _checkAuth();
    await Future.wait([
      _loadShops(),
      _fetchLocation(),
    ]);
  }

  // ── Auth ────────────────────────────────────────────────────────────────

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isAuthenticated = user != null;
    });
  }

  // ── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadShops() async {
    if (!_isLoading || _error != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final shops = await _shopService.getAllShops();
      if (!mounted) return;
      setState(() {
        _allShops = shops;
        _applyFilters();
        _isLoading = false;
        if (_userPosition != null) _applySortByDistance();
      });
    } catch (e) {
      appLog('Error loading shops: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ── Search & Filter ─────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onCategorySelected(String categoryId) {
    HapticFeedback.selectionClick();
    AnalyticsService.safeLog(() => AnalyticsService().logFilterCategory(category: categoryId));
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubServiceId = null; // reset sub-service when category changes
      _applyFilters();
    });
  }

  void _onSubServiceSelected(String? subServiceId) {
    if (subServiceId != null) AnalyticsService.safeLog(() => AnalyticsService().logFilterCategory(category: _selectedCategoryId, subService: subServiceId));
    setState(() {
      _selectedSubServiceId = subServiceId;
      _applyFilters();
    });
  }

  void _onFilterChanged(ShopFilter next) {
    setState(() {
      _filter = next;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<RepairShop> result = _allShops;

    // Category filter
    if (_selectedCategoryId != 'all') {
      result = result
          .where((s) => s.categories.any(
              (c) => c.toLowerCase() == _selectedCategoryId.toLowerCase()))
          .toList();

      // Sub-service filter
      if (_selectedSubServiceId != null) {
        result = result
            .where((s) {
              final shopSubs = s.subServices[_selectedCategoryId];
              return shopSubs != null && shopSubs.contains(_selectedSubServiceId);
            })
            .toList();
      }
    }

    // Search filter (name + description + sub-service keys)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        if (s.name.toLowerCase().contains(q)) return true;
        if (s.description.toLowerCase().contains(q)) return true;
        if (s.area.toLowerCase().contains(q)) return true;
        for (final subs in s.subServices.values) {
          if (subs.any((x) => x.toLowerCase().contains(q))) return true;
        }
        return false;
      }).toList();
    }

    // User filter (open now, rating, price, distance) + sort
    result = ShopFilterEngine.apply(
      result,
      _filter,
      distanceKm: _userPosition == null ? null : _getDistanceKm,
    );

    _filteredShops = result;
  }

  // ── Location ────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _locationLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition()
          .timeout(AppConstants.locationTimeout);
      if (!mounted) return;

      setState(() => _userPosition = position);

      // Try reverse geocoding to get location name
      await _reverseGeocode(position.latitude, position.longitude);

      _sortByDistance();
    } catch (e) {
      appLog('Location error: $e');
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  /// Reverse geocode coordinates → human-readable location name.
  /// Tries the geocoding package first, falls back to Nominatim API.
  Future<void> _reverseGeocode(double lat, double lng) async {
    // Attempt 1: geocoding package (works on mobile, may fail on web)
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final district = placemark.subAdministrativeArea ?? '';
        final city = placemark.locality ?? '';
        final province = placemark.administrativeArea ?? '';

        final parts = <String>[];
        if (district.isNotEmpty) parts.add(district);
        if (city.isNotEmpty && city != district) parts.add(city);
        if (province.isNotEmpty && province != city && province != district) {
          parts.add(province);
        }
        final name = parts.join(', ');

        if (name.isNotEmpty) {
          setState(() {
            _districtName = district.isNotEmpty ? district : city;
            _fullLocationName = name;
            _locationLoading = false;
          });
          return; // success
        }
      }
    } catch (e) {
      appLog('Geocoding package failed, trying fallback: $e');
    }

    // Attempt 2: Nominatim API (OpenStreetMap, works on all platforms)
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'th,en',
          'zoom': 14,
        },
        options: Options(
          headers: {'User-Agent': 'WonWon-App/1.0'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final district = address['suburb'] ??
            address['neighbourhood'] ??
            address['quarter'] ??
            '';
        final city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            '';
        final province = address['state'] ??
            address['province'] ??
            '';

        final parts = <String>[];
        if (district.toString().isNotEmpty) parts.add(district.toString());
        if (city.toString().isNotEmpty && city.toString() != district.toString()) {
          parts.add(city.toString());
        }
        if (province.toString().isNotEmpty &&
            province.toString() != city.toString() &&
            province.toString() != district.toString()) {
          parts.add(province.toString());
        }
        final name = parts.join(', ');

        if (name.isNotEmpty) {
          setState(() {
            _districtName = district.toString().isNotEmpty
                ? district.toString()
                : city.toString();
            _fullLocationName = name;
            _locationLoading = false;
          });
          return; // success
        }
      }
    } catch (e) {
      appLog('Nominatim fallback also failed: $e');
    }

    // Final fallback: show coordinates
    if (mounted) {
      setState(() {
        _districtName = '${lat.toStringAsFixed(2)}°N, ${lng.toStringAsFixed(2)}°E';
        _fullLocationName = _districtName;
        _locationLoading = false;
      });
    }
  }

  void _sortByDistance() {
    if (_userPosition == null || !mounted) return;
    setState(() {
      _applySortByDistance();
    });
  }

  void _applySortByDistance() {
    if (_userPosition == null) return;
    _updateDistanceCache();
    // Re-run the combined filter so distance-based sort + filters
    // are recomputed against the freshly-cached distances.
    _applyFilters();
  }

  // ── Distance helper ─────────────────────────────────────────────────────

  void _updateDistanceCache() {
    _distanceCache.clear();
    if (_userPosition == null) return;
    // Cache distances for ALL shops so filter/sort can look them up
    // regardless of whether the shop is currently in _filteredShops.
    for (final shop in _allShops) {
      final meters = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude,
        shop.latitude, shop.longitude,
      );
      _distanceCache[shop.id] = meters / 1000;
    }
  }

  double? _getDistanceKm(RepairShop shop) {
    return _distanceCache[shop.id];
  }

  // ── Navigation helpers ──────────────────────────────────────────────────

  void _openShopDetail(RepairShop shop) async {
    if (_isNavigating) return;
    _isNavigating = true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(
          shopId: shop.id,
          selectedCategory:
              _selectedCategoryId != 'all' ? _selectedCategoryId : null,
        ),
      ),
    );

    _isNavigating = false;
    if (!mounted) return;
    if (result is Map<String, dynamic> && result.containsKey('filterCategory')) {
      _onCategorySelected(result['filterCategory'] as String);
    }
  }

  void _openAddShop() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddShopScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_login_to_add_shop'.tr(context))),
      );
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) {
      if (mounted) _loadShops();
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadShops,
          color: AppConstants.primaryColor,
          child: _isLoading
              ? _buildShimmerLoading()
              : _error != null
                  ? _buildErrorState()
                  : _buildBody(),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'add_shop_home',
          onPressed: _openAddShop,
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          tooltip: 'add_new_shop_tooltip'.tr(context),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final screenSize = MediaQuery.of(context).size;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: screenSize.height * 0.25),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 360 ? 20 : 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'something_went_wrong'.tr(context),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadShops,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('retry'.tr(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App bar
        SliverToBoxAdapter(child: _buildAppBar()),

        // Location info
        SliverToBoxAdapter(child: _buildLocationInfo()),

        // Search bar
        SliverToBoxAdapter(child: _buildSearchBar()),

        // Recent searches (only when search is focused + empty)
        if (_showRecentSearches && _recentSearches.isNotEmpty)
          SliverToBoxAdapter(child: _buildRecentSearches()),

        // Filter & sort bar
        SliverToBoxAdapter(
          child: FilterBar(filter: _filter, onChanged: _onFilterChanged),
        ),

        // Category chips
        SliverToBoxAdapter(child: _buildCategorySection()),

        // Nearby shops carousel (only when not searching and showing all categories)
        if (_searchQuery.isEmpty && _selectedCategoryId == 'all' && _filteredShops.isNotEmpty)
          SliverToBoxAdapter(child: _buildNearbySection()),

        // All shops header
        SliverToBoxAdapter(child: _buildAllShopsHeader()),

        // Shop list or empty state
        if (_filteredShops.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          _buildShopList(),

        // Bottom padding for nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          SizedBox(
            height: 34,
            child: Image.asset(
              'assets/images/wwg.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.screwdriverWrench,
                      size: 16, color: AppConstants.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'WonWon',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkColor,
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // Location pill
          if (_districtName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: AppConstants.primaryColor),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      _districtName,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.darkColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 10),

          // Auth action: login button or notification bell
          if (_isAuthenticated)
            NotificationIcon(
              onTap: () => NotificationController().openSidebar(),
              size: 18,
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openLogin,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'login'.tr(context),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Location Info ────────────────────────────────────────────────────────

  Widget _buildLocationInfo() {
    // Show nothing if location never loaded and not loading
    if (!_locationLoading && _fullLocationName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _locationLoading && _fullLocationName.isEmpty
                ? Text(
                    'finding_location'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'your_current_location'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _fullLocationName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.darkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: (q) {
            _onSearchChanged(q);
            setState(() {
              _showRecentSearches =
                  _searchFocus.hasFocus && q.trim().isEmpty;
            });
          },
          onSubmitted: (q) {
            if (q.trim().isNotEmpty) {
              RecentSearches().add(q);
              _loadRecentSearches();
            }
          },
          style: GoogleFonts.inter(fontSize: 15, color: AppConstants.darkColor),
          decoration: InputDecoration(
            hintText: 'search_shops_services'.tr(context),
            hintStyle:
                GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Recent Searches ─────────────────────────────────────────────────────

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'recent_searches'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await RecentSearches().clear();
                    await _loadRecentSearches();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    minimumSize: const Size(40, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'clear_all'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _recentSearches
                  .map((q) => _recentSearchChip(q))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentSearchChip(String q) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyRecentSearch(q),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                q,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () async {
                  await RecentSearches().remove(q);
                  await _loadRecentSearches();
                },
                customBorder: const CircleBorder(),
                child: Icon(Icons.close_rounded,
                    size: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Categories ──────────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: CategoryChips(
        selectedCategoryId: _selectedCategoryId,
        selectedSubServiceId: _selectedSubServiceId,
        onCategorySelected: _onCategorySelected,
        onSubServiceSelected: _onSubServiceSelected,
      ),
    );
  }

  // ── Nearby Shops Carousel ───────────────────────────────────────────────

  Widget _buildNearbySection() {
    final nearbyShops = _filteredShops.take(8).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _userPosition != null
                      ? 'shops_near_you'.tr(context)
                      : 'recommended_shops'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nearbyShops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final shop = nearbyShops[index];
              final cardWidth = screenWidth < 360
                  ? screenWidth * 0.65
                  : 230.0;
              return SizedBox(
                width: cardWidth,
                child: RepaintBoundary(
                  child: ShopCard(
                    shop: shop,
                    compact: false,
                    distanceKm: _getDistanceKm(shop),
                    onTap: () => _openShopDetail(shop),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── All Shops Header ────────────────────────────────────────────────────

  Widget _buildAllShopsHeader() {
    final label = _selectedCategoryId != 'all'
        ? 'filtered_results'.tr(context)
        : (_searchQuery.isNotEmpty
            ? 'search_results'.tr(context)
            : 'all_shops'.tr(context));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label (${_filteredShops.length})',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkColor,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectedCategoryId != 'all' || _searchQuery.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoryId = 'all';
                    _selectedSubServiceId = null;
                    _filter = const ShopFilter();
                    _applyFilters();
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 14, color: AppConstants.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'clear'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shop List (responsive) ──────────────────────────────────────────────

  Widget _buildShopList() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= ResponsiveBreakpoints.desktop;
    return isDesktop ? _buildDesktopGrid() : _buildMobileList();
  }

  Widget _buildMobileList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final shop = _filteredShops[index];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < _filteredShops.length - 1 ? 10 : 0),
              child: RepaintBoundary(
                child: ShopCard(
                  shop: shop,
                  compact: true,
                  distanceKm: _getDistanceKm(shop),
                  onTap: () => _openShopDetail(shop),
                ),
              ),
            );
          },
          childCount: _filteredShops.length,
        ),
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final shop = _filteredShops[index];
            return RepaintBoundary(
              child: ShopCard(
                shop: shop,
                compact: true,
                distanceKm: _getDistanceKm(shop),
                onTap: () => _openShopDetail(shop),
              ),
            );
          },
          childCount: _filteredShops.length,
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final hasFilter = _selectedCategoryId != 'all' ||
        _searchQuery.isNotEmpty ||
        _filter.hasActiveFilters;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 20 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off_rounded : Icons.storefront_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'no_shops_in_category'.tr(context)
                  : 'no_shops_found'.tr(context),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 8),
              Text(
                'try_different_category'.tr(context),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoryId = 'all';
                    _filter = const ShopFilter();
                    _applyFilters();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                ),
                child: Text('show_all_shops'.tr(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // App bar placeholder
        Row(
          children: [
            _shimmerBox(34, 34, radius: 10),
            const SizedBox(width: 10),
            _shimmerBox(18, 80, radius: 4),
            const Spacer(),
            _shimmerBox(34, 90, radius: 22),
          ],
        ),
        const SizedBox(height: 20),

        // Search bar placeholder
        _shimmerBox(50, double.infinity, radius: 16),
        const SizedBox(height: 20),

        // Category chips placeholder
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => _shimmerBox(44, 95, radius: 22),
          ),
        ),
        const SizedBox(height: 28),

        // Section header placeholder
        Row(
          children: [
            _shimmerBox(20, 3, radius: 2),
            const SizedBox(width: 10),
            _shimmerBox(18, 140, radius: 4),
          ],
        ),
        const SizedBox(height: 16),

        // Carousel placeholder — matches new card design
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: 230,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: _shimmerBox(155, double.infinity, radius: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(14, 130, radius: 4),
                        const SizedBox(height: 8),
                        _shimmerBox(12, 100, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Section header placeholder
        Row(
          children: [
            _shimmerBox(20, 3, radius: 2),
            const SizedBox(width: 10),
            _shimmerBox(18, 120, radius: 4),
          ],
        ),
        const SizedBox(height: 16),

        // List items placeholder — matches new compact card design
        for (int i = 0; i < 4; i++) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                _shimmerBox(94, 94, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(14, 140, radius: 4),
                      const SizedBox(height: 8),
                      _shimmerBox(12, 100, radius: 4),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _shimmerBox(20, 60, radius: 8),
                          const SizedBox(width: 4),
                          _shimmerBox(20, 55, radius: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
