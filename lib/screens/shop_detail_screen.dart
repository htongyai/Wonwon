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
import 'package:wonwonw2/services/content_management_service.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
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
  final ContentManagementService _contentService = ContentManagementService();

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
  Map<String, bool> _showReplyInput = {};
  Map<String, TextEditingController> _replyControllers = {};
  Map<String, bool> _expandedReplies = {};
  Map<String, bool> _userExistsCache = {};
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
      // Cache for session
      _userExistsCache = existsMap;
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

  /// Open maps with directions to the shop
  Future<void> _openMapsWithDirections() async {
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('opening_maps'.tr(context)),
        duration: const Duration(seconds: 1),
      ),
    );

    // Get the shop's coordinates
    final double latitude = _shop!.latitude;
    final double longitude = _shop!.longitude;

    // Create Google Maps URL with directions
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    // Create Apple Maps URL for iOS devices
    final Uri appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
    );

    try {
      // Try to launch Google Maps first
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
      // If Google Maps can't be launched, try Apple Maps
      else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
      // If neither can be launched, show error message
      else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('could_not_open_directions'.tr(context)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('could_not_open_directions'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
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
                _buildBusinessInfo(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildPaymentMethods(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildFeatures(),
                SizedBox(height: ResponsiveSize.getHeight(6)),
                _buildMapLocation(),
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
        _buildInfoItem(
          'Price Range',
          _shop!.priceRange?.toString() ?? 'No information',
        ),
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


  // Removed unused method _buildDesktopHeader
    return Container(
      height: 400, // Increased height for better visual impact
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child:
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
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          // Admin Actions
          if (_isAdmin)
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppConstants.primaryColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditShopScreen(shop: _shop!),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          // Shop Title and Info - Redesigned for better balance
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side - Shop name and basic info
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _shop!.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        if (_shop!.description.isNotEmpty)
                          Text(
                            _shop!.description,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 16),
                        // Rating and location
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _shop!.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '(${_shop!.reviewCount} reviews)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right side - Location and quick info
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _shop!.area,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _shop!.approved
                                    ? AppConstants.primaryColor.withOpacity(0.9)
                                    : Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _shop!.approved ? 'Verified' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
        const SizedBox(height: 16),

        // Services
        Row(
          children: [
            Icon(Icons.build_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'services'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main categories
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    _shop!.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'category_$category'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              if (_shop!.subServices.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'available_subservices_label'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                // Sub-services grouped by category
                ..._shop!.subServices.entries.map((entry) {
                  final categoryId = entry.key;
                  final subServiceIds = entry.value;
                  if (subServiceIds.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'category_$categoryId'.tr(context),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            subServiceIds.map((subServiceId) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  'subservice_${categoryId}_$subServiceId'.tr(
                                    context,
                                  ),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Methods
        if (_shop!.paymentMethods != null &&
            _shop!.paymentMethods!.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.payment_outlined, color: Colors.brown),
              SizedBox(width: ResponsiveSize.getWidth(2)),
              Text(
                'payment_methods'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          Container(
            width: double.infinity,
            padding: ResponsiveSize.getScaledPadding(const EdgeInsets.all(16)),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _shop!.paymentMethods!.map((method) {
                    IconData icon;
                    Color color;

                    switch (method.toLowerCase()) {
                      case 'cash':
                        icon = Icons.money;
                        color = Colors.green;
                        break;
                      case 'credit_card':
                        icon = Icons.credit_card;
                        color = Colors.blue;
                        break;
                      case 'debit_card':
                        icon = Icons.credit_card;
                        color = Colors.blue;
                        break;
                      case 'promptpay':
                        icon = Icons.qr_code;
                        color = Colors.purple;
                        break;
                      case 'true_money':
                        icon = Icons.account_balance_wallet;
                        color = Colors.orange;
                        break;
                      case 'line_pay':
                        icon = Icons.chat;
                        color = Colors.green;
                        break;
                      default:
                        icon = Icons.payment;
                        color = Colors.grey;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 4),
                          Text(
                            'payment_${_normalizePaymentMethod(method)}'.tr(
                              context,
                            ),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Description
        Row(
          children: [
            Icon(Icons.description_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'description'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            _shop!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
        _buildAdditionalInfo(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shop!.address.isNotEmpty ? _shop!.address : 'No information',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                      _shop!.address.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[400],
                  fontStyle:
                      _shop!.address.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              _buildMobileInfoRow('Building Number', _shop!.buildingNumber),
              _buildMobileInfoRow('Building Name', _shop!.buildingName),
              _buildMobileInfoRow('Floor', _shop!.buildingFloor),
              _buildMobileInfoRow('Soi', _shop!.soi),
              _buildMobileInfoRow('District', _shop!.district),
              _buildMobileInfoRow('Province', _shop!.province),
              _buildMobileInfoRow(
                'Area',
                _shop!.area.isNotEmpty ? _shop!.area : null,
              ),
              _buildMobileInfoRow('Landmark', _shop!.landmark),
              if (_shop!.latitude != 0.0 && _shop!.longitude != 0.0)
                _buildMobileInfoRow(
                  'Coordinates',
                  '${_shop!.latitude.toStringAsFixed(6)}, ${_shop!.longitude.toStringAsFixed(6)}',
                ),
            ],
          ),
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
              'hours'.tr(context),
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
          child: Column(
            children: List.generate(days.length, (i) {
              final hours = _shop!.hours[shortKeys[i]];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      HoursFormatter.formatHours(hours, context),
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            hours != null ? Colors.grey[800] : Colors.grey[500],
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
      // Phone Number
      InfoRow(
        icon: Icons.phone,
        text:
            shop.phoneNumber?.isNotEmpty == true
                ? shop.phoneNumber!
                : 'no_information'.tr(context),
        onTap:
            shop.phoneNumber?.isNotEmpty == true
                ? () => _launchUrl('tel:${shop.phoneNumber}')
                : null,
      ),
      // Line ID
      InfoRow(
        icon: FontAwesomeIcons.line,
        text:
            shop.lineId?.isNotEmpty == true
                ? shop.lineId!
                : 'no_information'.tr(context),
        onTap:
            shop.lineId?.isNotEmpty == true
                ? () => _launchUrl('https://line.me/ti/p/~${shop.lineId}')
                : null,
      ),
      // Facebook
      InfoRow(
        icon: FontAwesomeIcons.facebook,
        text:
            shop.facebookPage?.isNotEmpty == true
                ? shop.facebookPage!
                : 'no_information'.tr(context),
        onTap:
            shop.facebookPage?.isNotEmpty == true
                ? () => _launchUrl(shop.facebookPage!)
                : null,
      ),
      // Instagram
      InfoRow(
        icon: FontAwesomeIcons.instagram,
        text:
            shop.instagramPage?.isNotEmpty == true
                ? shop.instagramPage!
                : 'no_information'.tr(context),
        onTap:
            shop.instagramPage?.isNotEmpty == true
                ? () => _launchUrl(shop.instagramPage!)
                : null,
      ),
      // Other Contacts
      InfoRow(
        icon: Icons.contact_mail,
        text:
            shop.otherContacts?.isNotEmpty == true
                ? shop.otherContacts!
                : 'no_information'.tr(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'contact_information'.tr(context),
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
          child: Column(
            children:
                info
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: row,
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rate_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'reviews'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingReviews
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
            ? _buildNoReviews()
            : Column(
              children:
                  _reviews.map((review) => _buildReviewItem(review)).toList(),
            ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddReviewDialog,
          icon: const Icon(Icons.rate_review),
          label: Text('write_review'.tr(context)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoReviews() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'no_reviews'.tr(context),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'be_first_review'.tr(context),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final formattedDate =
        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}';
    _replyControllers.putIfAbsent(review.id, () => createTextController());
    _showReplyInput.putIfAbsent(review.id, () => false);
    _expandedReplies.putIfAbsent(review.id, () => false);
    // Use cache to determine display name
    String displayName =
        (_userExistsCache[review.userId] == false || review.isAnonymous)
            ? 'Anonymous'
            : review.userName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    review.isAnonymous ||
                            (_userExistsCache[review.userId] == false)
                        ? Colors.grey[400]
                        : AppConstants.primaryColor.withOpacity(0.2),
                radius: 16,
                child: Text(
                  (review.isAnonymous ||
                          (_userExistsCache[review.userId] == false))
                      ? 'A'
                      : review.userName
                          .split(' ')
                          .map((e) => e.isEmpty ? '' : e[0])
                          .join('')
                          .toUpperCase(),
                  style: TextStyle(
                    color:
                        review.isAnonymous ||
                                (_userExistsCache[review.userId] == false)
                            ? Colors.white
                            : AppConstants.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color:
                          index < review.rating
                              ? Colors.amber
                              : Colors.grey[400],
                      size: 16,
                    ),
                  ),
                  // Add spacing between stars and show replies button
                  if (review.replies.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedReplies[review.id] =
                              !_expandedReplies[review.id]!;
                        });
                      },
                      child: Text(
                        _expandedReplies[review.id] == true
                            ? 'Hide replies'
                            : 'Show replies',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  // Delete button for review (only visible to author or admin/moderator)
                  FutureBuilder<bool>(
                    future: _contentService.canDeleteContent(review.userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return Row(
                          children: [
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _deleteReview(review),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 16,
                              ),
                              tooltip: 'Delete review',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment),
          const SizedBox(height: 8),
          // Replies (expandable)
          if (review.replies.isNotEmpty && _expandedReplies[review.id] == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  review.replies.map((reply) {
                    final replyDate =
                        '${reply.createdAt.day}/${reply.createdAt.month}/${reply.createdAt.year}';
                    // Use cache to determine reply display name
                    String replyDisplayName =
                        (_userExistsCache[reply.userId] == false)
                            ? 'Anonymous'
                            : reply.userName;
                    return Container(
                      margin: const EdgeInsets.only(top: 8, left: 24),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                (_userExistsCache[reply.userId] == false)
                                    ? Colors.grey[400]
                                    : AppConstants.primaryColor.withOpacity(
                                      0.15,
                                    ),
                            radius: 12,
                            child: Text(
                              (_userExistsCache[reply.userId] == false)
                                  ? 'A'
                                  : (reply.userName.isNotEmpty
                                      ? reply.userName[0].toUpperCase()
                                      : '?'),
                              style: TextStyle(
                                color:
                                    (_userExistsCache[reply.userId] == false)
                                        ? Colors.white
                                        : AppConstants.primaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyDisplayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  replyDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reply.comment,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          // Reply button and input
          const SizedBox(height: 8),
          if (_showReplyInput[review.id] == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _replyControllers[review.id],
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _submitReply(review),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Reply'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showReplyInput[review.id] = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _showReplyInput[review.id] = true;
                });
              },
              child: const Text('Reply'),
            ),
        ],
      ),
    );
  }

  void _submitReply(Review review) async {
    final replyText = _replyControllers[review.id]?.text.trim() ?? '';
    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reply.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Get user info
    String userId = await _authService.getUserId() ?? 'unknown';
    String userName = await _authService.getUserName() ?? 'User';
    final reply = ReviewReply(
      id:
          DateTime.now().millisecondsSinceEpoch
              .toString(), // Generate unique ID
      userId: userId,
      userName: userName,
      comment: replyText,
      createdAt: DateTime.now(),
    );
    try {
      await _reviewService.addReplyToReview(
        shopId: widget.shopId,
        reviewId: review.id,
        reply: reply,
      );
      _replyControllers[review.id]?.clear();
      setState(() {
        _showReplyInput[review.id] = false;
      });
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddReviewDialog() async {
    // If not logged in, prompt to login first
    if (!_isLoggedIn) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('login_required'.tr(context)),
              content: Text('login_to_review'.tr(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  child: Text('cancel'.tr(context)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: Text('login'.tr(context)),
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        _isLoggedIn = true;
                      });
                      // Now show the review dialog since user is logged in
                      _showAddReviewDialog();
                    }
                  },
                ),
              ],
            ),
      );
      return;
    }

    // Get the actual user's full name
    String userName = await _authService.getUserName() ?? 'User';

    // User is logged in, show review dialog
    showDialog(
      context: context,
      builder:
          (context) => _ReviewDialog(
            onSubmit: (rating, comment, isAnonymous) {
              if (comment.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('please_write_review_comment'.tr(context)),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newReview = Review(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                shopId: widget.shopId,
                userId: 'current-user',
                userName: userName,
                comment: comment,
                rating: rating,
                createdAt: DateTime.now(),
                isAnonymous: isAnonymous,
              );

              _reviewService.addReview(newReview).then((_) {
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('thank_you_review'.tr(context)),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
          ),
    );
  }

  void _showReportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReportFormScreen(
              shopId: widget.shopId,
              onReportSubmitted: () {
                _loadReports();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('thank_you_report'.tr(context)),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
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

  Widget _buildAdditionalInfo() {
    final shop = _shop!;
    List<Widget> info = [];
    if (shop.timestamp != null) {
      info.add(
        InfoRow(
          icon: Icons.access_time,
          text:
              'added_label'.tr(context) +
              ': ' +
              shop.timestamp!.toLocal().toString(),
        ),
      );
    }
    if ((shop.buildingNumber != null && shop.buildingNumber!.isNotEmpty) ||
        (shop.buildingName != null && shop.buildingName!.isNotEmpty)) {
      info.add(
        InfoRow(
          icon: Icons.location_city,
          text:
              'building_label'.tr(context) +
              ': ' +
              [
                shop.buildingNumber,
                shop.buildingName,
              ].where((e) => e != null && e.isNotEmpty).join(' '),
        ),
      );
    }
    if (shop.buildingFloor != null && shop.buildingFloor!.isNotEmpty)
      info.add(
        InfoRow(
          icon: Icons.location_city,
          text: 'building_floor_label'.tr(context) + ': ' + shop.buildingFloor!,
        ),
      );
    if (shop.soi != null && shop.soi!.isNotEmpty)
      info.add(
        InfoRow(
          icon: Icons.alt_route,
          text: 'soi_label'.tr(context) + ': ' + shop.soi!,
        ),
      );
    if (shop.district != null && shop.district!.isNotEmpty)
      info.add(
        InfoRow(
          icon: Icons.map,
          text: 'district_label'.tr(context) + ': ' + shop.district!,
        ),
      );
    if (shop.province != null && shop.province!.isNotEmpty)
      info.add(
        InfoRow(
          icon: Icons.location_city,
          text: 'province_label'.tr(context) + ': ' + shop.province!,
        ),
      );
    if (shop.landmark != null && shop.landmark!.isNotEmpty) {
      info.add(
        InfoRow(
          icon: Icons.place,
          text: 'landmark_label'.tr(context) + ': ' + shop.landmark!,
        ),
      );
    }
    if (shop.notesOrConditions != null && shop.notesOrConditions!.isNotEmpty) {
      info.add(
        InfoRow(
          icon: Icons.info_outline,
          text: 'notes_label'.tr(context) + ': ' + shop.notesOrConditions!,
        ),
      );
    }
    if (shop.tryOnAreaAvailable == true)
      info.add(
        InfoRow(
          icon: Icons.check_circle_outline,
          text:
              'try_on_area_available'.tr(context) +
              ': ' +
              'yes_label'.tr(context),
        ),
      );
    if (shop.paymentMethods != null && shop.paymentMethods!.isNotEmpty) {
      info.add(
        InfoRow(
          icon: Icons.payment,
          text:
              'payment_methods_label'.tr(context) +
              ': ' +
              shop.paymentMethods!.join(', '),
        ),
      );
    }
    if (shop.instagramPage != null && shop.instagramPage!.isNotEmpty)
      info.add(
        InfoRow(icon: FontAwesomeIcons.instagram, text: shop.instagramPage!),
      );
    return info.isNotEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'additional_info_label'.tr(context),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...info,
          ],
        )
        : SizedBox.shrink();
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      ),
      child: Row(
        children: [
          // Get Directions button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openMapsWithDirections,
              icon: const Icon(Icons.directions, color: Colors.white),
              label: Text(
                'directions'.tr(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: ResponsiveSize.getScaledPadding(
                  const EdgeInsets.symmetric(vertical: 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(3)),
          // Save location button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleSaved,
              icon:
                  _isLoadingSavedState
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                      ),
              label: Text(
                _isSaved ? 'saved'.tr(context) : 'save'.tr(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSaved ? Colors.orange[700] : AppConstants.primaryColor,
                padding: ResponsiveSize.getScaledPadding(
                  const EdgeInsets.symmetric(vertical: 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(3)),
          // Log Repair button
          ElevatedButton.icon(
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
              'log'.tr(context),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
              padding: ResponsiveSize.getScaledPadding(
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this function to normalize payment method keys
  String _normalizePaymentMethod(String method) {
    final m = method.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    if (m.contains('cash')) return 'cash';
    if (m.contains('creditcard') ||
        m.contains('debitcard') ||
        m.contains('card'))
      return 'card';
    if (m.contains('qr') || m.contains('promptpay')) return 'qr';
    if (m.contains('banktransfer')) return 'bank_transfer';
    if (m.contains('truemoney')) return 'true_money';
    if (m.contains('linepay')) return 'line_pay';
    return m;
  }

  // Delete review method
  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Delete Review',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final success = await _reviewService.deleteReview(
          widget.shopId,
          review.id,
          review.userId,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Review deleted successfully!',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          // Reload reviews
          _loadReviews();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'You do not have permission to delete this review.',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Error deleting review: $e',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Desktop-specific widget methods
  Widget _buildDesktopShopInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'about_shop'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _shop!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopServices() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'services'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _shop!.categories.map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      category.tr(context),
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopReviews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'reviews'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
              const Spacer(),
              Text(
                '${_reviews.length} reviews',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_reviews_yet'.tr(context),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length > 3 ? 3 : _reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _buildDesktopReviewItem(review);
              },
            ),
          if (_reviews.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Show all reviews dialog or navigate to reviews page
                  },
                  child: Text('view_all_reviews'.tr(context)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopReviewItem(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
              child: Text(
                review.userName.isNotEmpty
                    ? review.userName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: AppConstants.primaryColor,
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
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.4)),
      ],
    );
  }

  Widget _buildDesktopActionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _openMapsWithDirections,
            icon: const Icon(Icons.directions),
            label: Text('get_directions'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _toggleSaved,
            icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
            label: Text(
              _isSaved ? 'saved'.tr(context) : 'save_shop'.tr(context),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  _isSaved ? Colors.red : AppConstants.primaryColor,
              side: BorderSide(
                color: _isSaved ? Colors.red : AppConstants.primaryColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showReportDialog,
            icon: const Icon(Icons.report_problem_outlined),
            label: Text('report_issue'.tr(context)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'location'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _shop!.address.isNotEmpty ? _shop!.address : 'No information',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Building Number', _shop!.buildingNumber),
          _buildInfoRow('Building Name', _shop!.buildingName),
          _buildInfoRow('Floor', _shop!.buildingFloor),
          _buildInfoRow('Soi', _shop!.soi),
          _buildInfoRow('District', _shop!.district),
          _buildInfoRow('Province', _shop!.province),
          _buildInfoRow('Area', _shop!.area.isNotEmpty ? _shop!.area : null),
          _buildInfoRow('Landmark', _shop!.landmark),
          if (_shop!.latitude != 0.0 && _shop!.longitude != 0.0)
            _buildInfoRow(
              'Coordinates',
              '${_shop!.latitude.toStringAsFixed(6)}, ${_shop!.longitude.toStringAsFixed(6)}',
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_phone_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'contact_info'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDesktopContactItem(
            Icons.phone,
            'Phone',
            _shop!.phoneNumber?.isNotEmpty == true
                ? _shop!.phoneNumber!
                : 'No information',
            _shop!.phoneNumber?.isNotEmpty == true
                ? () => _launchUrl('tel:${_shop!.phoneNumber}')
                : null,
          ),
          _buildDesktopContactItem(
            Icons.chat,
            'LINE ID',
            _shop!.lineId?.isNotEmpty == true
                ? _shop!.lineId!
                : 'No information',
            null,
          ),
          _buildDesktopContactItem(
            Icons.facebook,
            'Facebook',
            _shop!.facebookPage?.isNotEmpty == true
                ? 'Visit Page'
                : 'No information',
            _shop!.facebookPage?.isNotEmpty == true
                ? () => _launchUrl(_shop!.facebookPage!)
                : null,
          ),
          _buildDesktopContactItem(
            Icons.camera_alt,
            'Instagram',
            _shop!.instagramPage?.isNotEmpty == true
                ? 'Visit Page'
                : 'No information',
            _shop!.instagramPage?.isNotEmpty == true
                ? () => _launchUrl(_shop!.instagramPage!)
                : null,
          ),
          _buildDesktopContactItem(
            Icons.contact_mail,
            'Other Contacts',
            _shop!.otherContacts?.isNotEmpty == true
                ? _shop!.otherContacts!
                : 'No information',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          onTap != null
                              ? AppConstants.primaryColor
                              : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const Spacer(),
                Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHoursCard() {
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'opening_hours'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            days.length,
            (index) => _buildDesktopHourItem(days[index], shortKeys[index]),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopHourItem(String dayName, String dayKey) {
    final hours = _shop!.hours[dayKey];
    final isToday = _isToday(dayKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppConstants.primaryColor : Colors.black87,
              ),
            ),
          ),
          Text(
            HoursFormatter.formatHours(hours, context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppConstants.primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build mobile info rows with consistent styling
  Widget _buildMobileInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'No information',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows with consistent styling
  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'No information',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Business Information Card
  Widget _buildDesktopBusinessInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Business Information',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Price Range',
            _shop!.priceRange.isNotEmpty ? _shop!.priceRange : null,
          ),
          _buildInfoRow(
            'Duration (minutes)',
            _shop!.durationMinutes > 0 ? '${_shop!.durationMinutes}' : null,
          ),
          _buildInfoRow(
            'Requires Purchase',
            _shop!.requiresPurchase ? 'Yes' : 'No',
          ),
          _buildInfoRow(
            'Try-on Area Available',
            _shop!.tryOnAreaAvailable == true
                ? 'Yes'
                : (_shop!.tryOnAreaAvailable == false ? 'No' : null),
          ),
          _buildInfoRow(
            'Irregular Hours',
            _shop!.irregularHours ? 'Yes' : 'No',
          ),
          _buildInfoRow('Approved', _shop!.approved ? 'Yes' : 'No'),
          if (_shop!.notesOrConditions?.isNotEmpty == true)
            _buildInfoRow('Notes/Conditions', _shop!.notesOrConditions),
          if (_shop!.amenities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Amenities:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _shop!.amenities
                      .map(
                        (amenity) => Chip(
                          label: Text(amenity),
                          backgroundColor: AppConstants.primaryColor
                              .withOpacity(0.1),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ] else ...[
            _buildInfoRow('Amenities', null),
          ],
        ],
      ),
    );
  }

  // Payment Methods Card
  Widget _buildDesktopPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Methods',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_shop!.paymentMethods?.isNotEmpty == true) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _shop!.paymentMethods!.map((method) {
                    IconData icon;
                    String label;
                    switch (method.toLowerCase()) {
                      case 'cash':
                        icon = Icons.money;
                        label = 'Cash';
                        break;
                      case 'card':
                        icon = Icons.credit_card;
                        label = 'Card';
                        break;
                      case 'qr':
                        icon = Icons.qr_code;
                        label = 'QR Code';
                        break;
                      case 'bank_transfer':
                        icon = Icons.account_balance;
                        label = 'Bank Transfer';
                        break;
                      case 'true_money':
                        icon = Icons.wallet;
                        label = 'TrueMoney';
                        break;
                      case 'line_pay':
                        icon = Icons.payment;
                        label = 'LINE Pay';
                        break;
                      default:
                        icon = Icons.payment;
                        label = method;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ] else ...[
            Text(
              'No information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Features Card
  Widget _buildDesktopFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Features',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_shop!.features.isNotEmpty) ...[
            ..._shop!.features.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          fontSize: 14,
                          color: Colors.black87,
                          decoration:
                              entry.value ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            Text(
              'No information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Mobile Business Information Section
  Widget _buildBusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business_outlined, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Business Information',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileInfoRow(
                'Price Range',
                _shop!.priceRange.isNotEmpty ? _shop!.priceRange : null,
              ),
              _buildMobileInfoRow(
                'Duration (minutes)',
                _shop!.durationMinutes > 0 ? '${_shop!.durationMinutes}' : null,
              ),
              _buildMobileInfoRow(
                'Requires Purchase',
                _shop!.requiresPurchase ? 'Yes' : 'No',
              ),
              _buildMobileInfoRow(
                'Try-on Area Available',
                _shop!.tryOnAreaAvailable == true
                    ? 'Yes'
                    : (_shop!.tryOnAreaAvailable == false ? 'No' : null),
              ),
              _buildMobileInfoRow(
                'Irregular Hours',
                _shop!.irregularHours ? 'Yes' : 'No',
              ),
              _buildMobileInfoRow('Approved', _shop!.approved ? 'Yes' : 'No'),
              if (_shop!.notesOrConditions?.isNotEmpty == true)
                _buildMobileInfoRow(
                  'Notes/Conditions',
                  _shop!.notesOrConditions,
                ),
              if (_shop!.amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Amenities:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      _shop!.amenities
                          .map(
                            (amenity) => Chip(
                              label: Text(amenity),
                              backgroundColor: AppConstants.primaryColor
                                  .withOpacity(0.1),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ] else ...[
                _buildMobileInfoRow('Amenities', null),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Mobile Payment Methods Section
  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment_outlined, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Payment Methods',
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
          child:
              _shop!.paymentMethods?.isNotEmpty == true
                  ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        _shop!.paymentMethods!.map((method) {
                          IconData icon;
                          String label;
                          switch (method.toLowerCase()) {
                            case 'cash':
                              icon = Icons.money;
                              label = 'Cash';
                              break;
                            case 'card':
                              icon = Icons.credit_card;
                              label = 'Card';
                              break;
                            case 'qr':
                              icon = Icons.qr_code;
                              label = 'QR Code';
                              break;
                            case 'bank_transfer':
                              icon = Icons.account_balance;
                              label = 'Bank Transfer';
                              break;
                            case 'true_money':
                              icon = Icons.wallet;
                              label = 'TrueMoney';
                              break;
                            case 'line_pay':
                              icon = Icons.payment;
                              label = 'LINE Pay';
                              break;
                            default:
                              icon = Icons.payment;
                              label = method;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 14,
                                  color: AppConstants.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  )
                  : Text(
                    'No information',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
        ),
      ],
    );
  }

  // Mobile Features Section
  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Features',
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
          child:
              _shop!.features.isNotEmpty
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _shop!.features.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color:
                                      entry.value ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      decoration:
                                          entry.value
                                              ? null
                                              : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  )
                  : Text(
                    'No information',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _centerMapOnShop() {
    if (_mapController != null && _shop != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_shop!.latitude, _shop!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    }
  }

  Widget _buildMapLocation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(
                'location'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                // Google Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      _shop != null
                          ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_shop!.latitude, _shop!.longitude),
                              zoom: 16.0,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(_shop!.id),
                                position: LatLng(
                                  _shop!.latitude,
                                  _shop!.longitude,
                                ),
                                infoWindow: InfoWindow(
                                  title: _shop!.name,
                                  snippet: _shop!.address,
                                ),
                              ),
                            },
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                            compassEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                          )
                          : Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Loading map...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
                // Center Map button
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _centerMapOnShop,
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryColor,
                    child: const Icon(Icons.my_location, size: 16),
                  ),
                ),
                // Get Directions button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ElevatedButton.icon(
                    onPressed: () => _openMapsWithDirections(),
                    icon: const Icon(Icons.directions, size: 16),
                    label: Text('directions'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
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

  Widget _buildDesktopMapLocation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red[600],
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'location'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  // Google Map
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _shop != null
                            ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _shop!.latitude,
                                  _shop!.longitude,
                                ),
                                zoom: 16.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(_shop!.id),
                                  position: LatLng(
                                    _shop!.latitude,
                                    _shop!.longitude,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: _shop!.name,
                                    snippet: _shop!.address,
                                  ),
                                ),
                              },
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                              },
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: true,
                              compassEnabled: true,
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                            )
                            : Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      size: isSmallScreen ? 48 : 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading Interactive Map...',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey[600],
                                        fontSize: isSmallScreen ? 16 : 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                  ),
                  // Address overlay
                  if (_shop != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: isSmallScreen ? 60 : 80,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _shop!.name,
                              style: GoogleFonts.montserrat(
                                color: AppConstants.darkColor,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _shop!.address,
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Center Map button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _centerMapOnShop,
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      child: const Icon(Icons.my_location, size: 20),
                    ),
                  ),
                  // Get Directions button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMapsWithDirections(),
                      icon: const Icon(Icons.directions, size: 20),
                      label: Text('get_directions'.tr(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
}

class _ReportDialog extends StatefulWidget {
  final Function(String reason, String correctInfo, String additionalDetails)
  onSubmit;
  final List<String> reasonOptions;

  const _ReportDialog({required this.onSubmit, required this.reasonOptions});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _selectedReason = '';
  String _correctInfo = '';
  String _details = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text('report_incorrect'.tr(context)),
      insetPadding: ResponsiveSize.getScaledPadding(
        EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 24.0),
      ),
      content: Container(
        width: screenWidth * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'whats_incorrect'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveSize.getHeight(2)),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    widget.reasonOptions
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value ?? '';
                  });
                },
                hint: Text('report_select_reason'.tr(context)),
              ),
              const SizedBox(height: 16),
              Text(
                'report_correct_info'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'report_correct_info_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _correctInfo = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'report_additional_details'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'report_details_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _details = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr(context)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text('submit'.tr(context)),
          onPressed: () {
            widget.onSubmit(_selectedReason, _correctInfo, _details);
          },
        ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final Function(double rating, String comment, bool isAnonymous) onSubmit;

  const _ReviewDialog({required this.onSubmit});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  double _rating = 5.0;
  String _comment = '';
  bool _isAnonymous = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text('write_review'.tr(context)),
      insetPadding: ResponsiveSize.getScaledPadding(
        EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 24.0),
      ),
      content: Container(
        width: screenWidth * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'rating'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey[400],
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'your_review'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'review_comment_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _comment = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? false;
                      });
                    },
                  ),
                  Text('post_anonymous'.tr(context)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr(context)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_rating, _comment, _isAnonymous);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text('submit'.tr(context)),
        ),
      ],
    );
  }
}
