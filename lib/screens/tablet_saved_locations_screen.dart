import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/design_tokens.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/saved_shop_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';

class TabletSavedLocationsScreen extends StatefulWidget {
  const TabletSavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _TabletSavedLocationsScreenState createState() =>
      _TabletSavedLocationsScreenState();
}

class _TabletSavedLocationsScreenState extends State<TabletSavedLocationsScreen>
    with WidgetDisposalMixin<TabletSavedLocationsScreen> {
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
  bool _isSidebarCollapsed = false;

  @override
  void onInitState() {
    super.onInitState();
    _checkLoginStatus();

    // Listen for auth state changes
    listenToStream(FirebaseAuth.instance.authStateChanges(), (User? user) {
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
          orphanedIds.add(id);
        }
      }

      // Clean up orphaned IDs
      if (orphanedIds.isNotEmpty) {
        for (String id in orphanedIds) {
          await _savedShopService.removeShop(id);
        }
        appLog('Cleaned up ${orphanedIds.length} orphaned saved shop IDs');
      }

      setState(() {
        _savedShops = shops;
        _filteredShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      appLog('Error loading saved shops: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredShops =
          _savedShops.where((shop) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                shop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                shop.address.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesCategory =
                _selectedCategoryId == 'all' ||
                shop.categories.contains(_selectedCategoryId);

            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    if (!_isLoggedIn) {
      return _buildLoginPrompt();
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left sidebar with filters (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 0 : 250,
            child:
                _isSidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildTabletSidebar(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with search and toggle button
                _buildTabletHeader(),
                // Shop grid (2 columns for tablet)
                Expanded(child: _buildTabletShopGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeLg,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = true;
                    });
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // Filter controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              children: [
                // Search bar
                TextField(
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search saved shops...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                // Category filter
                _buildCategoryFilter(),
                const SizedBox(height: DesignTokens.spacingLg),
                // Stats
                _buildStatsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            _buildCategoryItem('All', 'all', FontAwesomeIcons.list),
            _buildCategoryItem('Clothing', 'clothing', FontAwesomeIcons.shirt),
            _buildCategoryItem(
              'Footwear',
              'footwear',
              FontAwesomeIcons.shoePrints,
            ),
            _buildCategoryItem('Watches', 'watch', FontAwesomeIcons.clock),
            _buildCategoryItem('Bags', 'bag', FontAwesomeIcons.briefcase),
            _buildCategoryItem(
              'Appliances',
              'appliance',
              FontAwesomeIcons.plug,
            ),
            _buildCategoryItem(
              'Electronics',
              'electronics',
              FontAwesomeIcons.laptop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String name, String categoryId, IconData icon) {
    final isSelected = _selectedCategoryId == categoryId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Material(
        color:
            isSelected
                ? AppConstants.primaryColor.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategoryId = categoryId;
            });
            _applyFilters();
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color:
                      isSelected ? AppConstants.primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: DesignTokens.fontSizeSm,
                      fontWeight:
                          isSelected
                              ? DesignTokens.fontWeightSemiBold
                              : DesignTokens.fontWeightNormal,
                      color:
                          isSelected
                              ? AppConstants.primaryColor
                              : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 16,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  'Total Saved: ${_savedShops.length}',
                  style: GoogleFonts.inter(fontSize: DesignTokens.fontSizeSm),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  'Filtered: ${_filteredShops.length}',
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeSm,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      padding: DesignTokens.getResponsivePadding(ResponsiveSize.screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Row(
        children: [
          // Toggle sidebar button
          if (_isSidebarCollapsed)
            IconButton(
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = false;
                });
              },
              icon: const Icon(Icons.menu),
            ),
          // Title
          Text(
            'Saved Locations',
            style: GoogleFonts.inter(
              fontSize: DesignTokens.fontSizeXl,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const Spacer(),
          // Clear all button
          if (_savedShops.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _showClearAllDialog();
              },
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletShopGrid() {
    if (_filteredShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _savedShops.isEmpty ? Icons.bookmark_border : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              _savedShops.isEmpty
                  ? 'No saved locations yet'
                  : 'No shops match your filters',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              _savedShops.isEmpty
                  ? 'Start saving shops you like!'
                  : 'Try adjusting your search or filters',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeSm,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: DesignTokens.getResponsivePadding(ResponsiveSize.screenWidth),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns for tablet
        childAspectRatio: 0.8,
        crossAxisSpacing: DesignTokens.spacingMd,
        mainAxisSpacing: DesignTokens.spacingMd,
      ),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        final shop = _filteredShops[index];
        return _buildTabletShopCard(shop);
      },
    );
  }

  Widget _buildTabletShopCard(RepairShop shop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailScreen(shopId: shop.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusLg),
                  ),
                  image:
                      shop.photos.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(shop.photos.first),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    shop.photos.isEmpty
                        ? Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.store,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                        : null,
              ),
            ),
            // Shop info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: GoogleFonts.inter(
                        fontSize: DesignTokens.fontSizeMd,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      shop.address,
                      style: GoogleFonts.inter(
                        fontSize: DesignTokens.fontSizeSm,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: DesignTokens.fontSizeSm,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _removeSavedShop(shop);
                          },
                          icon: const Icon(Icons.bookmark_remove),
                          iconSize: 20,
                          color: Colors.red[600],
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

  Widget _buildLoginPrompt() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              'Please log in to view your saved locations',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingLg,
                  vertical: DesignTokens.spacingMd,
                ),
              ),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              'Error loading saved locations',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            ElevatedButton(
              onPressed: _loadSavedShops,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeSavedShop(RepairShop shop) async {
    try {
      await _savedShopService.removeShop(shop.id);
      setState(() {
        _savedShops.removeWhere((s) => s.id == shop.id);
        _filteredShops.removeWhere((s) => s.id == shop.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${shop.name} removed from saved locations'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      appLog('Error removing saved shop: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error removing shop'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Saved Locations'),
            content: const Text(
              'Are you sure you want to remove all saved locations? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _clearAllSavedShops();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Future<void> _clearAllSavedShops() async {
    try {
      // Get all saved shop IDs and remove them one by one
      final savedShopIds = await _savedShopService.getSavedShopIds();
      for (String id in savedShopIds) {
        await _savedShopService.removeShop(id);
      }
      setState(() {
        _savedShops.clear();
        _filteredShops.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All saved locations cleared'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      appLog('Error clearing saved shops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error clearing saved locations'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
