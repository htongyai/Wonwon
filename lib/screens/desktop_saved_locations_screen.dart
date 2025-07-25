import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/saved_shop_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/auth_wrapper.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/widgets/search_bar_widget.dart';
import 'package:wonwonw2/services/auth_state_service.dart';
import 'package:go_router/go_router.dart';

class DesktopSavedLocationsScreen extends StatefulWidget {
  const DesktopSavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _DesktopSavedLocationsScreenState createState() =>
      _DesktopSavedLocationsScreenState();
}

class _DesktopSavedLocationsScreenState
    extends State<DesktopSavedLocationsScreen> {
  final SavedShopService _savedShopService = SavedShopService();
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();

  List<RepairShop> _savedShops = [];
  List<RepairShop> _filteredShops = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      if (isLoggedIn) {
        _loadSavedShops();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedShops() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get IDs of saved shops
      final savedShopIds = await _savedShopService.getSavedShopIds();

      // Load details for each saved shop
      final shops = <RepairShop>[];
      for (String id in savedShopIds) {
        final shop = await _shopService.getShopById(id);
        if (shop != null) {
          shops.add(shop);
        }
      }

      if (mounted) {
        setState(() {
          _savedShops = shops;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved shops: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _applyFilters() {
    List<RepairShop> filtered = _savedShops;

    // Apply category filter
    if (_selectedCategoryId != 'all') {
      filtered =
          filtered
              .where((shop) => shop.categories.contains(_selectedCategoryId))
              .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((shop) {
            final nameMatch = shop.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final addressMatch = shop.address.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final categoryMatch = shop.categories.any(
              (category) => 'category_${category.toLowerCase()}'
                  .tr(context)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
            );
            return nameMatch || addressMatch || categoryMatch;
          }).toList();
    }

    setState(() {
      _filteredShops = filtered;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilters();
  }

  Future<void> _removeShop(RepairShop shop) async {
    try {
      await _savedShopService.removeShop(shop.id);
      await _loadSavedShops();
    } catch (e) {
      print('Error removing shop: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FeatureAuthGate(
        featureAccess: FeatureAccess.requiresLogin,
        unauthorizedWidget: _buildLoginRequired(),
        child:
            _isLoading
                ? _buildLoadingScreen()
                : _hasError
                ? _buildErrorScreen()
                : _savedShops.isEmpty
                ? _buildEmptyState()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(color: AppConstants.primaryColor),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'error_loading_saved'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSavedShops,
            child: Text('try_again'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'login_required'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'login_to_view_saved'.tr(context),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToLogin,
            icon: const Icon(Icons.login),
            label: Text('login'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_saved_locations'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'save_shops_to_see_here'.tr(context),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.bookmark,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'saved_locations'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                onPressed: _loadSavedShops,
                icon: Icon(Icons.refresh, color: AppConstants.primaryColor),
                tooltip: 'refresh'.tr(context),
              ),
            ],
          ),
        ),

        // Search and filters
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              AnimatedSearchBar(
                onSearch: _handleSearch,
                hintText: 'search_saved_locations'.tr(context),
              ),
              const SizedBox(height: 24),

              // Categories
              Text(
                'categories'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoriesGrid(),
            ],
          ),
        ),

        // Shops grid
        Expanded(
          child: _filteredShops.isEmpty ? _buildNoResults() : _buildShopsGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = RepairCategory.getCategories();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        childAspectRatio: 1.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategoryId == category.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _filterByCategory(category.id),
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
                    color:
                        isSelected ? Colors.white : AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category.name.tr(context),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
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
      },
    );
  }

  Widget _buildShopsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        return _buildShopCard(_filteredShops[index]);
      },
    );
  }

  Widget _buildShopCard(RepairShop shop) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final result = await context.push('/shops/${shop.id}');
          if (result == true) {
            // Refresh if shop was removed from saved
            _loadSavedShops();
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
                          ? Image.network(
                            shop.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder(shop.name);
                            },
                          )
                          : _buildImagePlaceholder(shop.name),
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
                              fontSize: 16,
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
                                fontSize: 13,
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
                        Icon(Icons.build, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.subServices.isNotEmpty
                                ? '${shop.subServices.values.first.length} services'
                                : 'No subservices',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
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
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
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
                                  final result = await context.push(
                                    '/shops/${shop.id}',
                                  );
                                  if (result == true) {
                                    _loadSavedShops();
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Center(
                                  child: Text(
                                    'View Details',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _removeShop(shop),
                              borderRadius: BorderRadius.circular(6),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String shopName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.primaryColor.withOpacity(0.8),
            AppConstants.primaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
          style: GoogleFonts.montserrat(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_matching_results'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'try_different_search'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
