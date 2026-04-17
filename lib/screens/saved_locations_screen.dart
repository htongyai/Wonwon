import 'dart:async';

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
import 'package:wonwonw2/widgets/optimized_image.dart';
import 'package:wonwonw2/widgets/common/shimmer_loading.dart';

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
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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

      // Batch load shop details (uses Firestore whereIn, chunked to 10 per query)
      final shops = await _shopService.getShopsByIds(savedShopIds);

      // Find orphaned IDs (shops that no longer exist)
      final loadedIds = shops.map((s) => s.id).toSet();
      final orphanedIds =
          savedShopIds.where((id) => !loadedIds.contains(id)).toList();
      if (orphanedIds.isNotEmpty) {
        for (final id in orphanedIds) {
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

    if (confirmed != true || !mounted) return;
    await _performRemoveShop(shop);
  }

  Future<void> _performRemoveShop(RepairShop shop) async {
    try {
      final success = await _savedShopService.removeShop(shop.id);
      if (!mounted) return;
      if (success) {
        setState(() {
          _savedShops.removeWhere((s) => s.id == shop.id);
          _applyFilters();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_remove'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true && mounted) {
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

            // Categories chips row
            if (_isLoggedIn &&
                !_isLoading &&
                !_hasError &&
                _savedShops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildCategoriesSection(),
              ),

            // Main content
            Expanded(
              child:
                  _isLoading
                      ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 4,
                        itemBuilder: (context, index) =>
                            const ShimmerShopCard(),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(FontAwesomeIcons.bookmark, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'no_saved_locations'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'locations_will_appear'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                if (context.mounted) {
                  final mainNav = MainNavigationState.of(context);
                  if (mainNav != null) {
                    mainNav.onTap(0);
                  }
                }
              },
              icon: const Icon(Icons.search),
              label: Text(
                'find_repair_shops'.tr(context),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchingCategory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_list_off, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'no_matching_category'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_category'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                if (context.mounted) {
                  final mainNav = MainNavigationState.of(context);
                  if (mainNav != null) {
                    mainNav.onTap(0);
                  }
                }
              },
              icon: const Icon(Icons.search),
              label: Text(
                'find_repair_shops'.tr(context),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedShopsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedShops,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        key: const PageStorageKey<String>('saved_locations_list'),
        padding: const EdgeInsets.all(16),
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          final shop = _filteredShops[index];
          return Dismissible(
            key: Key(shop.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            onDismissed: (_) => _performRemoveShop(shop),
            child: RepaintBoundary(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShopDetailScreen(shopId: shop.id),
                      ),
                    );
                    if (!mounted) return;
                    _loadSavedShops();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              shop.photos.isNotEmpty
                                  ? OptimizedImage(
                                    imageUrl: shop.photos.first,
                                    fit: BoxFit.cover,
                                    width: MediaQuery.of(context).size.width - 32,
                                    height: 160,
                                    errorWidget: AssetHelpers.getShopPlaceholder(
                                      shop.name,
                                      containerWidth: 300,
                                      containerHeight: 200,
                                    ),
                                  )
                                  : AssetHelpers.getShopPlaceholder(
                                    shop.name,
                                    containerWidth: 300,
                                    containerHeight: 200,
                                  ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => _removeShop(shop),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.darkColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey[500],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    shop.address,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  shop.categories
                                      .take(3)
                                      .map((category) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            'category_$category'.tr(context),
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
              ),
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
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == categories.length - 1 ? 0 : 8,
            ),
            child: _buildCategoryChip(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(RepairCategory category) {
    final isSelected = _selectedCategoryId == category.id;

    return GestureDetector(
      onTap: () => _filterShopsByCategory(category.id),
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
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppConstants.darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
