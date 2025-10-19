import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/design_tokens.dart';
import '../models/repair_shop.dart';
import 'add_shop_screen.dart';
import 'shop_detail_screen.dart';
import '../services/shop_service.dart';
import '../utils/responsive_size.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../utils/app_logger.dart';
import 'dart:async';
import '../mixins/widget_disposal_mixin.dart';

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen>
    with WidgetDisposalMixin<TabletHomeScreen>, SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  List<RepairShop> _shops = <RepairShop>[];
  List<RepairShop> _filteredShops = <RepairShop>[];
  bool _isLoading = true;
  bool _isShopsLoading = true;
  bool _isCategorySidebarCollapsed = false;
  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = createAnimationController(
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    _initializeData();

    AppLocalizationsService().localeStream.listen((locale) {
      if (mounted) {
        // Language change handled by AppLocalizationsService
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      await _loadShops();
    } on Exception catch (e) {
      appLog('Error during data initialization: $e');
      setState(() {
        _isShopsLoading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _isShopsLoading = true;
    });

    try {
      final shops = await _shopService.getAllShops();
      setState(() {
        _shops = shops;
        _filteredShops = shops;
        _isShopsLoading = false;
      });
    } on Exception catch (e) {
      appLog('Error loading shops: $e');
      setState(() {
        _isShopsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: <Widget>[
          // Left sidebar with categories (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCategorySidebarCollapsed ? 0 : 200,
            child:
                _isCategorySidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildCategorySidebar(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: <Widget>[
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

  Widget _buildCategorySidebar() => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      boxShadow: DesignTokens.shadowSm,
    ),
    child: Column(
      children: <Widget>[
        // Sidebar header
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Row(
            children: <Widget>[
              Text(
                'Categories',
                style: GoogleFonts.inter(
                  fontSize: DesignTokens.fontSizeLg,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isCategorySidebarCollapsed = true;
                  });
                },
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ],
          ),
        ),
        // Category list
        Expanded(
          child: ListView(
            children: <Widget>[
              _buildCategoryItem('All', 'all', FontAwesomeIcons.list),
              _buildCategoryItem(
                'Clothing',
                'clothing',
                FontAwesomeIcons.shirt,
              ),
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
      ],
    ),
  );

  Widget _buildCategoryItem(String name, String categoryId, IconData icon) {
    final isSelected = _selectedCategoryId == categoryId;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: DesignTokens.spacingXs,
      ),
      child: Material(
        color:
            isSelected
                ? AppConstants.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategoryId = categoryId;
              _filterShops();
            });
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 20,
                  color:
                      isSelected ? AppConstants.primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: DesignTokens.spacingMd),
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

  Widget _buildTabletHeader() => Container(
    padding: DesignTokens.getResponsivePadding(ResponsiveSize.screenWidth),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: DesignTokens.shadowSm,
    ),
    child: Row(
      children: <Widget>[
        // Toggle sidebar button
        if (_isCategorySidebarCollapsed)
          IconButton(
            onPressed: () {
              setState(() {
                _isCategorySidebarCollapsed = false;
              });
            },
            icon: const Icon(Icons.menu),
          ),
        // Search bar
        Expanded(
          child: TextField(
            onChanged: (String query) {
              setState(() {
                _searchQuery = query;
                _filterShops();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search shops, services, locations...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingMd),
        // Add shop button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const AddShopScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Shop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingSm,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTabletShopGrid() {
    if (_isShopsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              'No shops found',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                color: Colors.grey[600],
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
      itemBuilder: (BuildContext context, int index) {
        final RepairShop shop = _filteredShops[index];
        return _buildTabletShopCard(shop);
      },
    );
  }

  Widget _buildTabletShopCard(RepairShop shop) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
    ),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (BuildContext context) => ShopDetailScreen(shopId: shop.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
                children: <Widget>[
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
                    children: <Widget>[
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
                      Text(
                        '\$${shop.priceRange}',
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeSm,
                          color: Colors.green[600],
                          fontWeight: DesignTokens.fontWeightMedium,
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

  void _filterShops() {
    setState(() {
      _filteredShops =
          _shops.where((RepairShop shop) {
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
  void onDispose() {
    _animationController.dispose();
    super.onDispose();
  }
}
