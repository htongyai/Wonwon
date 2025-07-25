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
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonwonw2/widgets/info_row.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonwonw2/screens/log_repair_screen.dart';
import 'package:wonwonw2/widgets/section_title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';

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

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ScrollController _scrollController = ScrollController();
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
  Map<String, bool> _showReplyInput = {};
  Map<String, TextEditingController> _replyControllers = {};
  Map<String, bool> _expandedReplies = {};
  Map<String, bool> _userExistsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchShop();
    _checkLoginStatus();
    _loadReviews();
    _loadReports();
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
  void dispose() {
    // Clean up resources
    _scrollController.dispose();
    _replyControllers.forEach((_, c) => c.dispose());
    super.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
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
                        ? Image.network(
                          _shop!.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  AssetHelpers.getShopPlaceholder(_shop!.name),
                        )
                        : AssetHelpers.getShopPlaceholder(_shop!.name),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
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
                                          (context) =>
                                              EditShopScreen(shop: _shop!),
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
                    _buildReviews(),
                    SizedBox(
                      height: ResponsiveSize.getHeight(20),
                    ), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
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
                spacing: 8,
                runSpacing: 8,
                children:
                    _shop!.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
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
                _shop!.address,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (_shop!.buildingName != null &&
                      _shop!.buildingName!.isNotEmpty ||
                  _shop!.buildingNumber != null &&
                      _shop!.buildingNumber!.isNotEmpty ||
                  _shop!.buildingFloor != null &&
                      _shop!.buildingFloor!.isNotEmpty ||
                  _shop!.soi != null && _shop!.soi!.isNotEmpty ||
                  _shop!.district != null && _shop!.district!.isNotEmpty ||
                  _shop!.province != null && _shop!.province!.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
              if (_shop!.buildingName != null &&
                  _shop!.buildingName!.isNotEmpty)
                _buildDetailRow(
                  'building_name_label'.tr(context),
                  _shop!.buildingName!,
                ),
              if (_shop!.buildingNumber != null &&
                  _shop!.buildingNumber!.isNotEmpty)
                _buildDetailRow(
                  'building_number_label'.tr(context),
                  _shop!.buildingNumber!,
                ),
              if (_shop!.buildingFloor != null &&
                  _shop!.buildingFloor!.isNotEmpty)
                _buildDetailRow(
                  'building_floor_label'.tr(context),
                  _shop!.buildingFloor!,
                ),
              if (_shop!.soi != null && _shop!.soi!.isNotEmpty)
                _buildDetailRow('soi_label'.tr(context), _shop!.soi!),
              if (_shop!.district != null && _shop!.district!.isNotEmpty)
                _buildDetailRow('district_label'.tr(context), _shop!.district!),
              if (_shop!.province != null && _shop!.province!.isNotEmpty)
                _buildDetailRow('province_label'.tr(context), _shop!.province!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
                      hours ?? 'day_closed'.tr(context),
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
    _replyControllers.putIfAbsent(review.id, () => TextEditingController());
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
                      color: Colors.amber,
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

  bool _isToday(String day) {
    final now = DateTime.now();
    final dayOfWeek = _getDayName(now.weekday);
    return dayOfWeek == day;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'day_monday'.tr(context);
      case 2:
        return 'day_tuesday'.tr(context);
      case 3:
        return 'day_wednesday'.tr(context);
      case 4:
        return 'day_thursday'.tr(context);
      case 5:
        return 'day_friday'.tr(context);
      case 6:
        return 'day_saturday'.tr(context);
      case 7:
        return 'day_sunday'.tr(context);
      default:
        return '';
    }
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
                      color: Colors.amber,
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
