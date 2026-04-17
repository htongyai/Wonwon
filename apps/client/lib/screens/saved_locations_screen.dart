import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/models/repair_category.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/screens/main_navigation.dart';
import 'package:wonwon_client/screens/shop_detail_screen.dart';

import 'package:shared/services/saved_shop_service.dart';
import 'package:shared/services/shop_service.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/widgets/shop_card.dart';
import 'package:shared/utils/app_logger.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final SavedShopService _savedShopService = SavedShopService();
  final ShopService _shopService = ShopService();


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

    _authSubscription =
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedShops() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final savedShopIds = await _savedShopService.getSavedShopIds();
      final shops = await _shopService.getShopsByIds(savedShopIds);

      // Clean up orphaned IDs
      final loadedIds = shops.map((s) => s.id).toSet();
      final orphanedIds =
          savedShopIds.where((id) => !loadedIds.contains(id)).toList();
      if (orphanedIds.isNotEmpty) {
        appLog('Cleaning up ${orphanedIds.length} orphaned saved shop IDs');
        try {
          await _savedShopService.cleanupOrphanedShops(orphanedIds);
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
      if (categoryId == 'all' || _selectedCategoryId == categoryId) {
        _selectedCategoryId = 'all';
      } else {
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
    List<RepairShop> result = _savedShops.where((shop) {
      return shop.id != 'not-found' &&
          shop.name.isNotEmpty &&
          shop.name != 'Not Found' &&
          shop.id.isNotEmpty;
    }).toList();

    if (_selectedCategoryId != 'all') {
      result = result
          .where((shop) => shop.categories.contains(_selectedCategoryId))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((shop) {
        return shop.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            shop.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            shop.categories.any(
              (category) =>
                  category.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    _filteredShops = result;
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
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_remove'.tr(context)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      _loadSavedShops();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'saved_locations'.tr(context),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: .5,
        actions: [
          if (_isLoggedIn && _savedShops.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
              onPressed: _loadSavedShops,
              tooltip: 'refresh'.tr(context),
            ),
        ],
      ),
      body: !_isLoggedIn ? _buildLoginRequired() : _buildBody(),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_savedShops.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'search_saved_locations'.tr(context),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // Category chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: _buildCategoriesSection(),
        ),

        // Shop list
        Expanded(
          child: _filteredShops.isEmpty
              ? _buildNoMatchingCategory()
              : _buildSavedShopsList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Login required
  // ---------------------------------------------------------------------------
  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'login_required'.tr(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'login_to_view_saved'.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'login'.tr(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'error_loading_saved'.tr(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loadSavedShops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('try_again'.tr(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 48,
                color: AppConstants.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_saved_locations'.tr(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'locations_will_appear'.tr(context),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (context.mounted) {
                    final mainNav = MainNavigationState.of(context);
                    if (mainNav != null) {
                      mainNav.onTap(0);
                    }
                  }
                },
                icon: const Icon(Icons.search_rounded, size: 20),
                label: Text(
                  'find_repair_shops'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // No matching category
  // ---------------------------------------------------------------------------
  Widget _buildNoMatchingCategory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'no_matching_category'.tr(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_category'.tr(context),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryId = 'all';
                  _searchQuery = '';
                  _applyFilters();
                });
              },
              child: Text(
                'show_all_shops'.tr(context),
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shop list
  // ---------------------------------------------------------------------------
  Widget _buildSavedShopsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedShops,
      color: AppConstants.primaryColor,
      child: ListView.separated(
        key: const PageStorageKey<String>('saved_locations_list'),
        padding: const EdgeInsets.all(16),
        itemCount: _filteredShops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final shop = _filteredShops[index];
          return Dismissible(
            key: Key(shop.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'remove'.tr(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => _performRemoveShop(shop),
            child: RepaintBoundary(
              child: ShopCard(
                shop: shop,
                compact: true,
                onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shopId: shop.id),
                  ),
                );
                if (!mounted) return;
                _loadSavedShops();
              },
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category chips
  // ---------------------------------------------------------------------------
  Widget _buildCategoriesSection() {
    final categories = RepairCategory.getCategories();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _filterShopsByCategory(category.id),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(category.id),
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'category_${category.id}'.tr(context),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
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
}
