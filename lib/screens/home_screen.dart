// This is the main Home Screen for the WonWon app
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/settings_screen.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/utils/icon_helper.dart';
import 'package:wonwonw2/widgets/advanced_search_bar.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/error_handler.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/config/web_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
// Conditional import for web
// ignore: uri_does_not_exist
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetDisposalMixin<HomeScreen>, SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();
  List<RepairShop> _shops = [];
  List<RepairShop> _filteredShops = [];
  bool _isLoading = true;
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  User? _currentUser;
  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  String? _selectedSubServiceId;

  // Current language code (en or th)
  String _currentLanguage = 'en';

  // Controller and variables for pull to refresh
  late ScrollController _scrollController;
  bool _isRefreshing = false;
  double _refreshIndicatorExtent = 0;

  bool _showLoadingOverlay = false;

  Position? _userPosition;
  String? _userDistrict;
  bool _locationPermissionDenied = false;

  @override
  void onInitState() {
    // Initialize animation controller using mixin
    _animationController = createAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    // Add scroll listener for custom refresh indicator using mixin
    _scrollController = createScrollController();
    _scrollController.addListener(_scrollListener);

    // Initialize app with auth check and data loading
    _initializeApp();

    // Listen for language changes
    AppLocalizationsService().localeStream.listen((locale) async {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = true;
          _currentLanguage = locale.languageCode;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _showLoadingOverlay = false;
          });
        }
      }
    });

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isAuthenticated = user != null;
        });
      }
    });
  }

  /// Initialize the app with auth check and data loading
  Future<void> _initializeApp() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Start all tasks in parallel
      final futures = <Future>[
        _checkAuthState(),
        _loadCurrentLanguage(),
        _loadShops(),
      ];

      // Add location with 10-second timeout
      futures.add(_getUserLocationWithTimeout());

      // Wait for all tasks to complete
      await Future.wait(futures);

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      _animationController.forward();
    } catch (e) {
      appLog('Error during app initialization: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// Check authentication state
  Future<void> _checkAuthState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = await _authService.isLoggedIn();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isAuthenticated = isLoggedIn;
        });
      }
    } catch (e) {
      appLog('Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isAuthenticated = false;
        });
      }
    }
  }

  /// Build full-screen loading widget
  Widget _buildFullScreenLoading() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/wwg.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.screwdriverWrench,
                        size: 40,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor,
                ),
                strokeWidth: 3,
              ),
            ),

            const SizedBox(height: 24),

            // Loading text
            Text(
              'initializing_app'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'loading_shops_and_services'.tr(context),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Auth status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _isAuthenticated
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _isAuthenticated
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAuthenticated ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: _isAuthenticated ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAuthenticated
                        ? '${_currentUser?.email?.split('@')[0] ?? 'signed_in'.tr(context)}'
                        : 'guest_mode'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isAuthenticated ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load the current language from SharedPreferences
  Future<void> _loadCurrentLanguage() async {
    final locale = await AppLocalizationsService.getLocale();
    if (mounted) {
      setState(() {
        _currentLanguage = locale.languageCode;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels < -60 && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
    } else if (_scrollController.position.pixels >= 0 && _isRefreshing) {
      setState(() {
        _isRefreshing = false;
      });
    }

    // Update pull extent for animation
    if (_scrollController.position.pixels < 0) {
      setState(() {
        _refreshIndicatorExtent = _scrollController.position.pixels.abs().clamp(
          0.0,
          60.0,
        );
      });
    }
  }

  // Disposal is now handled automatically by WidgetDisposalMixin

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shops = await _shopService.getAllShops();
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _shops = shops;
        if (_searchQuery.isEmpty && !_isFiltered()) {
          _filteredShops = shops;
        } else if (_searchQuery.isNotEmpty) {
          _handleSearch(_searchQuery);
        } else if (_isFiltered() && _filteredShops.isNotEmpty) {
          final selectedCategory = _getSelectedCategory();
          if (selectedCategory != null) {
            _filterShopsByCategory(selectedCategory);
          }
        }
        _isLoading = false;
        if (_userPosition != null) {
          _sortShopsByDistance();
        }
      });
      ErrorHandler.showSuccess(context, 'Shop list refreshed');
    } catch (e) {
      appLog('Error loading shops: $e');
      setState(() {
        _isLoading = false;
      });
      ErrorHandler.handleError(
        context,
        e,
        customMessage: 'Failed to refresh. Please try again.',
        onRetry: _refreshShops,
      );
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        // If we had a filter applied before searching, maintain that filter
        if (!_isFiltered()) {
          _filteredShops = _shops;
        }
      } else {
        // Apply search on current filtered list if we have a filter,
        // otherwise search the entire list
        final baseList =
            _isFiltered() && _searchQuery.isEmpty ? _filteredShops : _shops;

        // Use advanced search service for fuzzy search
        _filteredShops = ServiceManager().advancedSearchService.fuzzySearch(
          query,
          baseList,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show full-screen loading during initialization
    if (_isInitializing) {
      return _buildFullScreenLoading();
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadShops,
              color: AppConstants.primaryColor,
              displacement: 40.0,
              strokeWidth: 3.0,
              edgeOffset: 20.0,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              child: Stack(
                children: [
                  if (_isLoading)
                    const PerformanceLoadingWidget(
                      message: 'Loading shops and services...',
                      size: 60,
                    )
                  else
                    _buildMainContent(),
                  // Pull to refresh indicator at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 0, // Hidden initially
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Always show FAB for now, but we can add auth check later
              // final isLoggedIn = snapshot.hasData && snapshot.data != null;
              return FloatingActionButton(
                heroTag: 'add_shop_home',
                onPressed: () {
                  // Check auth before navigation
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddShopScreen(),
                      ),
                    );
                  } else {
                    // Show login prompt
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to add a shop'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Add New Shop',
              );
            },
          ),
        ),
        if (_showLoadingOverlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 80, // Leave space for FAB
            child: Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // Main content
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Custom pull-to-refresh indicator
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _refreshIndicatorExtent,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_refreshIndicatorExtent > 40)
                        const Icon(
                          Icons.refresh,
                          color: AppConstants.primaryColor,
                        ),
                      if (_refreshIndicatorExtent > 20)
                        const SizedBox(width: 8),
                      if (_refreshIndicatorExtent > 20)
                        Text(
                          _refreshIndicatorExtent > 50
                              ? 'Release to refresh'
                              : 'Pull to refresh',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveSize.getScaledPadding(
                  const EdgeInsets.fromLTRB(16, 10, 16, 0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and settings row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo on the left
                        SizedBox(
                          height: ResponsiveSize.getHeight(5),
                          child: Image.asset(
                            'assets/images/wwg.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: ResponsiveSize.getHeight(5),
                                width: ResponsiveSize.getHeight(5),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.screwdriverWrench,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Language dropdown and icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Language selector
                            _buildSimpleLanguageSelector(),
                            SizedBox(width: ResponsiveSize.getWidth(1)),
                            // Feedback icon
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: IconHelper.getSafeIcon(
                                FontAwesomeIcons.comment,
                                Icons.comment,
                                color: AppConstants.primaryColor,
                                size: 16,
                              ),
                              onPressed: () {
                                _launchFeedbackForm();
                              },
                            ),
                            // Settings icon
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: IconHelper.getSafeIcon(
                                FontAwesomeIcons.gear,
                                Icons.settings,
                                color: AppConstants.darkColor,
                                size: 16,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(0.5)),

                    // Add spacing above the homepage title
                    SizedBox(height: ResponsiveSize.getHeight(4)),
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0, 0.6, curve: Curves.easeOut),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0,
                              0.6,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: Text(
                          'Find repair services nearby'.tr(context),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(24),
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(0.5)),

                    // Subtitle with animations
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.2,
                            0.7,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.2,
                              0.7,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: Text(
                          'Expert repair services for all your needs'.tr(
                            context,
                          ),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(2)),

                    // Search bar with animations
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.3,
                            0.8,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.3,
                              0.8,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: AdvancedSearchBar(
                          onSearch: _handleSearch,
                          onSuggestionSelected: _handleSearch,
                          searchService: ServiceManager().advancedSearchService,
                          shops: _shops,
                          hintText: 'Search shops, services, locations...'.tr(
                            context,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(1)),

                    // Categories heading
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.4,
                            0.9,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: Text(
                        'categories'.tr(context),
                        style: GoogleFonts.montserrat(
                          fontSize: ResponsiveSize.getFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppConstants.darkColor,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(2)),
                  ],
                ),
              ),
            ),

            // Categories horizontal list
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: SizedBox(
                  height: ResponsiveSize.getHeight(
                    10,
                  ), // Reduced height for the categories section
                  child: _buildCategoriesSection(),
                ),
              ),
            ),

            // Add sub-services section after categories
            SliverToBoxAdapter(child: _buildSubServicesSection()),

            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveSize.getScaledPadding(
                  const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommended shops heading with clear filter button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isFiltered()
                              ? 'filtered_results'.tr(context)
                              : (_searchQuery.isEmpty
                                  ? (_userPosition != null
                                      ? 'Shops near you'
                                      : 'recommended_shops'.tr(context))
                                  : 'search_results'.tr(context)),
                          style: GoogleFonts.montserrat(
                            fontSize: ResponsiveSize.getFontSize(20),
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                        if (_isFiltered())
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear, size: 16),
                            label: Text('clear'.tr(context)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppConstants.primaryColor,
                              padding: ResponsiveSize.getScaledPadding(
                                const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveSize.getHeight(2),
                    ), // Add spacing under heading
                  ],
                ),
              ),
            ),

            // Shops list
            _filteredShops.isEmpty
                ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFiltered()
                              ? Icons.filter_list_off
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isFiltered()
                              ? 'no_shops_in_category'.tr(context)
                              : 'no_shops_found'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_isFiltered()) ...[
                          const SizedBox(height: 8),
                          Text(
                            'try_different_category'.tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearFilters,
                            child: Text('show_all_shops'.tr(context)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getMobileGridCrossAxisCount(),
                    childAspectRatio: _getMobileGridAspectRatio(),
                    crossAxisSpacing: 8, // Reduced spacing to prevent overflow
                    mainAxisSpacing: 8, // Reduced spacing to prevent overflow
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shop = _filteredShops[index];
                    // Staggered animation for shop cards
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final delay = 0.6 + (index * 0.05);
                        final animation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            delay.clamp(0.0, 1.0),
                            (delay + 0.4).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        );

                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0,
                            end: 1,
                          ).animate(animation),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          4,
                          0,
                          4,
                          8,
                        ), // Reduced padding for mobile
                        child: _buildShopCard(shop),
                      ),
                    );
                  }, childCount: _filteredShops.length),
                ),

            // Add extra bottom padding for the navigation bar (increased to match new height)
            SliverToBoxAdapter(
              child: SizedBox(height: ResponsiveSize.getHeight(9)),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getUserLocation,
                      icon: Icon(Icons.my_location),
                      label: Text('Find Nearby Shops'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                    ),
                    if (_userDistrict != null) ...[
                      SizedBox(width: 12),
                      Text(
                        'District: ${_userDistrict!}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (_locationPermissionDenied)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'Location permission denied',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final categories = RepairCategory.getCategories();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: EdgeInsets.only(
            right: index == categories.length - 1 ? 16 : 12,
            left: index == 0 ? 0 : 0,
          ),
          child: _buildCategoryCard(category),
        );
      },
    );
  }

  Widget _buildCategoryCard(RepairCategory category) {
    final isSelected = _selectedCategoryId == category.id;
    return GestureDetector(
      onTap: () async {
        _showTemporaryLoadingOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
        if (category.id == 'all') {
          _clearFilters();
          setState(() {
            _selectedCategoryId = 'all';
          });
        } else if (isSelected) {
          // If already selected, deselect and show all
          _clearFilters();
          setState(() {
            _selectedCategoryId = 'all';
          });
        } else {
          // Select the new category
          _filterShopsByCategory(category.id);
          setState(() {
            _selectedCategoryId = category.id;
          });
        }
      },
      child: Container(
        width: 64, // Fixed width to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min, // Add this to ensure minimum height
          children: [
            Container(
              width: 52, // Fixed width
              height: 52, // Fixed height
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color:
                      isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Icon(
                _getCategoryIcon(category.id),
                color: isSelected ? Colors.white : AppConstants.primaryColor,
                size: 24, // Fixed size
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(1)),
            Text(
              category.getLocalizedName(context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.montserrat(
                fontSize: 12, // Fixed font size
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.darkColor,
              ),
            ),
          ],
        ),
      ),
    );
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

  // Get the currently selected category if any
  String? _getSelectedCategory() {
    return _selectedCategoryId != 'all' ? _selectedCategoryId : null;
  }

  int _getMobileGridCrossAxisCount() {
    // Always use single column for mobile to display one shop at a time
    return 1;
  }

  double _getMobileGridAspectRatio() {
    final crossAxisCount = _getMobileGridCrossAxisCount();
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate available width
    const double padding =
        24; // Match the reduced padding from _getMobileGridCrossAxisCount
    const double spacing = 8; // Match the reduced spacing from SliverGrid
    double availableWidth = screenWidth - padding;
    double cardWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    // Increase target height to accommodate all content without overflow
    double targetHeight;
    if (screenWidth < 400) {
      // Very small screens: Increase height significantly to prevent overflow
      targetHeight = 320; // Image (120px) + Content (~180px) + Padding (~20px)
    } else {
      // Normal mobile screens: Generous height for all content
      targetHeight = 380; // Image (150px) + Content (~210px) + Padding (~20px)
    }

    double aspectRatio = cardWidth / targetHeight;

    // Since we're always using single column now, ensure reasonable aspect ratio
    aspectRatio = aspectRatio.clamp(0.8, 1.2);

    return aspectRatio;
  }

  Widget _buildShopCard(RepairShop shop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              // Get the currently selected category
              final selectedCategory = _getSelectedCategory();

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
                setState(() {
                  _selectedCategoryId = category;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              children: [
                // Shop image
                Hero(
                  tag: 'shop-image-${shop.id}',
                  child: Container(
                    height:
                        containerWidth < 200
                            ? 120
                            : 150, // Smaller image on very small cards
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
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
                                  containerHeight: 150,
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
                                containerHeight: 150,
                              ),

                          // Gradient overlay for better visibility
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Shop details
                Flexible(
                  // Make this section flexible
                  child: Padding(
                    padding: EdgeInsets.all(
                      containerWidth < 200
                          ? 8
                          : (containerWidth < 300 ? 10 : 16),
                    ), // More responsive padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Prevent overflow
                      children: [
                        // Name and rating row
                        Row(
                          children: [
                            Expanded(
                              flex: 3, // Give more space to the name
                              child: Text(
                                shop.name,
                                style: GoogleFonts.montserrat(
                                  fontSize:
                                      ResponsiveSize.getResponsiveFontSize(
                                        18,
                                        containerWidth,
                                      ),
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.darkColor,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              // Make rating section flexible
                              flex: 1,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    shop.rating.toStringAsFixed(1),
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          ResponsiveSize.getResponsiveFontSize(
                                            14,
                                            containerWidth,
                                          ),
                                      color: AppConstants.darkColor,
                                    ),
                                  ),
                                  if (shop.reviewCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${shop.reviewCount})',
                                      style: GoogleFonts.montserrat(
                                        fontSize:
                                            ResponsiveSize.getResponsiveFontSize(
                                              13,
                                              containerWidth,
                                            ),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: containerWidth < 200 ? 4 : 6,
                        ), // Responsive spacing
                        // Categories under name
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              shop.categories.map((category) {
                                return Container(
                                  padding: ResponsiveSize.getScaledPadding(
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'category_${category.toLowerCase()}'.tr(
                                      context,
                                    ),
                                    style: GoogleFonts.montserrat(
                                      fontSize:
                                          ResponsiveSize.getResponsiveFontSize(
                                            12,
                                            containerWidth,
                                          ),
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(
                          height: containerWidth < 200 ? 6 : 10,
                        ), // Responsive spacing
                        // Subservices available
                        Builder(
                          builder: (context) {
                            final subServiceNames = <String>[];
                            shop.subServices.forEach((cat, subs) {
                              subServiceNames.addAll(
                                subs.map(
                                  (id) => RepairSubService(
                                    categoryId: cat,
                                    id: id,
                                    name: '',
                                    description: '',
                                  ).getLocalizedName(context),
                                ),
                              );
                            });
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.build,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    subServiceNames.isNotEmpty
                                        ? subServiceNames.take(3).join(', ') +
                                            (subServiceNames.length > 3
                                                ? '...'
                                                : '')
                                        : 'no_subservices'.tr(context),
                                    style: GoogleFonts.montserrat(
                                      fontSize:
                                          ResponsiveSize.getResponsiveFontSize(
                                            13,
                                            containerWidth,
                                          ),
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(
                          height: containerWidth < 200 ? 4 : 8,
                        ), // Responsive spacing
                        // Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.address,
                                style: GoogleFonts.montserrat(
                                  fontSize:
                                      ResponsiveSize.getResponsiveFontSize(
                                        14,
                                        containerWidth,
                                      ),
                                  color: Colors.grey[700],
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: containerWidth < 200 ? 8 : 16,
                        ), // Responsive spacing
                        // View Details button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final selectedCategory = _getSelectedCategory();
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => ShopDetailScreen(
                                        shopId: shop.id,
                                        selectedCategory: selectedCategory,
                                      ),
                                ),
                              );
                              if (result is Map<String, dynamic> &&
                                  result.containsKey('filterCategory')) {
                                final category =
                                    result['filterCategory'] as String;
                                _filterShopsByCategory(category);
                                setState(() {
                                  _selectedCategoryId = category;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'view_details'.tr(context),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: ResponsiveSize.getResponsiveFontSize(
                                  15,
                                  containerWidth,
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

  // Add a new method to filter shops by category
  void _filterShopsByCategory(String categoryId) {
    // Handle "All" category as a special case
    if (categoryId == 'all') {
      _clearFilters();
      setState(() {
        _selectedCategoryId = 'all';
        _selectedSubServiceId = null;
      });
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubServiceId = null;
      _filteredShops =
          _shops.where((shop) {
            return shop.categories.any(
              (category) => category.toLowerCase() == categoryId.toLowerCase(),
            );
          }).toList();
    });

    // Scroll to the top to show filtered results
    if (_filteredShops.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Add methods to check if we're filtered and to clear filters
  bool _isFiltered() {
    // Check if we have a category filter active
    return _selectedCategoryId != 'all';
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = 'all';
      _selectedSubServiceId = null;
      _filteredShops = _shops;
    });
  }

  Widget _buildSimpleLanguageSelector() {
    // Hide language selector for admin deployments
    if (WebConfig.isAdminOnlyDeployment) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        // Toggle between languages
        final newLang = _currentLanguage == 'en' ? 'th' : 'en';
        _changeLanguage(newLang);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLanguage == 'en' ? 'English' : 'ไทย',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    // Set the new language
    await AppLocalizationsService.setLocale(languageCode);

    setState(() {
      _currentLanguage = languageCode;
    });

    // Show a short confirmation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'en'
                ? 'Language changed to English'
                : 'เปลี่ยนภาษาเป็นภาษาไทย',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    }

    // Refresh the page if running on web
    if (kIsWeb) {
      html.window.location.reload();
    }
  }

  void _launchFeedbackForm() async {
    final Uri url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLScIEoSedtD3w-cvMDp6U4h_pe2aIUpWaE4tpf14maPhZUTlRQ/viewform?usp=pp_url',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // If unable to launch URL, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open feedback form. Please try again later.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Add this new method to build sub-services section
  Widget _buildSubServicesSection() {
    if (_selectedCategoryId == 'all') return const SizedBox.shrink();

    final categories = RepairCategory.getCategories();
    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    if (selectedCategory.subServices.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'available_subservices_label'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    selectedCategory.subServices.map((subService) {
                      final isSelected = _selectedSubServiceId == subService.id;
                      return InkWell(
                        onTap: () async {
                          _showTemporaryLoadingOverlay();
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );
                          setState(() {
                            _selectedSubServiceId =
                                isSelected ? null : subService.id;
                          });
                          _filterShopsBySubService(subService.id);
                        },
                        child: Container(
                          padding: ResponsiveSize.getScaledPadding(
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppConstants.primaryColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppConstants.primaryColor
                                      : AppConstants.primaryColor.withOpacity(
                                        0.3,
                                      ),
                            ),
                          ),
                          child: Text(
                            RepairSubService(
                              categoryId: selectedCategory.id,
                              id: subService.id,
                              name: '',
                              description: '',
                            ).getLocalizedName(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppConstants.darkColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add this new method to filter shops by sub-service
  void _filterShopsBySubService(String subServiceId) {
    setState(() {
      _filteredShops =
          _shops.where((shop) {
            final shopSubServices = shop.subServices[_selectedCategoryId] ?? [];
            return shopSubServices.contains(subServiceId);
          }).toList();
    });

    // Scroll to the top to show filtered results
    if (_filteredShops.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showTemporaryLoadingOverlay() async {
    setState(() {
      _showLoadingOverlay = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showLoadingOverlay = false;
      });
    }
  }

  /// Get user location with 10-second timeout
  Future<void> _getUserLocationWithTimeout() async {
    try {
      // Try to get location with 10-second timeout
      await _getUserLocation().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      appLog(
        'Location request timed out after 10 seconds - showing shop list anyway',
      );
      setState(() {
        _locationPermissionDenied = true;
        _userDistrict = 'Location timeout - showing all shops';
      });
    } catch (e) {
      appLog('Error getting location: $e');
      setState(() {
        _locationPermissionDenied = true;
        _userDistrict = 'Location unavailable - showing all shops';
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationPermissionDenied = true;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
      });
      // Reverse geocode for district
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _userDistrict = placemarks.first.subAdministrativeArea;
        });
      }
      _sortShopsByDistance();
    } catch (e) {
      setState(() {
        _locationPermissionDenied = true;
      });
    }
  }

  void _sortShopsByDistance() {
    if (_userPosition == null) return;
    setState(() {
      _filteredShops.sort((a, b) {
        double da = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        double db = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return da.compareTo(db);
      });
    });
  }
}
