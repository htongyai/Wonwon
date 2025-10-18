import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Fetch all data in parallel
      final shopsQuery = await _firestore.collection('shops').get();
      final usersQuery = await _firestore.collection('users').get();
      final reportsQuery = await _firestore.collection('report').get();
      final categoriesQuery =
          await _firestore.collection('serviceCategories').get();
      final reviewsQuery = await _firestore.collection('reviews').get();

      // Process shops data
      final totalShops = shopsQuery.docs.length;
      final approvedShops =
          shopsQuery.docs.where((doc) => doc.data()['approved'] == true).length;
      final unapprovedShops = totalShops - approvedShops;
      final recentShops =
          shopsQuery.docs.where((doc) {
            final createdAt = doc.data()['createdAt'];
            if (createdAt is Timestamp) {
              return createdAt.toDate().isAfter(sevenDaysAgo);
            }
            return false;
          }).length;

      // Process users data
      final totalUsers = usersQuery.docs.length;
      final recentUsers =
          usersQuery.docs.where((doc) {
            final createdAt = doc.data()['createdAt'];
            if (createdAt is Timestamp) {
              return createdAt.toDate().isAfter(sevenDaysAgo);
            }
            return false;
          }).length;

      // Process reports data
      final totalReports = reportsQuery.docs.length;

      // Process categories and reviews
      final totalCategories = categoriesQuery.docs.length;
      final totalReviews = reviewsQuery.docs.length;

      double averageRating = 0.0;
      if (totalReviews > 0) {
        double totalRating = 0.0;
        for (var doc in reviewsQuery.docs) {
          final rating = doc.data()['rating'] ?? 0.0;
          totalRating += rating;
        }
        averageRating = totalRating / totalReviews;
      }

      final recentReviewsQuery =
          await _firestore
              .collection('reviews')
              .where('createdAt', isGreaterThan: sevenDaysAgo)
              .get();

      final topCategories = await _getTopCategories();

      if (mounted) {
        setState(() {
          _stats = {
            'totalShops': totalShops,
            'approvedShops': approvedShops,
            'unapprovedShops': unapprovedShops,
            'totalUsers': totalUsers,
            'totalReports': totalReports,
            'recentShops': recentShops,
            'recentUsers': recentUsers,
            'totalCategories': totalCategories,
            'totalReviews': totalReviews,
            'averageRating': averageRating,
            'recentReviews': recentReviewsQuery.docs.length,
            'topCategories': topCategories,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      appLog('Error loading dashboard stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getTopCategories() async {
    try {
      final categoriesQuery =
          await _firestore.collection('serviceCategories').get();
      final categories =
          categoriesQuery.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'name': doc.data()['name'] ?? 'Unknown',
                  'shopCount': 0,
                },
              )
              .toList();

      final shopsQuery = await _firestore.collection('shops').get();
      for (var shopDoc in shopsQuery.docs) {
        final shopData = shopDoc.data();
        final shopCategories = shopData['categories'] as List<dynamic>? ?? [];
        for (var categoryId in shopCategories) {
          final categoryIndex = categories.indexWhere(
            (cat) => cat['id'] == categoryId,
          );
          if (categoryIndex != -1) {
            categories[categoryIndex]['shopCount'] =
                (categories[categoryIndex]['shopCount'] ?? 0) + 1;
          }
        }
      }

      categories.sort(
        (a, b) => (b['shopCount'] ?? 0).compareTo(a['shopCount'] ?? 0),
      );
      return categories.take(5).toList();
    } catch (e) {
      appLog('Error getting top categories: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppConstants.darkColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.darkColor),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildKeyMetrics(),
                    const SizedBox(height: 32),
                    _buildChartsSection(),
                    const SizedBox(height: 32),
                    _buildRecentActivity(),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Admin Dashboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor and manage your repair shop platform',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppConstants.darkColor,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Shops',
                _stats['totalShops']?.toString() ?? '0',
                FontAwesomeIcons.store,
                AppConstants.primaryColor,
                'All registered shops',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                'Active Users',
                _stats['totalUsers']?.toString() ?? '0',
                FontAwesomeIcons.users,
                Colors.blue,
                'Registered users',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                'Categories',
                _stats['totalCategories']?.toString() ?? '0',
                FontAwesomeIcons.tags,
                Colors.purple,
                'Service categories',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                'Reviews',
                _stats['totalReviews']?.toString() ?? '0',
                FontAwesomeIcons.star,
                Colors.amber,
                'User reviews',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildApprovalStatus()),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildTopCategories()),
      ],
    );
  }

  Widget _buildApprovalStatus() {
    final approved = _stats['approvedShops'] ?? 0;
    final pending = _stats['unapprovedShops'] ?? 0;
    final total = approved + pending;
    final approvedPercentage = total > 0 ? (approved / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Shop Approval Status',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$approvedPercentage%',
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Approved',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusItem('Approved', approved, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatusItem('Pending', pending, Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final topCategories =
        _stats['topCategories'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Top Categories',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topCategories.isEmpty)
            Center(
              child: Text(
                'No categories found',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            ...topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(index),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category['name'] ?? 'Unknown',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppConstants.darkColor,
                        ),
                      ),
                    ),
                    Text(
                      '${category['shopCount'] ?? 0}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.darkColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity (7 days)',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'New Shops',
                  _stats['recentShops']?.toString() ?? '0',
                  FontAwesomeIcons.store,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActivityCard(
                  'New Users',
                  _stats['recentUsers']?.toString() ?? '0',
                  FontAwesomeIcons.userPlus,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActivityCard(
                  'New Reviews',
                  _stats['recentReviews']?.toString() ?? '0',
                  FontAwesomeIcons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildActionButton(
                'Add Shop',
                FontAwesomeIcons.plus,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddShopScreen(),
                  ),
                ),
              ),
              _buildActionButton(
                'Manage Shops',
                FontAwesomeIcons.store,
                AppConstants.primaryColor,
                () => Navigator.pushNamed(context, '/admin/manage-shops'),
              ),
              _buildActionButton(
                'Manage Users',
                FontAwesomeIcons.users,
                Colors.blue,
                () => Navigator.pushNamed(context, '/admin/manage-users'),
              ),
              _buildActionButton(
                'View Reports',
                FontAwesomeIcons.flag,
                Colors.orange,
                () => Navigator.pushNamed(context, '/admin/reports'),
              ),
              _buildActionButton(
                'Pending Approvals',
                FontAwesomeIcons.clock,
                Colors.red,
                () => Navigator.pushNamed(context, '/admin/unapprove-pages'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
