import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/review.dart';
import 'package:wonwonw2/screens/login_screen.dart';
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

/// Screen that displays detailed information about a repair shop
/// Shows shop information, hours, contact details, services, and reviews
class ShopDetailScreen extends StatefulWidget {
  // The repair shop to display details for
  final RepairShop shop;

  // Optional parameter for pre-selected service category
  final String? selectedCategory;

  const ShopDetailScreen({Key? key, required this.shop, this.selectedCategory})
    : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  // Controller for the scrollable content
  final ScrollController _scrollController = ScrollController();

  // Services for data operations
  final ReviewService _reviewService = ReviewService();
  final ReportService _reportService = ReportService();
  final SavedShopService _savedShopService = SavedShopService();
  final AuthService _authService = AuthService();

  // State variables for shop data
  List<Review> _reviews = [];
  List<ShopReport> _reports = [];
  bool _isLoadingReviews = true;
  bool _isLoadingReports = true;
  bool _isSaved = false;
  bool _isLoadingSavedState = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Load all necessary data when screen initializes
    _checkLoginStatus();
    _loadReviews();
    _loadReports();
  }

  /// Check if user is logged in and update UI accordingly
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      // If logged in, check if this shop is saved
      if (isLoggedIn) {
        _checkIfSaved();
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
      final isSaved = await _savedShopService.isShopSaved(widget.shop.id);
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
        success = await _savedShopService.removeShop(widget.shop.id);
        if (success && mounted) {
          setState(() {
            _isSaved = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from saved locations'),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      } else {
        // Add shop to saved locations
        success = await _savedShopService.saveShop(widget.shop.id);
        if (success && mounted) {
          setState(() {
            _isSaved = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to your locations'),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update saved location'),
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
      final reviews = await _reviewService.getReviewsForShop(widget.shop.id);
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
      final reports = await _reportService.getReportsByShopId(widget.shop.id);
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
  void dispose() {
    // Clean up resources
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top header with image and back button
            _buildHeader(),

            // Main content
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildShopInfo(),
                  const SizedBox(height: 16),
                  _buildAddress(),
                  const SizedBox(height: 24),
                  _buildHours(),
                  const SizedBox(height: 24),
                  _buildContact(),
                  const SizedBox(height: 24),
                  _buildServices(),
                  const SizedBox(height: 24),
                  _buildReviews(),
                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar with action buttons
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            // Get Directions button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening maps...')),
                  );
                },
                icon: const Icon(Icons.directions, color: Colors.white),
                label: Text(
                  'directions'.tr(context),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save location button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleSaved,
                icon:
                    _isLoadingSavedState
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                label: Text(
                  _isSaved ? 'saved'.tr(context) : 'save'.tr(context),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaved ? Colors.orange[700] : AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header section with shop image and name
  Widget _buildHeader() {
    return Stack(
      children: [
        // Shop image or placeholder
        Container(
          height: 200,
          width: double.infinity,
          child:
              widget.shop.photos.isNotEmpty
                  ? Image.network(
                    widget.shop.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                            AssetHelpers.getShopPlaceholder(widget.shop.name),
                  )
                  : AssetHelpers.getShopPlaceholder(widget.shop.name),
        ),

        // Shop name overlay with gradient background
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            child: Text(
              widget.shop.name,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 8,
          left: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        // Report button with counter for existing reports
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            radius: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _showReportDialog,
                ),
                // Show count badge if there are existing reports
                if (!_isLoadingReports && _reports.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
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
                          _reports.length > 9 ? '9+' : '${_reports.length}',
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
          ),
        ),
      ],
    );
  }

  Widget _buildShopInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    widget.shop.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${widget.shop.reviewCount} reviews)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
            widget.shop.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
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
              'address'.tr(context),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.shop.address, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                widget.shop.area,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.brown),
            const SizedBox(width: 8),
            Text(
              'opening_hours'.tr(context),
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
            children: [
              _buildHourRow(
                'day_monday'.tr(context),
                '9:00 AM - 6:00 PM',
                _isToday('Monday'),
              ),
              _buildHourRow(
                'day_tuesday'.tr(context),
                '9:00 AM - 6:00 PM',
                _isToday('Tuesday'),
              ),
              _buildHourRow(
                'day_wednesday'.tr(context),
                '9:00 AM - 6:00 PM',
                _isToday('Wednesday'),
              ),
              _buildHourRow(
                'day_thursday'.tr(context),
                '9:00 AM - 6:00 PM',
                _isToday('Thursday'),
              ),
              _buildHourRow(
                'day_friday'.tr(context),
                '9:00 AM - 6:00 PM',
                _isToday('Friday'),
              ),
              _buildHourRow(
                'day_saturday'.tr(context),
                '10:00 AM - 4:00 PM',
                _isToday('Saturday'),
              ),
              _buildHourRow(
                'day_sunday'.tr(context),
                'day_closed'.tr(context),
                _isToday('Sunday'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContact() {
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
            children: [
              _buildContactItem(Icons.phone, '+66 80 123 4567', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling shop...')),
                );
              }),
              const Divider(height: 16),
              _buildContactItem(FontAwesomeIcons.line, '@wonwonrepair', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Line...')),
                );
              }),
              const Divider(height: 16),
              _buildContactItem(Icons.language, 'www.wonwonrepair.com', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening website...')),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.shop.categories.map((category) {
                final bool isSelected =
                    widget.selectedCategory != null &&
                    widget.selectedCategory!.toLowerCase() ==
                        category.toLowerCase();

                return InkWell(
                  onTap: () {
                    if (category.toLowerCase() == "all") {
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context, {'filterCategory': category});
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    backgroundColor:
                        isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.primaryColor.withOpacity(0.1),
                    label: Text(
                      category,
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
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

  Widget _buildHourRow(String day, String hours, bool isToday) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppConstants.primaryColor : Colors.black87,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppConstants.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.brown),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
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
            const Text(
              'No reviews yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this shop',
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
            children: [
              CircleAvatar(
                backgroundColor:
                    review.isAnonymous
                        ? Colors.grey[400]
                        : AppConstants.primaryColor.withOpacity(0.2),
                radius: 16,
                child: Text(
                  review.isAnonymous
                      ? 'A'
                      : review.userName
                          .split(' ')
                          .map((e) => e.isEmpty ? '' : e[0])
                          .join('')
                          .toUpperCase(),
                  style: TextStyle(
                    color:
                        review.isAnonymous
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
                      review.getDisplayName(),
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
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    // If not logged in, prompt to login first
    if (!_isLoggedIn) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Login Required'),
              content: const Text(
                'You need to be logged in to write a review.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: const Text('Login'),
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

    // User is logged in, show review dialog
    showDialog(
      context: context,
      builder:
          (context) => _ReviewDialog(
            onSubmit: (rating, comment, isAnonymous) {
              if (comment.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please write a review comment'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newReview = Review(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                shopId: widget.shop.id,
                userId: 'current-user',
                userName: 'Current User',
                comment: comment,
                rating: rating,
                createdAt: DateTime.now(),
                isAnonymous: isAnonymous,
              );

              _reviewService.addReview(newReview).then((_) {
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your review!'),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
          ),
    );
  }

  void _showReportDialog() {
    // Remove login check and directly show report dialog
    final reasonOptions = [
      'report_reason_address'.tr(context),
      'report_reason_hours'.tr(context),
      'report_reason_closed'.tr(context),
      'report_reason_contact'.tr(context),
      'report_reason_services'.tr(context),
      'report_reason_nonexistent'.tr(context),
      'report_reason_other'.tr(context),
    ];

    showDialog(
      context: context,
      builder:
          (context) => _ReportDialog(
            onSubmit: (reason, details) {
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('report_reason_required'.tr(context)),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final report = ShopReport(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                shopId: widget.shop.id,
                reason: reason,
                details: details,
                createdAt: DateTime.now(),
                userId: 'anonymous-user',
              );

              _reportService.addReport(report).then((_) {
                _loadReports();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('thank_you_report'.tr(context)),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
            reasonOptions: reasonOptions,
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
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}

class _ReportDialog extends StatefulWidget {
  final Function(String reason, String details) onSubmit;
  final List<String> reasonOptions;

  const _ReportDialog({required this.onSubmit, required this.reasonOptions});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _selectedReason = '';
  String _details = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text('report_incorrect'.tr(context)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08,
        vertical: 24.0,
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
              const SizedBox(height: 8),
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
            widget.onSubmit(_selectedReason, _details);
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
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08,
        vertical: 24.0,
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
                  hintText: 'Share your experience...',
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
