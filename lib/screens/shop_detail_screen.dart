import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/review.dart';
import 'package:wonwonw2/screens/edit_shop_screen.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/report_form_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/review_service.dart';
import 'package:wonwonw2/services/report_service.dart';
import 'package:wonwonw2/services/saved_shop_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonwonw2/widgets/info_row.dart';
import 'package:wonwonw2/screens/log_repair_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/utils/hours_formatter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';

/// Screen that displays detailed information about a repair shop
/// Shows shop information, hours, contact details, services, and reviews
class ShopDetailScreen extends StatefulWidget {
  final String shopId;
  final String? selectedCategory;
  const ShopDetailScreen({
    Key? key,
    required this.shopId,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen>
    with WidgetDisposalMixin<ShopDetailScreen> {
  late ScrollController _scrollController;
  final ReviewService _reviewService = ReviewService();
  final ReportService _reportService = ReportService();
  final SavedShopService _savedShopService = SavedShopService();
  final AuthService _authService = AuthService();

  RepairShop? _shop;
  bool _isLoadingShop = true;
  String? _error;
  List<Review> _reviews = [];
  List<ShopReport> _reports = [];
  bool _isLoadingReviews = true;
  bool _isLoadingReports = true;
  bool _isSaved = false;
  bool _isLoadingSavedState = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  // Removed unused fields: _showReplyInput, _replyControllers
  GoogleMapController? _mapController;

  @override
  void onInitState() {
    _scrollController = createScrollController();
    _fetchShop();
    _checkLoginStatus();
    _loadReviews();
    _loadReports();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });

        if (user != null) {
          _checkIfSaved();
          _checkAdminStatus();
        } else {
          setState(() {
            _isSaved = false;
            _isAdmin = false;
            _isLoadingSavedState = false;
          });
        }
      }
    });
  }

  Future<void> _fetchShop() async {
    setState(() {
      _isLoadingShop = true;
      _error = null;
    });
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('shops')
              .doc(widget.shopId)
              .get();
      if (!doc.exists) {
        setState(() {
          _error = 'Shop not found';
          _isLoadingShop = false;
        });
        return;
      }
      setState(() {
        _shop = RepairShop.fromMap(doc.data()!..['id'] = doc.id);
        _isLoadingShop = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading shop';
        _isLoadingShop = false;
      });
    }
  }

  /// Check if user is logged in and update UI accordingly
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      // If logged in, check if this shop is saved and check admin status
      if (isLoggedIn) {
        _checkIfSaved();
        _checkAdminStatus();
      } else {
        setState(() {
          _isLoadingSavedState = false;
        });
      }
    }
  }

  /// Check if this shop is saved by the logged-in user
  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await _savedShopService.isShopSaved(widget.shopId);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _isLoadingSavedState = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSavedState = false;
        });
      }
    }
  }

  /// Check if the current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (mounted) {
          setState(() {
            _isAdmin = userDoc.data()?['admin'] ?? false;
          });
        }
      }
    } catch (e) {
      appLog('Error checking admin status', e);
    }
  }

  /// Toggle the saved status of the shop
  /// Redirects to login if user is not logged in
  Future<void> _toggleSaved() async {
    if (_isLoadingSavedState) return;

    // If not logged in, prompt to login
    if (!_isLoggedIn) {
      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (loginResult == true) {
        // User logged in successfully
        setState(() {
          _isLoggedIn = true;
          _isLoadingSavedState = true;
        });
        await _checkIfSaved();
        return;
      } else {
        // User canceled login
        return;
      }
    }

    setState(() {
      _isLoadingSavedState = true;
    });

    try {
      bool success;
      if (_isSaved) {
        // Remove shop from saved locations
        success = await _savedShopService.removeShop(widget.shopId);
        if (success && mounted) {
          setState(() {
            _isSaved = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'removed_from_saved'
                    .tr(context)
                    .replaceAll('{shop_name}', _shop!.name),
              ),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      } else {
        // Add shop to saved locations
        success = await _savedShopService.saveShop(widget.shopId);
        if (success && mounted) {
          setState(() {
            _isSaved = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'saved_to_locations'
                    .tr(context)
                    .replaceAll('{shop_name}', _shop!.name),
              ),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error toggling saved shop: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_update_saved'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSavedState = false;
        });
      }
    }
  }

  /// Load reviews for this shop
  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getReviewsForShop(widget.shopId);
      // Collect all unique userIds from reviews and replies
      Set<String> userIds = {};
      for (var review in reviews) {
        userIds.add(review.userId);
        for (var reply in review.replies) {
          userIds.add(reply.userId);
        }
      }
      // Check which users exist (batch in groups of 10)
      Map<String, bool> existsMap = {};
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final userIdList = userIds.toList();
      for (int i = 0; i < userIdList.length; i += 10) {
        final batch = userIdList.skip(i).take(10).toList();
        if (batch.isEmpty) continue;
        final query =
            await usersCollection
                .where(FieldPath.documentId, whereIn: batch)
                .get();
        // Mark found users as existing
        for (var doc in query.docs) {
          existsMap[doc.id] = true;
        }
        // Mark not found users as not existing
        for (var id in batch) {
          if (!existsMap.containsKey(id)) {
            existsMap[id] = false;
          }
        }
      }
      // Cache for session (removed _userExistsCache field)
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  /// Load existing reports for this shop
  Future<void> _loadReports() async {
    try {
      final reports = await _reportService.getReportsByShopId(widget.shopId);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

  @override
  void onDispose() {
    // Clean up map controller (not managed by mixin)
    _mapController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingShop) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (_shop == null) {
      return Scaffold(
        body: Center(child: Text('Shop not found')), // fallback
      );
    }

    // Check if we're on desktop
    final isDesktop = ResponsiveSize.shouldShowDesktopLayout(context);

    // Debug: Print layout info
    debugPrint(
      'ShopDetailScreen - Screen width: ${MediaQuery.of(context).size.width}, isDesktop: $isDesktop',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomBar(),
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: false,
          floating: false,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                _shop!.photos.isNotEmpty
                    ? getCachedImage(
                      imageUrl: _shop!.photos.first,
                      imageType: ImageType.shop,
                      priority: MemoryPriority.high,
                      fit: BoxFit.cover,
                      errorWidget: AssetHelpers.getShopPlaceholder(
                        _shop!.name,
                        containerWidth: MediaQuery.of(context).size.width,
                        containerHeight: 200,
                      ),
                    )
                    : AssetHelpers.getShopPlaceholder(
                      _shop!.name,
                      containerWidth: MediaQuery.of(context).size.width,
                      containerHeight: 200,
                    ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.7),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Edit button - only show for admin users
                      if (_isAdmin)
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppConstants.primaryColor,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditShopScreen(shop: _shop!),
                                ),
                              );
                            },
                          ),
                        ),
                      if (_isAdmin) const SizedBox(width: 8),
                      // Report button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            child: IconButton(
                              icon: const Icon(
                                Icons.report_problem_outlined,
                                color: Colors.red,
                              ),
                              onPressed: _showReportDialog,
                            ),
                          ),
                          if (!_isLoadingReports && _reports.isNotEmpty)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Center(
                                  child: Text(
                                    _reports.length > 9
                                        ? '9+'
                                        : '${_reports.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveSize.getScaledPadding(
              const EdgeInsets.all(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopInfo(),
                SizedBox(height: ResponsiveSize.getHeight(4)),
                _buildAddress(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildHours(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildContactInfo(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildBusinessInfoSection(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildPaymentMethodsSection(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildFeaturesSection(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildDesktopMapLocation(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildReviews(),
                SizedBox(
                  height: ResponsiveSize.getHeight(20),
                ), // Space for bottom buttons
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1400;
    final isMediumScreen = screenWidth > 1000 && screenWidth <= 1400;

    // Responsive sidebar width
    double sidebarWidth;
    if (isLargeScreen) {
      sidebarWidth = 480;
    } else if (isMediumScreen) {
      sidebarWidth = 400;
    } else {
      sidebarWidth = 350;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Compact Header Bar (Google Maps style)
          _buildDesktopCompactHeader(),
          // Main Content - Google Maps inspired layout
          Expanded(
            child: Row(
              children: [
                // Left Panel - Shop Details (Google Maps style sidebar)
                Container(
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: _buildDesktopSidebar(),
                ),
                // Right Area - Map and Visual Content
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      children: [
                        // Large Map Section (fills available space)
                        Expanded(flex: 3, child: _buildDesktopMapLocation()),
                        // Reviews Section (scrollable)
                        Expanded(flex: 2, child: _buildDesktopReviewsSection()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCompactHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;
    final isVerySmall = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isVerySmall ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: isVerySmall ? 20 : 24,
                  padding: EdgeInsets.all(isVerySmall ? 8 : 12),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              // Shop Name
              Expanded(
                child: Text(
                  _shop!.name,
                  style: GoogleFonts.montserrat(
                    fontSize: isVerySmall ? 16 : (isSmallScreen ? 18 : 22),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: isVerySmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Action Buttons
              // Log Repair Button
              if (!isVerySmall)
                Container(
                  margin: EdgeInsets.only(left: isSmallScreen ? 4 : 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LogRepairScreen(shop: _shop!),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      'Log Repair',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              // Save Shop Button
              Container(
                margin: EdgeInsets.only(left: isSmallScreen ? 4 : 8),
                child: ElevatedButton.icon(
                  onPressed: _toggleSaved,
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                    size: isVerySmall ? 16 : (isSmallScreen ? 16 : 18),
                  ),
                  label: Text(
                    _isSaved ? 'Saved' : 'Save Shop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmall ? 12 : (isSmallScreen ? 12 : 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSaved
                            ? Colors.orange[700]
                            : AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmall ? 10 : (isSmallScreen ? 12 : 16),
                      vertical: isVerySmall ? 6 : (isSmallScreen ? 8 : 10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              // Report Button
              if (!isVerySmall)
                Container(
                  margin: EdgeInsets.only(left: isSmallScreen ? 4 : 8),
                  child: ElevatedButton.icon(
                    onPressed: _showReportDialog,
                    icon: Icon(
                      Icons.flag_outlined,
                      color: Colors.white,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      'Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              // Admin Edit Button
              if (_isAdmin)
                Container(
                  margin: EdgeInsets.only(left: isSmallScreen ? 4 : 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppConstants.primaryColor,
                      size: isVerySmall ? 18 : (isSmallScreen ? 20 : 24),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditShopScreen(shop: _shop!),
                        ),
                      );
                    },
                    padding: EdgeInsets.all(isVerySmall ? 8 : 12),
                  ),
                ),
            ],
          ),
          // Quick Info Row (moved to separate row to prevent overflow)
          if (!isVerySmall) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: isSmallScreen ? 48 : 56), // Align with content
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _shop!.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_shop!.area} • ${_shop!.reviewCount} reviews',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image
          if (_shop!.photos.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: getCachedImage(
                  imageUrl: _shop!.photos.first,
                  imageType: ImageType.shop,
                  priority: MemoryPriority.high,
                  fit: BoxFit.cover,
                  errorWidget: AssetHelpers.getShopPlaceholder(
                    _shop!.name,
                    containerWidth: 432,
                    containerHeight: 200,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Quick Actions (Google Maps style)
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Shop Description
          if (_shop!.description.isNotEmpty) ...[
            Text(
              'About',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _shop!.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Essential Info Cards
          _buildEssentialInfoCard(),
          const SizedBox(height: 16),
          _buildContactInfoCard(),
          const SizedBox(height: 16),
          _buildHoursInfoCard(),
          const SizedBox(height: 24),

          // Services
          _buildServicesSection(),
          const SizedBox(height: 24),

          // Photo Gallery (moved from right side)
          _buildPhotoGallerySection(),
          const SizedBox(height: 24),

          // Payment Methods
          _buildPaymentMethodsSection(),
          const SizedBox(height: 24),

          // Features & Amenities
          _buildFeaturesSection(),
          const SizedBox(height: 24),

          // Business Info
          _buildBusinessInfoSection(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Call action
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Directions action
            },
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEssentialInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _shop!.address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_shop!.area.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  _shop!.area,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            Icons.phone,
            _shop!.phoneNumber != null && _shop!.phoneNumber!.isNotEmpty
                ? _shop!.phoneNumber!
                : 'No information',
          ),
          _buildContactRow(
            Icons.facebook,
            _shop!.facebookPage?.isNotEmpty == true
                ? 'Facebook Page'
                : 'No information',
          ),
          _buildContactRow(
            Icons.camera_alt,
            _shop!.instagramPage?.isNotEmpty == true
                ? 'Instagram'
                : 'No information',
          ),
          if (_shop!.lineId?.isNotEmpty == true || _shop!.lineId == null)
            _buildContactRow(
              Icons.chat,
              _shop!.lineId?.isNotEmpty == true
                  ? 'Line: ${_shop!.lineId}'
                  : 'No information',
            ),
          if (_shop!.otherContacts?.isNotEmpty == true ||
              _shop!.otherContacts == null)
            _buildContactRow(
              Icons.contact_phone,
              _shop!.otherContacts?.isNotEmpty == true
                  ? _shop!.otherContacts!
                  : 'No information',
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildHoursInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hours',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Show all days' hours
          _buildAllDaysHours(),
        ],
      ),
    );
  }

  Widget _buildAllDaysHours() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const shortKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final today = DateTime.now().weekday;
    final todayKey = _getTodayKey(today);

    return Column(
      children: List.generate(days.length, (i) {
        final dayKey = shortKeys[i];
        final hours = _shop!.hours[dayKey];
        final isToday = dayKey == todayKey;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                days[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? AppConstants.primaryColor : Colors.grey[700],
                ),
              ),
              Text(
                HoursFormatter.formatHours(hours, context),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color:
                      isToday
                          ? AppConstants.primaryColor
                          : (hours != null
                              ? Colors.grey[800]
                              : Colors.grey[500]),
                  fontStyle:
                      hours == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildServicesSection() {
    if (_shop!.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _shop!.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_shop!.photos.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No information',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _shop!.photos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index < _shop!.photos.length - 1 ? 8 : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: getCachedImage(
                      imageUrl: _shop!.photos[index],
                      imageType: ImageType.shop,
                      priority: MemoryPriority.normal,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    final paymentMethods = _shop!.paymentMethods ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (paymentMethods.isEmpty)
          Text(
            'No information',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                paymentMethods.map((method) {
                  IconData icon;
                  switch (method.toLowerCase()) {
                    case 'cash':
                      icon = Icons.money;
                      break;
                    case 'card':
                      icon = Icons.credit_card;
                      break;
                    case 'qr':
                      icon = Icons.qr_code;
                      break;
                    default:
                      icon = Icons.payment;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          method,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = _shop!.features;
    final amenities = _shop!.amenities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features & Amenities',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (features.isEmpty && amenities.isEmpty)
          Text(
            'No information',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          )
        else ...[
          if (amenities.isNotEmpty) ...[
            Text(
              'Amenities:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            if (features.isNotEmpty) const SizedBox(height: 16),
          ],
          if (features.isNotEmpty) ...[
            Text(
              'Features:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...features.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          decoration:
                              entry.value ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ],
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Information',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Price Range', _shop!.priceRange.toString()),
        _buildInfoItem(
          'Duration',
          _shop!.durationMinutes > 0
              ? '${_shop!.durationMinutes} minutes'
              : 'No information',
        ),
        _buildInfoItem(
          'Try-on Area',
          _shop!.tryOnAreaAvailable == true
              ? 'Available'
              : (_shop!.tryOnAreaAvailable == false
                  ? 'Not Available'
                  : 'No information'),
        ),
        _buildInfoItem(
          'Purchase Required',
          _shop!.requiresPurchase == true
              ? 'Yes'
              : (_shop!.requiresPurchase == false ? 'No' : 'No information'),
        ),
        _buildInfoItem('Irregular Hours', _shop!.irregularHours ? 'Yes' : 'No'),
        _buildInfoItem(
          'Status',
          _shop!.approved ? 'Approved' : 'Pending Approval',
        ),
        if (_shop!.notesOrConditions?.isNotEmpty == true)
          _buildInfoItem('Notes', _shop!.notesOrConditions!)
        else
          _buildInfoItem('Notes', 'No information'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color:
                    value == 'No information'
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                fontStyle:
                    value == 'No information'
                        ? FontStyle.italic
                        : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopReviewsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reviews & Ratings',
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddReviewDialog,
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: isSmallScreen ? 14 : 16,
                ),
                label: Text(
                  'Write Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _shop!.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_shop!.reviewCount} reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on customer feedback',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_reviews.isNotEmpty) ...[
                    Text(
                      'Recent Reviews:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children:
                          _reviews.take(3).map((review) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 14,
                                          color:
                                              i < review.rating
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${review.createdAt.day}/${review.createdAt.month}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review.comment,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
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
    );
  }

  // Removed unused desktop methods: _buildDesktopShopInfo, _buildDesktopServices,
  // _buildDesktopReviews, _buildDesktopActionCard, _buildDesktopInfoCard,
  // _buildDesktopContactCard, _buildDesktopHoursCard, _buildDesktopBusinessInfoCard,
  // _buildDesktopPaymentMethodsCard, _buildDesktopFeaturesCard

  Widget _buildShopInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Title
        Text(
          _shop!.name,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppConstants.darkColor,
          ),
        ),
        const SizedBox(height: 8),

        // Rating info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _shop!.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_shop!.reviewCount} reviews)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Area
        if (_shop!.area.isNotEmpty) ...[
          Text(
            _shop!.area,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
        ],

        // Description
        if (_shop!.description.isNotEmpty) ...[
          Text(
            _shop!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'address_label'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(_shop!.address, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildHours() {
    final days = [
      'day_monday'.tr(context),
      'day_tuesday'.tr(context),
      'day_wednesday'.tr(context),
      'day_thursday'.tr(context),
      'day_friday'.tr(context),
      'day_saturday'.tr(context),
      'day_sunday'.tr(context),
    ];
    final shortKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'hours_label'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: List.generate(days.length, (i) {
              final dayKey = shortKeys[i];
              final hours = _shop!.hours[dayKey];
              final isToday = _isToday(dayKey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color:
                            isToday
                                ? AppConstants.primaryColor
                                : Colors.grey[700],
                      ),
                    ),
                    Text(
                      HoursFormatter.formatHours(hours, context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color:
                            isToday
                                ? AppConstants.primaryColor
                                : (hours != null
                                    ? Colors.grey[800]
                                    : Colors.grey[500]),
                        fontStyle:
                            hours == null ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    final shop = _shop!;
    final List<InfoRow> info = [
      if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty)
        InfoRow(
          icon: Icons.phone,
          text: '${'phone_label'.tr(context)}: ${shop.phoneNumber!}',
          onTap: () => _launchUrl('tel:${shop.phoneNumber}'),
        ),
      if (shop.facebookPage != null && shop.facebookPage!.isNotEmpty)
        InfoRow(
          icon: Icons.facebook,
          text: '${'facebook_label'.tr(context)}: Facebook Page',
          onTap: () => _launchUrl(shop.facebookPage!),
        ),
      if (shop.instagramPage != null && shop.instagramPage!.isNotEmpty)
        InfoRow(
          icon: Icons.camera_alt,
          text: '${'instagram_label'.tr(context)}: Instagram',
          onTap: () => _launchUrl(shop.instagramPage!),
        ),
      if (shop.lineId != null && shop.lineId!.isNotEmpty)
        InfoRow(
          icon: Icons.chat,
          text: '${'line_label'.tr(context)}: Line: ${shop.lineId}',
          onTap: () => _launchUrl('https://line.me/ti/p/${shop.lineId}'),
        ),
      if (shop.otherContacts != null && shop.otherContacts!.isNotEmpty)
        InfoRow(
          icon: Icons.contact_phone,
          text: '${'other_contacts_label'.tr(context)}: ${shop.otherContacts!}',
          onTap: () => _launchUrl('tel:${shop.otherContacts}'),
        ),
    ];

    if (info.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'contact_label'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: info.map((item) => item).toList()),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      appLog('Error launching URL: $e');
    }
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'reviews_label'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          _buildNoReviews()
        else
          Column(
            children:
                _reviews
                    .take(3)
                    .map((review) => _buildReviewItem(review))
                    .toList(),
          ),
        if (_reviews.length > 3)
          TextButton(
            onPressed: () {
              // Show all reviews
            },
            child: Text('show_all_reviews'.tr(context)),
          ),
      ],
    );
  }

  Widget _buildNoReviews() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          'no_reviews_yet'.tr(context),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty
                          ? review.userName
                          : 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: i < review.rating ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(fontSize: 14)),
          if (review.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children:
                    review.replies.map((reply) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[400],
                              child: Text(
                                reply.userName.isNotEmpty
                                    ? reply.userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply.userName.isNotEmpty
                                        ? reply.userName
                                        : 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    reply.comment,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddReviewDialog() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_login_to_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rating = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('add_review'.tr(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('select_rating'.tr(context)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        Icons.star,
                        color: i < 3 ? Colors.amber : Colors.grey[300],
                      ),
                      onPressed: () => Navigator.pop(context, i + 1),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
            ],
          ),
    );

    if (rating == null) return;

    String? comment;
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('add_comment'.tr(context)),
            content: TextField(
              decoration: InputDecoration(
                hintText: 'enter_comment'.tr(context),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => comment = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, comment),
                child: Text('submit'.tr(context)),
              ),
            ],
          ),
    );

    comment = result;

    if (comment == null || comment!.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final review = Review(
        id: '',
        shopId: widget.shopId,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        rating: rating.toDouble(),
        comment: comment!,
        createdAt: DateTime.now(),
        replies: [],
      );

      await _reviewService.addReview(review);
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('review_added'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_adding_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('report_shop'.tr(context)),
            content: Text('report_shop_message'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ReportFormScreen(shopId: widget.shopId),
                    ),
                  );
                },
                child: Text('report'.tr(context)),
              ),
            ],
          ),
    );
  }

  bool _isToday(String dayKey) {
    final now = DateTime.now();
    final todayKey = _getTodayKey(now.weekday);
    return todayKey == dayKey;
  }

  String _getTodayKey(int weekday) {
    const shortKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return shortKeys[weekday - 1]; // weekday is 1-7, array is 0-6
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleSaved,
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              label: Text(
                _isSaved ? 'saved'.tr(context) : 'save_shop'.tr(context),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSaved ? Colors.orange : AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogRepairScreen(shop: _shop!),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'log_repair'.tr(context),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showReportDialog,
              icon: const Icon(Icons.flag, color: Colors.white),
              label: Text(
                'report'.tr(context),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed unused desktop methods: _buildDesktopShopInfo, _buildDesktopServices,
  // _buildDesktopReviews, _buildDesktopActionCard, _buildDesktopInfoCard,
  // _buildDesktopContactCard, _buildDesktopHoursCard, _buildDesktopBusinessInfoCard,
  // _buildDesktopPaymentMethodsCard, _buildDesktopFeaturesCard

  Widget _buildDesktopMapLocation() {
    return Container(
      height: 400,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_shop!.latitude, _shop!.longitude),
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId(_shop!.id),
            position: LatLng(_shop!.latitude, _shop!.longitude),
            infoWindow: InfoWindow(title: _shop!.name, snippet: _shop!.address),
          ),
        },
      ),
    );
  }
}
