// This is the main Home Screen for the WonWon app
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/advanced_search_bar.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/error_handler.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/widgets/notification_icon.dart';
import 'package:wonwonw2/services/notification_controller.dart';

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

  // Controller and variables for pull to refresh
  late ScrollController _scrollController;
  bool _isRefreshing = false;
  double _refreshIndicatorExtent = 0;
  double? _lastScrollPixels;
  int _lastScrollDirection = 0; // -1 = pulling down, 1 = releasing

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

    // Listen for language changes (auto-cancelled by WidgetDisposalMixin)
    listenToStream(AppLocalizationsService().localeStream, (locale) async {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _showLoadingOverlay = false;
          });
        }
      }
    });

    // Listen for auth state changes (auto-cancelled by WidgetDisposalMixin)
    listenToStream(FirebaseAuth.instance.authStateChanges(), (User? user) {
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

      await Future.wait(futures);
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
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
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
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
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
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _isAuthenticated
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
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

  Future<void> _loadCurrentLanguage() async {
    await AppLocalizationsService.getLocale();
  }

  void _scrollListener() {
    final pixels = _scrollController.position.pixels;
    int direction = 0;
    if (_lastScrollPixels != null) {
      direction =
          pixels < _lastScrollPixels!
              ? -1
              : (pixels > _lastScrollPixels! ? 1 : _lastScrollDirection);
    }
    _lastScrollPixels = pixels;

    final newRefreshing =
        pixels < -60 ? true : (pixels >= 0 ? false : _isRefreshing);
    final newExtent = pixels < 0 ? pixels.abs().clamp(0.0, 60.0) : 0.0;
    final directionChanged = direction != _lastScrollDirection;
    _lastScrollDirection = direction;

    // Throttle: only call setState when scroll direction changes, refresh threshold crosses,
    // or extent changes by at least 10 pixels (quantization for smoother pull feedback)
    const extentStep = 10.0;
    final extentStepChanged =
        ((newExtent / extentStep).floor() !=
            (_refreshIndicatorExtent / extentStep).floor());
    final shouldUpdate =
        directionChanged ||
        newRefreshing != _isRefreshing ||
        (pixels >= 0 && _refreshIndicatorExtent > 0) ||
        extentStepChanged;
    if (shouldUpdate) {
      setState(() {
        _isRefreshing = newRefreshing;
        _refreshIndicatorExtent = newExtent;
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
      if (!mounted) return;
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
      ErrorHandler.showSuccess(context, 'shop_list_refreshed'.tr(context));
    } catch (e) {
      appLog('Error loading shops: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ErrorHandler.handleError(
        context,
        e,
        customMessage: 'failed_to_refresh'.tr(context),
        onRetry: _loadShops,
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
        final baseList = _isFiltered() ? _filteredShops : _shops;

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
                    PerformanceLoadingWidget(
                      message: 'loading_shops_services'.tr(context),
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
                      SnackBar(
                        content: Text('please_login_to_add_shop'.tr(context)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'add_new_shop_tooltip'.tr(context),
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
          key: const PageStorageKey<String>('home_screen_scroll'),
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
                              ? 'release_to_refresh'.tr(context)
                              : 'pull_to_refresh'.tr(context),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean header: logo + notification bell
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: Image.asset(
                            'assets/images/wwg.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.screwdriverWrench,
                                    size: 16,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _isAuthenticated
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      ).then((_) {
                                        if (mounted) _loadShops();
                                      });
                                    },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _isAuthenticated
                                      ? AppConstants.primaryColor.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isAuthenticated ? Icons.person : Icons.person_outline,
                                  size: 20,
                                  color: _isAuthenticated
                                      ? AppConstants.primaryColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            NotificationIcon(
                              onTap: () {
                                NotificationController().openSidebar();
                              },
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0, 0.6, curve: Curves.easeOut),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
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
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppConstants.darkColor,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Search bar
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
                          begin: const Offset(0, 0.15),
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
                        child: AdvancedSearchBar(
                          onSearch: _handleSearch,
                          onSuggestionSelected: _handleSearch,
                          searchService: ServiceManager().advancedSearchService,
                          shops: _shops,
                          hintText: 'search_shops_services'.tr(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Categories heading
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
                      child: Text(
                        'categories'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppConstants.darkColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                child: SizedBox(height: 48, child: _buildCategoriesSection()),
              ),
            ),

            // Add sub-services section after categories
            SliverToBoxAdapter(child: _buildSubServicesSection()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isFiltered()
                            ? 'filtered_results'.tr(context)
                            : (_searchQuery.isEmpty
                                ? (_userPosition != null
                                    ? 'shops_near_you'.tr(context)
                                    : 'recommended_shops'.tr(context))
                                : 'search_results'.tr(context)),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppConstants.darkColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (_isFiltered())
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text('clear'.tr(context)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
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
                : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final shop = _filteredShops[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final delay = 0.5 + (index * 0.05);
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
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: RepaintBoundary(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index < _filteredShops.length - 1 ? 16 : 0,
                            ),
                            child: _buildShopCard(shop),
                          ),
                        ),
                      );
                    }, childCount: _filteredShops.length),
                  ),
                ),

            // Add extra bottom padding for the navigation bar (increased to match new height)
            SliverToBoxAdapter(
              child: SizedBox(height: ResponsiveSize.getHeight(9)),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getUserLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text('my_location'.tr(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                    ),
                    if (_userDistrict != null)
                      Text(
                        '${_userDistrict!}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    if (_locationPermissionDenied)
                      Text(
                        'location_permission_required'.tr(context),
                        style: const TextStyle(color: Colors.red, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: EdgeInsets.only(
            right: index == categories.length - 1 ? 20 : 8,
          ),
          child: _buildCategoryCard(category),
        );
      },
    );
  }

  Widget _buildCategoryCard(RepairCategory category) {
    final isSelected = _selectedCategoryId == category.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        _showTemporaryLoadingOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        if (category.id == 'all') {
          _clearFilters();
          setState(() {
            _selectedCategoryId = 'all';
          });
        } else if (isSelected) {
          _clearFilters();
          setState(() {
            _selectedCategoryId = 'all';
          });
        } else {
          _filterShopsByCategory(category.id);
          setState(() {
            _selectedCategoryId = category.id;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category.id),
              color: isSelected ? Colors.white : AppConstants.darkColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              category.getLocalizedName(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppConstants.darkColor,
              ),
            ),
          ],
        ),
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

  Widget _buildShopCard(RepairShop shop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
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
              if (!mounted) return;
              if (result is Map<String, dynamic> &&
                  result.containsKey('filterCategory')) {
                final category = result['filterCategory'] as String;
                _filterShopsByCategory(category);
                setState(() {
                  _selectedCategoryId = category;
                });
              }
            },
            splashColor: AppConstants.primaryColor.withValues(alpha: 0.08),
            highlightColor: AppConstants.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large image area
                  Hero(
                    tag: 'shop-image-${shop.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            shop.photos.isNotEmpty
                                ? getCachedImage(
                                  imageUrl: shop.photos.first,
                                  imageType: ImageType.shop,
                                  priority: MemoryPriority.normal,
                                  fit: BoxFit.cover,
                                  width: containerWidth,
                                  height: 180,
                                  errorWidget: AssetHelpers.getShopPlaceholder(
                                    shop.name,
                                    containerWidth: containerWidth,
                                    containerHeight: 180,
                                  ),
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppConstants.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                                : AssetHelpers.getShopPlaceholder(
                                  shop.name,
                                  containerWidth: containerWidth,
                                  containerHeight: 180,
                                ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.35),
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

                  // Content area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name + inline rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: AppConstants.darkColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star_rounded,
                              color: AppConstants.primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            if (shop.reviewCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '(${shop.reviewCount})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Category as subtle grey text
                        if (shop.categories.isNotEmpty)
                          Text(
                            shop.categories
                                .map(
                                  (c) =>
                                      'category_${c.toLowerCase()}'.tr(context),
                                )
                                .join(' · '),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),

                        // Address with pin icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey[400],
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                shop.address,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

    if (_filteredShops.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
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

  // Sub-services section
  Widget _buildSubServicesSection() {
    if (_selectedCategoryId == 'all') return const SizedBox.shrink();

    final categories = RepairCategory.getCategories();
    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    if (selectedCategory.subServices.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'available_subservices_label'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedCategory.subServices.map((subService) {
                  final isSelected = _selectedSubServiceId == subService.id;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      _showTemporaryLoadingOverlay();
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (!mounted) return;
                      setState(() {
                        _selectedSubServiceId =
                            isSelected ? null : subService.id;
                      });
                      _filterShopsBySubService(subService.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppConstants.primaryColor
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        RepairSubService(
                          categoryId: selectedCategory.id,
                          id: subService.id,
                          name: '',
                          description: '',
                        ).getLocalizedName(context),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppConstants.darkColor,
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
          ),
        ],
      ),
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

    if (_filteredShops.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _locationPermissionDenied = true;
        _userDistrict = 'location_timeout_showing_all'.tr(context);
      });
    } catch (e) {
      appLog('Error getting location: $e');
      if (!mounted) return;
      setState(() {
        _locationPermissionDenied = true;
        _userDistrict = 'location_unavailable_showing_all'.tr(context);
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationPermissionDenied = true;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = position;
      });
      // Reverse geocode for district
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _userDistrict = placemarks.first.subAdministrativeArea;
        });
      }
      _sortShopsByDistance();
    } catch (e) {
      if (!mounted) return;
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
