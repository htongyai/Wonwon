// This is the main Home Screen for the WonWon app
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/settings_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/search_bar_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  List<RepairShop> _shops = [];
  List<RepairShop> _filteredShops = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  // Controller and variables for pull to refresh
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  double _refreshIndicatorExtent = 0;

  @override
  void initState() {
    super.initState();
    _loadShops();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();

    // Add scroll listener for custom refresh indicator
    _scrollController.addListener(_scrollListener);
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

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shops = await _shopService.getAllShops();

      // Add a small delay to show the refresh indicator
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _shops = shops;
        if (_searchQuery.isEmpty && !_isFiltered()) {
          _filteredShops = shops;
        } else if (_searchQuery.isNotEmpty) {
          // Re-apply search filter
          _handleSearch(_searchQuery);
        } else if (_isFiltered() && _filteredShops.isNotEmpty) {
          // Re-apply category filter
          final selectedCategory = _getSelectedCategory();
          if (selectedCategory != null) {
            _filterShopsByCategory(selectedCategory);
          }
        }
        _isLoading = false;
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shop list refreshed'),
          backgroundColor: AppConstants.primaryColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error loading shops: $e');
      setState(() {
        _isLoading = false;
      });

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
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
        _filteredShops =
            baseList.where((shop) {
              return shop.name.toLowerCase().contains(query.toLowerCase()) ||
                  shop.description.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  shop.categories.any(
                    (category) =>
                        category.toLowerCase().contains(query.toLowerCase()),
                  );
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
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
                padding: EdgeInsets.fromLTRB(
                  ResponsiveSize.getWidth(6), // 24px on standard screen
                  ResponsiveSize.getHeight(1.2), // 10px on standard screen
                  ResponsiveSize.getWidth(6),
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and settings row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo on the left
                        SizedBox(
                          height: ResponsiveSize.getHeight(
                            5,
                          ), // 40px on standard screen
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

                        // Settings icon at the right
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: EdgeInsets.all(ResponsiveSize.getWidth(2)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.gear,
                              color: AppConstants.darkColor,
                              size: ResponsiveSize.getWidth(3.5),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(3)),

                    // Greeting with animations
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
                        child: AnimatedSearchBar(
                          onSearch: _handleSearch,
                          hintText: 'Search for repair services...'.tr(context),
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
                    15,
                  ), // Taller height for the categories section
                  child: _buildCategoriesSection(),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  const SizedBox(height: 1),

                    // Recommended shops heading with clear filter button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isFiltered()
                              ? 'filtered_results'.tr(context)
                              : (_searchQuery.isEmpty
                                  ? 'recommended_shops'.tr(context)
                                  : 'search_results'.tr(context)),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_shops_found'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : SliverList(
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildShopCard(shop),
                      ),
                    );
                  }, childCount: _filteredShops.length),
                ),

            // Add extra bottom padding for the navigation bar (increased to match new height)
            SliverToBoxAdapter(
              child: SizedBox(height: ResponsiveSize.getHeight(9)),
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
          padding: const EdgeInsets.only(right: 12), // Smaller right padding
          child: _buildCategoryCard(category),
        );
      },
    );
  }

  Widget _buildCategoryCard(RepairCategory category) {
    // Check if this category is currently selected
    final isSelected = _selectedCategoryId == category.id;

    return GestureDetector(
      onTap: () {
        // If All category, clear filters
        if (category.id == 'all') {
          _clearFilters();
          setState(() {
            _selectedCategoryId = 'all';
          });
        }
        // If already selected, don't do anything
        else if (isSelected) {
          // Keep the same filter
        } else {
          // Filter shops by category
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
              width: 48, // Fixed width
              height: 48, // Fixed height
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
            const SizedBox(height: 4),
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

  Widget _buildShopCard(RepairShop shop) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Get the currently selected category
          final selectedCategory = _getSelectedCategory();

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ShopDetailScreen(
                    shop: shop,
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
          children: [
            // Shop image
            Hero(
              tag: 'shop-image-${shop.id}',
              child: Container(
                height: 150,
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
                          ? Image.network(
                            shop.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return AssetHelpers.getShopPlaceholder(shop.name);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              );
                            },
                          )
                          : AssetHelpers.getShopPlaceholder(shop.name),

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name
                  Text(
                    shop.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.darkColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.locationDot,
                        color: AppConstants.tertiaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Categories
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        shop.categories.map((category) {
                          return InkWell(
                            onTap: () {
                              _filterShopsByCategory(category);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'category_${category.toLowerCase()}'.tr(
                                  context,
                                ),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Get the currently selected category
                        final selectedCategory = _getSelectedCategory();

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ShopDetailScreen(
                                  shop: shop,
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
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'view_details'.tr(context),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  // Add a new method to filter shops by category
  void _filterShopsByCategory(String categoryId) {
    // Handle "All" category as a special case
    if (categoryId == 'all') {
      _clearFilters();
      setState(() {
        _selectedCategoryId = 'all';
      });
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
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
        PrimaryScrollController.of(context).animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
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
      _filteredShops = _shops;
    });
  }
}
