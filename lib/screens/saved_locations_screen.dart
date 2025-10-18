import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/auth_state_service.dart';
import 'package:wonwonw2/services/saved_shop_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/auth_wrapper.dart';
import 'package:wonwonw2/models/repair_category.dart';
import 'package:wonwonw2/widgets/search_bar_widget.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
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

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });

        if (user != null) {
          _loadSavedShops();
        } else {
          setState(() {
            _savedShops.clear();
            _filteredShops.clear();
            _isLoading = false;
          });
        }
      }
    });
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

      // Load details for each saved shop and clean up orphaned IDs
      final shops = <RepairShop>[];
      final orphanedIds = <String>[];

      for (String id in savedShopIds) {
        final shop = await _shopService.getShopById(id);
        if (shop != null) {
          shops.add(shop);
        } else {
          // Track orphaned IDs (shops that no longer exist)
          orphanedIds.add(id);
          appLog('Found orphaned saved shop ID: $id');
        }
      }

      // Clean up orphaned saved shop IDs using batch operation
      if (orphanedIds.isNotEmpty) {
        appLog('Cleaning up ${orphanedIds.length} orphaned saved shop IDs');
        try {
          await _savedShopService.cleanupOrphanedShops(orphanedIds);
          appLog(
            'Successfully cleaned up ${orphanedIds.length} orphaned saved shop IDs',
          );
        } catch (e) {
          appLog('Failed to cleanup orphaned saved shop IDs: $e');
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
      appLog('Error loading saved shops: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _filterShopsByCategory(String categoryId) {
    setState(() {
      if (categoryId == 'all') {
        _selectedCategoryId = 'all';
      } else if (_selectedCategoryId == categoryId) {
        // If already selected, deselect and show all
        _selectedCategoryId = 'all';
      } else {
        // Select the new category
        _selectedCategoryId = categoryId;
      }
      _applyFilters();
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Start with all saved shops and filter out invalid ones
    List<RepairShop> result =
        _savedShops.where((shop) {
          // Filter out invalid shops (not found, empty names, etc.)
          return shop.id != 'not-found' &&
              shop.name.isNotEmpty &&
              shop.name != 'Not Found' &&
              shop.id.isNotEmpty;
        }).toList();

    // Apply category filter if not 'all'
    if (_selectedCategoryId != 'all') {
      result =
          result
              .where((shop) => shop.categories.contains(_selectedCategoryId))
              .toList();
    }

    // Apply search filter if search query is not empty
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((shop) {
            return shop.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                shop.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                shop.categories.any(
                  (category) => category.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                );
          }).toList();
    }

    _filteredShops = result;
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

  Future<void> _removeShop(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('remove_saved_location'.tr(context)),
            content: Text(
              'remove_from_saved'
                  .tr(context)
                  .replaceAll('{shop_name}', shop.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'remove'.tr(context),
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final success = await _savedShopService.removeShop(shop.id);
        if (success) {
          setState(() {
            _savedShops.removeWhere((s) => s.id == shop.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'removed_from_saved'
                    .tr(context)
                    .replaceAll('{shop_name}', shop.name),
              ),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_remove'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true) {
      _checkLoginStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'saved_locations'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.darkColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoggedIn && _savedShops.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: AppConstants.primaryColor),
              onPressed: _loadSavedShops,
              tooltip: 'refresh'.tr(context),
            ),
        ],
      ),
      body: FeatureAuthGate(
        featureAccess: FeatureAccess.requiresLogin,
        unauthorizedWidget: _buildLoginRequired(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            if (_isLoggedIn &&
                !_isLoading &&
                !_hasError &&
                _savedShops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AnimatedSearchBar(
                  onSearch: _handleSearch,
                  hintText: 'search_saved_locations'.tr(context),
                ),
              ),

            // Categories heading and list
            if (_isLoggedIn &&
                !_isLoading &&
                !_hasError &&
                _savedShops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'categories'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.darkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoriesSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppConstants.primaryColor,
                        ),
                      )
                      : _hasError
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
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
                      )
                      : _savedShops.isEmpty
                      ? _buildEmptyState()
                      : _filteredShops.isEmpty
                      ? _buildNoMatchingCategory()
                      : _buildSavedShopsList(),
            ),
          ],
        ),
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
          Icon(FontAwesomeIcons.bookmark, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_saved_locations'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'locations_will_appear'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Update the navigation index to 0 (home)
              if (context.mounted) {
                final mainNav = MainNavigationState.of(context);
                if (mainNav != null) {
                  mainNav.onTap(0);
                }
              }
            },
            icon: const Icon(Icons.search),
            label: Text('find_repair_shops'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchingCategory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.bookmark, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_matching_category'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'try_different_category'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Update the navigation index to 0 (home)
              if (context.mounted) {
                final mainNav = MainNavigationState.of(context);
                if (mainNav != null) {
                  mainNav.onTap(0);
                }
              }
            },
            icon: const Icon(Icons.search),
            label: Text('find_repair_shops'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedShopsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedShops,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          final shop = _filteredShops[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shopId: shop.id),
                  ),
                );

                // Refresh the list when returning from details
                _loadSavedShops();
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Shop image with fallback
                          shop.photos.isNotEmpty
                              ? Image.network(
                                shop.photos.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return AssetHelpers.getShopPlaceholder(
                                    shop.name,
                                    containerWidth: 300,
                                    containerHeight: 200,
                                  );
                                },
                              )
                              : AssetHelpers.getShopPlaceholder(
                                shop.name,
                                containerWidth: 300,
                                containerHeight: 200,
                              ),

                          // Gradient overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  stops: const [0.6, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Shop name on image
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Text(
                              shop.name,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Remove button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => _removeShop(shop),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.xmark,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Shop details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.solidStar,
                              color: Colors.amber,
                              size: 14,
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

                        // Categories
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              shop.categories
                                  .take(3) // Show only first 3 categories
                                  .map((category) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = RepairCategory.getCategories();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(RepairCategory category) {
    // Check if this category is currently selected
    final isSelected = _selectedCategoryId == category.id;

    return GestureDetector(
      onTap: () => _filterShopsByCategory(category.id),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
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
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.getLocalizedName(context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.montserrat(
                fontSize: 12,
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
}
