// Home Screen - WonWon Repair Shop Directory
// Clean, modern Airbnb-style layout with responsive design.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:shared/services/location_service.dart';
import 'package:shared/services/notification_controller.dart';
import 'package:shared/utils/app_logger.dart';

import 'package:wonwon_client/screens/shop_detail_screen.dart';
import 'package:wonwon_client/screens/add_shop_screen.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/widgets/shop_card.dart';
import 'package:wonwon_client/widgets/category_chips.dart';
import 'package:wonwon_client/widgets/notification_icon.dart';
import 'package:wonwon_client/widgets/filter_bar.dart';
import 'package:wonwon_client/widgets/add_shop_method_sheet.dart';
import 'package:wonwon_client/widgets/google_maps_import_dialog.dart';
import 'package:wonwon_client/models/shop_filter.dart';
import 'package:wonwon_client/services/recent_searches.dart';
import 'package:wonwon_client/widgets/sustainability/community_impact_banner.dart';
import 'package:wonwon_client/widgets/sustainability/featured_shop_card.dart';
import 'package:wonwon_client/widgets/sustainability/category_intro.dart';
import 'package:wonwon_client/widgets/sustainability/brand_footer.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
  RepairShop? _featuredShop;

  Position? _userPosition;
  String _districtName = '';
  String _fullLocationName = '';
  bool _locationLoading = true;
  /// Current state of location permission, used to render the correct
  /// location-info card (loading / active / denied / service-off).
  _LocationState _locationState = _LocationState.loading;
  final Map<String, double> _distanceCache = {};

  // ── Pagination state ──────────────────────────────────────────────────
  // QA: tester saw only a limited slice of shops on the home screen
  // because the initial `getAllShops` cap was never supplemented with
  // a fetch-more mechanism. These fields power an infinite-scroll
  // loader that fires when the user scrolls close to the bottom.
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastShopDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  StreamSubscription<User?>? _authSubscription;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<String> _recentSearches = const [];
  bool _showRecentSearches = false;

  /// Debounce timer for search input. We coalesce rapid keystrokes
  /// into a single filter pass after the user stops typing for 300ms.
  /// Without this, every keystroke triggers a setState + full filter
  /// rebuild over the entire shop list — visible lag once the dataset
  /// grows past a few dozen shops, and burns CPU on every character.
  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;

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
    _scrollController.addListener(_onScroll);
    _loadRecentSearches();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Triggers [_loadMoreShops] when the user scrolls within 400px of the
  /// bottom. Guards prevent re-entry while a page is in flight and stop
  /// firing once the server reports no more results.
  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMoreShops();
    }
  }

  /// If the app resumes and we previously had no position — maybe the user
  /// just granted permission from system settings. Re-attempt the fetch.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        _userPosition == null &&
        _locationState != _LocationState.loading) {
      appLog('[Location] app resumed, re-checking permission');
      _retryLocation();
    }
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
      _loadFeaturedShop(),
    ]);
  }

  Future<void> _loadFeaturedShop() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();
      final featuredId = configDoc.data()?['featuredShopId'] as String?;
      if (featuredId == null || featuredId.isEmpty) return;

      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(featuredId)
          .get();
      if (!shopDoc.exists || !mounted) return;
      final shop = RepairShop.fromMap({
        ...shopDoc.data()!,
        'id': shopDoc.id,
      });
      setState(() => _featuredShop = shop);
    } catch (e) {
      appLog('Featured shop load error: $e');
    }
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
    // Detect pull-to-refresh: the initial load has `_isLoading == true`
    // set by the state initializer, so any subsequent call (where loading
    // was already false) is a user-initiated refresh. We surface a
    // SnackBar in that case so the user sees the refresh completed —
    // otherwise the spinner vanishes with no other feedback.
    final isRefresh = !_isLoading && _error == null;
    if (!_isLoading || _error != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await _shopService.getShopsFirstPage();
      if (!mounted) return;
      setState(() {
        _allShops = result.shops;
        _lastShopDoc = result.lastDoc;
        _hasMore = result.hasMore;
        _applyFilters();
        _isLoading = false;
        if (_userPosition != null) _applySortByDistance();
      });
      if (isRefresh && mounted) {
        // Clear any in-flight snackbar first so we don't queue behind the
        // pull-to-refresh spinner's chrome on iOS. Margin lifts the toast
        // above the bottom nav (~80px) — tester reported they couldn't see
        // any confirmation that the refresh succeeded.
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('refreshed_successfully'.tr(context)),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            backgroundColor: AppConstants.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      appLog('Error loading shops: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Fetches the next page of shops when the user nears the bottom of
  /// the list. Gracefully no-ops if we've already fetched the last page
  /// or if the cursor is missing.
  Future<void> _loadMoreShops() async {
    if (_isLoadingMore || !_hasMore || _lastShopDoc == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final result =
          await _shopService.getMoreShopsPage(lastDoc: _lastShopDoc!);
      if (!mounted) return;
      // Dedupe by id in case a shop appears in two consecutive pages
      // (can happen when shops are written between pages).
      final existingIds = _allShops.map((s) => s.id).toSet();
      final additions =
          result.shops.where((s) => !existingIds.contains(s.id)).toList();
      setState(() {
        _allShops = [..._allShops, ...additions];
        _lastShopDoc = result.lastDoc ?? _lastShopDoc;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
        _applyFilters();
        if (_userPosition != null) _applySortByDistance();
      });
    } catch (e) {
      appLog('Error loading more shops: $e');
      if (!mounted) return;
      // The cursor is now suspect — could be a stale snapshot reference,
      // a deleted doc, or a transient Firestore error. Clear it so the
      // next pull-to-refresh starts a clean first page rather than
      // re-attempting the same broken cursor.
      // _hasMore stays true so the user can still trigger a fresh load.
      setState(() {
        _isLoadingMore = false;
        _lastShopDoc = null;
      });
    }
  }

  // ── Search & Filter ─────────────────────────────────────────────────────

  /// Schedules a filter pass 300ms after the latest keystroke. Each call
  /// cancels the prior pending timer, so rapid typing only ever results
  /// in one filter run after the user pauses. Empty/clear is applied
  /// immediately so the "show everything" state restores instantly.
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      // No reason to wait when clearing — restore the full list now.
      setState(() {
        _searchQuery = '';
        _applyFilters();
      });
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () {
        if (!mounted) return;
        setState(() {
          _searchQuery = query;
          _applyFilters();
        });
      },
    );
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

  /// Fetches the user's location. Deliberately simple and direct — calls
  /// `Geolocator` without going through the shared service. That's the same
  /// pattern the rest of the app uses (splash, pickers, map retry) and it's
  /// what was proven to work.
  ///
  /// The `_LocationState` enum is still populated so the UI can render the
  /// right variant of the location card (denied / service-off / unavailable
  /// / active), but the control flow matches the committed working version.
  Future<void> _fetchLocation() async {
    appLog('[Location] === _fetchLocation start (web=$kIsWeb) ===');
    try {
      // Step 1: location services on? (native only — browsers don't expose
      // an equivalent and will reject `isLocationServiceEnabled` quietly.)
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() {
            _locationLoading = false;
            _locationState = _LocationState.serviceOff;
          });
          return;
        }
      }

      // Step 2: permission check, request if needed.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationLoading = false;
            _locationState = _LocationState.denied;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationLoading = false;
          _locationState = _LocationState.deniedForever;
        });
        return;
      }

      // Step 3: fetch position. On web, the default
      // `LocationAccuracy.best` sets `enableHighAccuracy: true`,
      // which on desktop Chrome (no GPS) waits for a high-accuracy
      // fix that never arrives — the 10s outer timeout then fires
      // and the user sees the "browser can't provide a location"
      // banner even though location is enabled. Try medium first,
      // then fall back to low. On native we keep `best` because
      // mobile devices have real GPS.
      final position = await _fetchPositionWithFallback();
      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _locationState = _LocationState.active;
        _locationLoading = false;
        // Coord fallback so the card renders even if reverse-geocode fails.
        if (_fullLocationName.isEmpty) {
          _fullLocationName =
              '${position.latitude.toStringAsFixed(3)}°, ${position.longitude.toStringAsFixed(3)}°';
          _districtName =
              '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
        }
      });

      await _reverseGeocode(position.latitude, position.longitude);
      _sortByDistance();
    } catch (e) {
      appLog('[Location] ❌ error: $e');
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        if (_userPosition == null) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('permission') && msg.contains('denied')) {
            _locationState = _LocationState.denied;
          } else if (msg.contains('position update is unavailable') ||
              msg.contains('timeout') ||
              msg.contains('timed out')) {
            // Permission granted but no coords possible — typically
            // DevTools emulation without a location override, VPN
            // blocking Google Location Services, or macOS location off.
            _locationState = _LocationState.unavailable;
          } else {
            _locationState = _LocationState.error;
          }
        }
      });
    }
  }

  /// Delegate to [LocationService] which has the full layered
  /// resolution: persistent cache → OS last-known → GPS fallback chain
  /// → IP geolocation → stale cache. Returning ANY of those is better
  /// than the previous behavior (GPS-only, threw "Position update is
  /// unavailable" on localhost dev / no-GPS desktops and rendered the
  /// "location unavailable" card).
  ///
  /// We do not catch errors here because [_fetchLocation] handles them
  /// for us and renders the appropriate error card. LocationService
  /// only throws/returns null when EVERY fallback is exhausted, which
  /// is rare in practice.
  Future<Position> _fetchPositionWithFallback() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos == null) {
      throw Exception('Position update is unavailable');
    }
    return pos;
  }

  /// Reverse geocode coordinates → human-readable location name.
  /// Tries the geocoding package first, falls back to Nominatim API.
  Future<void> _reverseGeocode(double lat, double lng) async {
    final langCode = mounted
        ? Localizations.localeOf(context).languageCode
        : 'th';
    // Attempt 1: geocoding package (works on mobile, may fail on web).
    // Skip on web — the web impl throws null-check exceptions; Nominatim
    // below handles web cleanly.
    if (!kIsWeb) {
      try {
        await setLocaleIdentifier(langCode == 'en' ? 'en_US' : 'th_TH');
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
          'accept-language': langCode == 'en' ? 'en,th' : 'th,en',
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

  Future<void> _openAddShop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_login_to_add_shop'.tr(context))),
      );
      return;
    }

    // Step 1: ask the user how they want to add the shop.
    final method = await showAddShopMethodSheet(context);
    if (method == null || !mounted) return;

    // Manual path — open an empty form, same as before.
    if (method == AddShopMethod.manual) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddShopScreen()));
      return;
    }

    // Google Maps path — pop the import dialog FIRST so the user previews
    // what was extracted, then push the form pre-filled with that data.
    // If the user cancels the import dialog we just stop; we don't want to
    // surprise them with an empty form when they explicitly chose the
    // import path.
    final import = await showModalBottomSheet<GoogleMapsImportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoogleMapsImportDialog(),
    );
    if (import == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddShopScreen(
          prefillData: import.parsed,
          prefillPhoto: import.photoBytes,
        ),
      ),
    );
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
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
                    color: theme.colorScheme.onSurface,
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
                    color: theme.colorScheme.onSurfaceVariant,
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
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App bar
        SliverToBoxAdapter(child: _buildAppBar()),

        // Location info
        SliverToBoxAdapter(child: _buildLocationInfo()),

        // Community impact banner (appears only when config data is present)
        const SliverToBoxAdapter(child: CommunityImpactBanner()),

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

        // Category editorial intro (only when a category is selected)
        if (_selectedCategoryId != 'all')
          SliverToBoxAdapter(
            child: CategoryIntro(categoryId: _selectedCategoryId),
          ),

        // Featured Repairer of the Week (only on neutral home state)
        if (_searchQuery.isEmpty &&
            _selectedCategoryId == 'all' &&
            !_filter.hasActiveFilters &&
            _featuredShop != null)
          SliverToBoxAdapter(
            child: FeaturedShopCard(
              shop: _featuredShop!,
              onTap: () => _openShopDetail(_featuredShop!),
            ),
          ),

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

        // Infinite-scroll indicator. Shown while a new page is in flight so
        // the user gets visual feedback that more content is arriving.
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'loading_more'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Manual "Load more" fallback — covers the case where the
        // scroll-edge trigger doesn't fire (e.g. iOS Safari overscroll
        // dampening, or when the list is short enough that the 400px
        // threshold is never crossed). Tester (§2.3) reported "Does not
        // load next shops" — visible button removes the ambiguity.
        if (_hasMore && !_isLoadingMore && _filteredShops.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadMoreShops,
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text('load_more'.tr(context)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(
                        color: AppConstants.primaryColor.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // End-of-list marker — when the server confirms there are no more
        // shops, show a quiet "you've seen all" line so the user understands
        // they've reached the end (rather than wondering if more should load).
        if (!_hasMore && !_isLoading && _filteredShops.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'end_of_list'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),

        // Brand footer — quiet mark at the bottom
        const SliverToBoxAdapter(child: BrandFooter()),

        // Bottom padding clears the FAB and bottom nav so the last card
        // isn't hidden behind them on mobile.
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // Location pill
          if (_districtName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                          color: theme.colorScheme.onSurface),
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

  /// Retry location flow after the user denied permission. For
  /// [LocationPermission.deniedForever] on native, this will no-op; user
  /// must open system settings. On web, re-requesting generally re-prompts.
  Future<void> _retryLocation() async {
    HapticFeedback.selectionClick();
    if (mounted) {
      setState(() {
        _locationLoading = true;
        _locationState = _LocationState.loading;
      });
    }
    await _fetchLocation();
    // On web, Safari/Chrome remember an explicit denial and silently
    // re-return `denied` without prompting. A successful retry is only
    // possible if the user toggled the browser's site permission. So after
    // one failed retry, advance to deniedForever — tapping the card now
    // opens the browser-settings dialog instead of cycling loading→denied.
    if (kIsWeb &&
        mounted &&
        _locationState == _LocationState.denied) {
      setState(() {
        _locationState = _LocationState.deniedForever;
      });
    }
  }

  Widget _buildLocationInfo() {
    // Show a visible "enable location" card when denied so the user knows
    // WHY they can't see distances — and has a one-tap retry.
    if (!_locationLoading && _fullLocationName.isEmpty) {
      if (_locationState == _LocationState.denied ||
          _locationState == _LocationState.deniedForever ||
          _locationState == _LocationState.serviceOff ||
          _locationState == _LocationState.unavailable ||
          _locationState == _LocationState.error) {
        return _buildLocationOffCard();
      }
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
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
                      color: theme.colorScheme.onSurfaceVariant,
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
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _fullLocationName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
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

  /// Shown when we have NO user position to offer — denied, service off, or
  /// native geocoding silently failed. A clear, tappable affordance so the
  /// location feature doesn't just vanish from the UI.
  ///
  /// For [_LocationState.deniedForever] the retry button would never succeed
  /// (the OS won't re-prompt), so we swap in an "Open Settings" CTA instead.
  Widget _buildLocationOffCard() {
    final String subtitleKey;
    // States where retrying in-app cannot succeed — the user must change
    // something in OS / browser Settings. Tester (§2.12) reported tapping
    // the card when in `serviceOff` "flickered but nothing happened" —
    // because retry just re-detected services were still off. Treat those
    // states as terminal so the tap opens Settings instead.
    final bool isTerminalDenial =
        _locationState == _LocationState.deniedForever ||
        _locationState == _LocationState.serviceOff ||
        _locationState == _LocationState.unavailable;
    switch (_locationState) {
      case _LocationState.denied:
        subtitleKey = 'location_off_denied_subtitle';
        break;
      case _LocationState.deniedForever:
        subtitleKey = 'location_off_forever_subtitle';
        break;
      case _LocationState.serviceOff:
        subtitleKey = 'location_off_service_subtitle';
        break;
      case _LocationState.unavailable:
        subtitleKey = 'location_off_unavailable_subtitle';
        break;
      case _LocationState.error:
      case _LocationState.loading:
      case _LocationState.active:
        subtitleKey = 'location_off_error_subtitle';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isTerminalDenial ? _openLocationSettings : _retryLocation,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_off_rounded,
                      size: 17, color: AppConstants.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'location_off_title'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleKey.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Retry icon for transient states, settings icon for
                // deniedForever (system-level action).
                Icon(
                  isTerminalDenial
                      ? Icons.settings_rounded
                      : Icons.refresh_rounded,
                  size: 18,
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open the OS-level location settings. Only called for deniedForever.
  /// On web we can't open a browser's site settings programmatically, and
  /// re-running the permission request on a deniedForever state just cycles
  /// the card back to "off" — producing a jarring flicker with no progress.
  /// Instead, we show a short dialog telling the user how to re-enable
  /// location in their browser (address-bar lock icon).
  Future<void> _openLocationSettings() async {
    HapticFeedback.selectionClick();
    if (kIsWeb) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('location_browser_title'.tr(ctx)),
          content: Text('location_browser_instructions'.tr(ctx)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ok'.tr(ctx)),
            ),
          ],
        ),
      );
      return;
    }
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      appLog('openAppSettings failed: $e');
    }
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
          style: GoogleFonts.inter(
              fontSize: 15, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'search_shops_services'.tr(context),
            hintStyle: GoogleFonts.inter(
                fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
            prefixIcon: Icon(Icons.search_rounded,
                color: theme.colorScheme.onSurfaceVariant, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: theme.colorScheme.onSurfaceVariant, size: 20),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'recent_searches'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyRecentSearch(q),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                q,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
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
                    size: 12, color: theme.colorScheme.onSurfaceVariant),
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.onSurface,
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
    final theme = Theme.of(context);
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
              color: theme.colorScheme.onSurfaceVariant,
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 8),
              Text(
                'try_different_category'.tr(context),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Permission/service state for the home-screen location pipeline.
/// Drives which variant of the location card we render.
enum _LocationState {
  loading,
  active,
  denied,
  deniedForever,
  serviceOff,
  /// Browser returned "position update is unavailable" or a timeout —
  /// typically caused by OS-level Location Services being off, a VPN
  /// blocking Google Location Services, or DevTools device emulation
  /// without a location override set.
  unavailable,
  error,
}
