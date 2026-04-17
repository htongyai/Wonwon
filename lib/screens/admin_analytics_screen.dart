import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/screens/activity_log_screen.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/admin/analytics/registration_trend_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/category_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/approval_status_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/engagement_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/rating_distribution_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/area_distribution_chart.dart';
import 'package:wonwonw2/widgets/admin/analytics/metric_card.dart';
import 'package:wonwonw2/widgets/admin/analytics/top_shops_section.dart';
import 'package:wonwonw2/widgets/admin/analytics/category_performance_section.dart';

class AdminAnalyticsScreen extends OptimizedScreen {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState
    extends OptimizedLoadingScreen<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _analyticsData = {};
  String _selectedPeriod = '7d';

  @override
  void onScreenInit() {
    super.onScreenInit();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setLoading(true, message: 'loading_analytics'.tr(context));

    try {
      final data = await _fetchAnalyticsData();

      safeSetState(() {
        _analyticsData = data;
      });

      setLoading(false);
    } catch (e) {
      setError(e, message: 'Failed to load analytics data');
    }
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final now = DateTime.now();
    final days =
        _selectedPeriod == '7d' ? 7 : (_selectedPeriod == '30d' ? 30 : 90);
    final startDate = now.subtract(Duration(days: days));

    // Fetch data from all collections
    final futures = await Future.wait([
      _firestore.collection('shops').get(),
      _firestore.collection('users').get(),
      _firestore.collection('reviews').get(),
      _firestore.collection('report').get(),
    ]);

    final shopsSnapshot = futures[0];
    final usersSnapshot = futures[1];
    final reviewsSnapshot = futures[2];
    final reportsSnapshot = futures[3];

    // Enhanced shop analytics
    final shopsByCategory = <String, int>{};
    final shopsByArea = <String, int>{};
    final shopRegistrationTrend = <DateTime, int>{};
    final shopPerformanceData = <String, Map<String, dynamic>>{};
    int approvedShops = 0;
    int pendingShops = 0;

    for (var doc in shopsSnapshot.docs) {
      final data = doc.data();
      final shopId = doc.id;

      // Approval status
      final isApproved = data['approved'] ?? false;
      if (isApproved) {
        approvedShops++;
      } else {
        pendingShops++;
      }

      // Category distribution
      final categories = List<String>.from(data['categories'] ?? []);
      for (var category in categories) {
        shopsByCategory[category] = (shopsByCategory[category] ?? 0) + 1;
      }

      // Area distribution
      final area = data['area'] ?? 'Unknown';
      shopsByArea[area] = (shopsByArea[area] ?? 0) + 1;

      // Shop performance metrics
      final rating = (data['rating'] ?? 0.0).toDouble();
      final reviewCount = (data['reviewCount'] ?? 0);
      shopPerformanceData[shopId] = {
        'name': data['name'] ?? 'Unknown',
        'rating': rating,
        'reviewCount': reviewCount,
        'category': categories.isNotEmpty ? categories.first : 'Unknown',
        'area': area,
        'approved': isApproved,
      };

      // Registration trend
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        if (date.isAfter(startDate)) {
          final dayKey = DateTime(date.year, date.month, date.day);
          shopRegistrationTrend[dayKey] =
              (shopRegistrationTrend[dayKey] ?? 0) + 1;
        }
      }
    }

    // Enhanced user analytics
    final userRegistrationTrend = <DateTime, int>{};
    final usersByAccountType = <String, int>{};
    final userEngagementData = <String, Map<String, dynamic>>{};
    int activeUsers = 0;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final userId = doc.id;

      // Account type distribution
      final accountType = data['accountType'] ?? 'user';
      usersByAccountType[accountType] =
          (usersByAccountType[accountType] ?? 0) + 1;

      // User activity analysis
      final lastLoginAt = data['lastLoginAt'];
      final isActive =
          lastLoginAt != null &&
          (lastLoginAt is Timestamp) &&
          lastLoginAt.toDate().isAfter(now.subtract(const Duration(days: 30)));

      if (isActive) activeUsers++;

      userEngagementData[userId] = {
        'name': data['name'] ?? 'Unknown',
        'email': data['email'] ?? 'Unknown',
        'accountType': accountType,
        'status': data['status'] ?? 'active',
        'isActive': isActive,
        'createdAt': data['createdAt'],
        'lastLoginAt': lastLoginAt,
        'lastActiveAt': data['lastActiveAt'] ?? lastLoginAt,
      };

      // Registration trend
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        if (date.isAfter(startDate)) {
          final dayKey = DateTime(date.year, date.month, date.day);
          userRegistrationTrend[dayKey] =
              (userRegistrationTrend[dayKey] ?? 0) + 1;
        }
      }
    }

    // Enhanced review analytics
    final ratingDistribution = <int, int>{};
    final reviewTrend = <DateTime, int>{};
    final reviewsByCategory = <String, int>{};
    double totalRating = 0;
    int reviewCount = 0;

    for (var doc in reviewsSnapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] ?? 0.0).toDouble();
      final ratingInt = rating.round();
      final shopId = data['shopId'] ?? '';

      ratingDistribution[ratingInt] = (ratingDistribution[ratingInt] ?? 0) + 1;
      totalRating += rating;
      reviewCount++;

      // Reviews by category (based on shop category)
      if (shopPerformanceData.containsKey(shopId)) {
        final category = shopPerformanceData[shopId]!['category'] as String;
        reviewsByCategory[category] = (reviewsByCategory[category] ?? 0) + 1;
      }

      // Review trend
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        if (date.isAfter(startDate)) {
          final dayKey = DateTime(date.year, date.month, date.day);
          reviewTrend[dayKey] = (reviewTrend[dayKey] ?? 0) + 1;
        }
      }
    }

    // Enhanced report analytics
    final reportsByType = <String, int>{};
    final reportTrend = <DateTime, int>{};
    final reportsByStatus = <String, int>{};

    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();

      // Report type distribution
      final type = data['type'] ?? 'Other';
      reportsByType[type] = (reportsByType[type] ?? 0) + 1;

      // Report status distribution
      final status = data['status'] ?? 'pending';
      reportsByStatus[status] = (reportsByStatus[status] ?? 0) + 1;

      // Report trend
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        if (date.isAfter(startDate)) {
          final dayKey = DateTime(date.year, date.month, date.day);
          reportTrend[dayKey] = (reportTrend[dayKey] ?? 0) + 1;
        }
      }
    }

    // Calculate performance metrics
    final topPerformingShops =
        shopPerformanceData.entries
            .where((entry) => entry.value['reviewCount'] > 0)
            .toList()
          ..sort(
            (a, b) => (b.value['rating'] as double).compareTo(
              a.value['rating'] as double,
            ),
          );

    final categoryPerformance = <String, Map<String, dynamic>>{};
    for (var category in shopsByCategory.keys) {
      final categoryShops = shopPerformanceData.values.where(
        (shop) => shop['category'] == category,
      );

      if (categoryShops.isNotEmpty) {
        final avgRating =
            categoryShops
                .map((shop) => shop['rating'] as double)
                .reduce((a, b) => a + b) /
            categoryShops.length;
        final totalReviews = categoryShops
            .map((shop) => shop['reviewCount'] as int)
            .reduce((a, b) => a + b);

        categoryPerformance[category] = {
          'averageRating': avgRating,
          'totalReviews': totalReviews,
          'shopCount': categoryShops.length,
        };
      }
    }

    // Calculate top engaged shops based on reviews, ratings, and recent activity
    final engagedShops = <String, Map<String, dynamic>>{};

    for (var entry in shopPerformanceData.entries) {
      final shopId = entry.key;
      final shopData = entry.value;

      // Calculate engagement score based on:
      // - Review count (40% weight)
      // - Average rating (30% weight)
      // - Recent review activity (30% weight)
      final reviewCount = shopData['reviewCount'] as int;
      final rating = shopData['rating'] as double;

      // Count recent reviews (last 30 days)
      final recentReviews =
          reviewsSnapshot.docs.where((doc) {
            final reviewData = doc.data();
            final shopIdFromReview = reviewData['shopId'];
            final createdAt = reviewData['createdAt'];

            if (shopIdFromReview == shopId && createdAt is Timestamp) {
              return createdAt.toDate().isAfter(
                now.subtract(const Duration(days: 30)),
              );
            }
            return false;
          }).length;

      // Calculate engagement score (0-100)
      final reviewScore =
          (reviewCount * 2).clamp(0, 40).toDouble(); // Max 40 points
      final ratingScore =
          (rating * 6).clamp(0, 30).toDouble(); // Max 30 points (5 stars * 6)
      final recentActivityScore =
          (recentReviews * 5).clamp(0, 30).toDouble(); // Max 30 points

      final engagementScore = reviewScore + ratingScore + recentActivityScore;

      if (engagementScore > 0) {
        engagedShops[shopId] = {
          ...shopData,
          'engagementScore': engagementScore,
          'recentReviews': recentReviews,
        };
      }
    }

    // Sort by engagement score and take top 5
    final topEngagedShops =
        engagedShops.entries.toList()..sort(
          (a, b) => (b.value['engagementScore'] as double).compareTo(
            a.value['engagementScore'] as double,
          ),
        );

    return {
      // Basic metrics
      'totalShops': shopsSnapshot.docs.length,
      'totalUsers': usersSnapshot.docs.length,
      'totalReviews': reviewCount,
      'totalReports': reportsSnapshot.docs.length,
      'averageRating': reviewCount > 0 ? totalRating / reviewCount : 0.0,

      // Shop analytics
      'shopsByCategory': shopsByCategory,
      'shopsByArea': shopsByArea,
      'shopRegistrationTrend': shopRegistrationTrend,
      'approvedShops': approvedShops,
      'pendingShops': pendingShops,
      'shopPerformanceData': shopPerformanceData,
      'topPerformingShops': topPerformingShops.take(10).toList(),
      'topEngagedShops': topEngagedShops.take(5).toList(),
      'categoryPerformance': categoryPerformance,

      // User analytics
      'userRegistrationTrend': userRegistrationTrend,
      'usersByAccountType': usersByAccountType,
      'activeUsers': activeUsers,
      'userEngagementData': userEngagementData,

      // Review analytics
      'ratingDistribution': ratingDistribution,
      'reviewTrend': reviewTrend,
      'reviewsByCategory': reviewsByCategory,

      // Report analytics
      'reportsByType': reportsByType,
      'reportTrend': reportTrend,
      'reportsByStatus': reportsByStatus,
    };
  }

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Analytics Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 32),

          // Key Metrics
          _buildKeyMetrics(),
          const SizedBox(height: 32),

          // Charts Section
          _buildChartsSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('7d', '7 Days'),
          _buildPeriodButton('30d', '30 Days'),
          _buildPeriodButton('90d', '90 Days'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          safeSetState(() {
            _selectedPeriod = period;
          });
          _loadAnalyticsData();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final metrics = [
      AnalyticsMetric(
        title: 'total_shops'.tr(context),
        value: _analyticsData['totalShops']?.toString() ?? '0',
        subtitle: 'n_approved'.tr(context).replaceAll('{count}', '${_analyticsData['approvedShops'] ?? 0}'),
        icon: FontAwesomeIcons.store,
        color: const Color(0xFF3B82F6),
        trend: _calculateShopGrowthTrend(),
      ),
      AnalyticsMetric(
        title: 'active_users'.tr(context),
        value: _analyticsData['activeUsers']?.toString() ?? '0',
        subtitle: 'of_n_total'.tr(context).replaceAll('{count}', '${_analyticsData['totalUsers'] ?? 0}'),
        icon: FontAwesomeIcons.users,
        color: const Color(0xFF10B981),
        trend: _calculateUserGrowthTrend(),
      ),
      AnalyticsMetric(
        title: 'average_rating'.tr(context),
        value: (_analyticsData['averageRating'] ?? 0.0).toStringAsFixed(1),
        subtitle: 'from_n_reviews'.tr(context).replaceAll('{count}', '${_analyticsData['totalReviews'] ?? 0}'),
        icon: FontAwesomeIcons.star,
        color: const Color(0xFFF59E0B),
        trend: 0.0,
      ),
      AnalyticsMetric(
        title: 'pending_shops'.tr(context),
        value: _analyticsData['pendingShops']?.toString() ?? '0',
        subtitle: 'awaiting_approval'.tr(context),
        icon: FontAwesomeIcons.clock,
        color: const Color(0xFFEF4444),
        trend: 0.0,
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: metrics.length,
          itemBuilder:
              (context, index) => MetricCard(metric: metrics[index]),
        ),
        const SizedBox(height: 32),
        _buildPerformanceInsights(),
      ],
    );
  }

  double _calculateShopGrowthTrend() {
    final registrationTrend =
        _analyticsData['shopRegistrationTrend'] as Map<DateTime, int>? ?? {};
    if (registrationTrend.isEmpty) return 0.0;

    final values = registrationTrend.values.toList();
    if (values.length < 2) return 0.0;

    final recent = values.sublist(values.length ~/ 2).fold(0, (a, b) => a + b);
    final older = values
        .sublist(0, values.length ~/ 2)
        .fold(0, (a, b) => a + b);

    if (older == 0) return recent > 0 ? 100.0 : 0.0;
    return ((recent - older) / older * 100);
  }

  double _calculateUserGrowthTrend() {
    final registrationTrend =
        _analyticsData['userRegistrationTrend'] as Map<DateTime, int>? ?? {};
    if (registrationTrend.isEmpty) return 0.0;

    final values = registrationTrend.values.toList();
    if (values.length < 2) return 0.0;

    final recent = values.sublist(values.length ~/ 2).fold(0, (a, b) => a + b);
    final older = values
        .sublist(0, values.length ~/ 2)
        .fold(0, (a, b) => a + b);

    if (older == 0) return recent > 0 ? 100.0 : 0.0;
    return ((recent - older) / older * 100);
  }

  Widget _buildPerformanceInsights() {
    final topShops = _analyticsData['topPerformingShops'] as List? ?? [];
    final categoryPerformance =
        _analyticsData['categoryPerformance']
            as Map<String, Map<String, dynamic>>? ??
        {};

    return Row(
      children: [
        Expanded(
          child: TopShopsSection(
            topShops: topShops,
            onShopTap: _showShopDetails,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CategoryPerformanceSection(
            categoryPerformance: categoryPerformance,
            onCategoryTap: _showCategoryPerformanceDetails,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        RegistrationTrendChart(
          shopTrend: _analyticsData['shopRegistrationTrend'] as Map<DateTime, int>? ?? {},
          userTrend: _analyticsData['userRegistrationTrend'] as Map<DateTime, int>? ?? {},
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: ShopCategoryChart(
                data: _analyticsData['shopsByCategory'] as Map<String, int>? ?? {},
                onCategoryTap: _showCategoryDetails,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ApprovalStatusChart(
                approvedShops: _analyticsData['approvedShops'] ?? 0,
                pendingShops: _analyticsData['pendingShops'] ?? 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: UserEngagementChart(
                activeUsers: _analyticsData['activeUsers'] ?? 0,
                totalUsers: _analyticsData['totalUsers'] ?? 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RatingDistributionChart(
                data: _analyticsData['ratingDistribution'] as Map<int, int>? ?? {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        AreaDistributionChart(
          data: _analyticsData['shopsByArea'] as Map<String, int>? ?? {},
        ),
        const SizedBox(height: 24),

        _buildUserActivitySection(),
        const SizedBox(height: 24),

        _buildTopEngagedShopsSection(),
      ],
    );
  }

  Widget _buildUserActivitySection() {
    final userEngagementData =
        _analyticsData['userEngagementData']
            as Map<String, Map<String, dynamic>>? ??
        {};
    final recentUsers =
        userEngagementData.entries
            .where((entry) => entry.value['lastActiveAt'] != null)
            .toList()
          ..sort((a, b) {
            final aTime = a.value['lastActiveAt'];
            final bTime = b.value['lastActiveAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.toDate().compareTo(aTime.toDate());
            }
            return 0;
          });

    return Row(
      children: [
        Expanded(
          child: _buildRecentUserActivity(recentUsers.take(10).toList()),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildUserEngagementStats()),
      ],
    );
  }

  Widget _buildRecentUserActivity(
    List<MapEntry<String, Map<String, dynamic>>> recentUsers,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              FaIcon(
                FontAwesomeIcons.clock,
                color: const Color(0xFF06B6D4),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent User Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showAllUserActivity(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'view_all'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF06B6D4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('no_data_available'.tr(context)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final userEntry = recentUsers[index];
                final user = userEntry.value;
                final userId = userEntry.key;
                final lastActive = user['lastActiveAt'];

                return InkWell(
                  onTap: () => _showUserDetails(userId, user),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getUserStatusColor(user).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              (user['name'] as String).isNotEmpty
                                  ? (user['name'] as String)[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _getUserStatusColor(user),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'Unknown User',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user['accountType'] ?? 'user',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    user['isActive']
                                        ? const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.1)
                                        : const Color(
                                          0xFF64748B,
                                        ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user['isActive'] ? 'Active' : 'Inactive',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      user['isActive']
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastActive != null && lastActive is Timestamp
                                  ? _formatLastActiveTime(lastActive.toDate())
                                  : 'Never',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUserEngagementStats() {
    final userEngagementData =
        _analyticsData['userEngagementData']
            as Map<String, Map<String, dynamic>>? ??
        {};
    final now = DateTime.now();

    // Calculate engagement stats
    final todayActive =
        userEngagementData.values.where((user) {
          final lastActive = user['lastActiveAt'];
          if (lastActive is Timestamp) {
            final activeDate = lastActive.toDate();
            return activeDate.year == now.year &&
                activeDate.month == now.month &&
                activeDate.day == now.day;
          }
          return false;
        }).length;

    final weekActive =
        userEngagementData.values.where((user) {
          final lastActive = user['lastActiveAt'];
          if (lastActive is Timestamp) {
            return lastActive.toDate().isAfter(
              now.subtract(const Duration(days: 7)),
            );
          }
          return false;
        }).length;

    final monthActive =
        userEngagementData.values.where((user) {
          final lastActive = user['lastActiveAt'];
          if (lastActive is Timestamp) {
            return lastActive.toDate().isAfter(
              now.subtract(const Duration(days: 30)),
            );
          }
          return false;
        }).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              FaIcon(
                FontAwesomeIcons.chartLine,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'User Engagement Stats',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEngagementStatCard(
            'Today',
            todayActive,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildEngagementStatCard(
            'This Week',
            weekActive,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          _buildEngagementStatCard(
            'This Month',
            monthActive,
            const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _showActivityLogPage(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.list,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'view_activity_log'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Active Users',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserStatusColor(Map<String, dynamic> user) {
    final accountType = user['accountType'] as String? ?? 'user';
    switch (accountType) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'moderator':
        return const Color(0xFFF59E0B);
      case 'shop_owner':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatLastActiveTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  void _showAllUserActivity() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.users,
                      color: const Color(0xFF06B6D4),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'all_user_activity'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildAllUserActivityContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllUserActivityContent() {
    final userEngagementData =
        _analyticsData['userEngagementData']
            as Map<String, Map<String, dynamic>>? ??
        {};
    final allUsers =
        userEngagementData.entries.toList()..sort((a, b) {
          final aTime = a.value['lastActiveAt'];
          final bTime = b.value['lastActiveAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.toDate().compareTo(aTime.toDate());
          }
          return 0;
        });

    return ListView.separated(
      itemCount: allUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final userEntry = allUsers[index];
        final user = userEntry.value;
        final userId = userEntry.key;
        final lastActive = user['lastActiveAt'];
        final createdAt = user['createdAt'];

        return InkWell(
          onTap: () => _showUserDetails(userId, user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getUserStatusColor(user).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] as String).isNotEmpty
                          ? (user['name'] as String)[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _getUserStatusColor(user),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown User',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? 'no_email'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getUserStatusColor(user).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['accountType'] ?? 'user',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getUserStatusColor(user),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  user['isActive']
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : const Color(
                                        0xFF64748B,
                                      ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['isActive'] ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    user['isActive']
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      lastActive != null && lastActive is Timestamp
                          ? _formatLastActiveTime(lastActive.toDate())
                          : 'Never',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${createdAt != null && createdAt is Timestamp ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'Unknown'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserDetails(String userId, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getUserStatusColor(user).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (user['name'] as String).isNotEmpty
                              ? (user['name'] as String)[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getUserStatusColor(user),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'Unknown User',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            user['email'] ?? 'no_email'.tr(context),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildUserDetailsContent(userId, user)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserDetailsContent(String userId, Map<String, dynamic> user) {
    final lastActive = user['lastActiveAt'];
    final lastLogin = user['lastLoginAt'];
    final createdAt = user['createdAt'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User status cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        user['isActive']
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFF64748B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        user['isActive'] ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              user['isActive']
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getUserStatusColor(user).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        user['accountType'] ?? 'user',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _getUserStatusColor(user),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account Type',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Activity information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Information',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('User ID', userId),
                _buildDetailRow('Account Status', user['status'] ?? 'active'),
                _buildDetailRow(
                  'Last Active',
                  lastActive != null && lastActive is Timestamp
                      ? DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format(lastActive.toDate())
                      : 'Never',
                ),
                _buildDetailRow(
                  'Last Login',
                  lastLogin != null && lastLogin is Timestamp
                      ? DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format(lastLogin.toDate())
                      : 'Never',
                ),
                _buildDetailRow(
                  'Member Since',
                  createdAt != null && createdAt is Timestamp
                      ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
                      : 'Unknown',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityLogPage() {
    // Import will be added at the top of the file
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ActivityLogScreen()));
  }

  void _showCategoryDetails(String category, int shopCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.tags,
                      color: const Color(0xFF8B5CF6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'category_details'.tr(context).replaceAll('{category}', category),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCategoryDetailsContent(category, shopCount),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDetailsContent(String category, int shopCount) {
    // Get shops in this category
    final categoryShops =
        (_analyticsData['shopPerformanceData']
                    as Map<String, Map<String, dynamic>>? ??
                {})
            .entries
            .where((entry) => entry.value['category'] == category)
            .toList();

    // Get subservices for this category
    final subServices = _getSubServicesForCategory(category);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Shops',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          shopCount.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avg Rating',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.star,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoryShops.isNotEmpty
                                  ? (categoryShops
                                              .map(
                                                (e) =>
                                                    e.value['rating'] as double,
                                              )
                                              .reduce((a, b) => a + b) /
                                          categoryShops.length)
                                      .toStringAsFixed(1)
                                  : '0.0',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF59E0B),
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
            const SizedBox(height: 24),

            // Subservices section
            if (subServices.isNotEmpty) ...[
              Text(
                'Subservices',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    subServices.map((subService) {
                      return InkWell(
                        onTap:
                            () => _showSubServiceDetails(category, subService),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subService,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Shops in category
            Text(
              'Shops in Category',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            if (categoryShops.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('no_shops_in_category'.tr(context)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryShops.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shopEntry = categoryShops[index];
                  final shop = shopEntry.value;
                  final shopId = shopEntry.key;

                  return InkWell(
                    onTap: () => _showShopDetails(shopId, shop),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop['name'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shop['area'] ?? 'Unknown Area',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.star,
                                    size: 14,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (shop['rating'] as double).toStringAsFixed(
                                      1,
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shop['reviewCount']} reviews',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPerformanceDetails(
    String category,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.chartBar,
                      color: const Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'category_performance'.tr(context).replaceAll('{category}', category),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildPerformanceMetrics(category, data)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics(String category, Map<String, dynamic> data) {
    final avgRating = data['averageRating'] as double;
    final totalReviews = data['totalReviews'] as int;
    final shopCount = data['shopCount'] as int;

    return Column(
      children: [
        // Performance metrics cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.star,
                          size: 20,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Average Rating',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      totalReviews.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Reviews',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      shopCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Shops',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Performance insights
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Insights',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildInsightItem(
                        'Rating Performance',
                        avgRating >= 4.0
                            ? 'Excellent'
                            : avgRating >= 3.0
                            ? 'Good'
                            : 'Needs Improvement',
                        avgRating >= 4.0
                            ? const Color(0xFF10B981)
                            : avgRating >= 3.0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                        avgRating >= 4.0
                            ? Icons.trending_up
                            : avgRating >= 3.0
                            ? Icons.trending_flat
                            : Icons.trending_down,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        'Review Volume',
                        totalReviews >= 100
                            ? 'High'
                            : totalReviews >= 50
                            ? 'Medium'
                            : 'Low',
                        totalReviews >= 100
                            ? const Color(0xFF10B981)
                            : totalReviews >= 50
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                        totalReviews >= 100
                            ? Icons.volume_up
                            : totalReviews >= 50
                            ? Icons.volume_down
                            : Icons.volume_mute,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        'Market Presence',
                        shopCount >= 20
                            ? 'Strong'
                            : shopCount >= 10
                            ? 'Moderate'
                            : 'Limited',
                        shopCount >= 20
                            ? const Color(0xFF10B981)
                            : shopCount >= 10
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                        shopCount >= 20
                            ? Icons.store
                            : shopCount >= 10
                            ? Icons.storefront
                            : Icons.store_mall_directory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShopDetails(String shopId, Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.store,
                      color: const Color(0xFF3B82F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shop['name'] ?? 'unknown_shop'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildShopDetailsContent(shopId, shop)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopDetailsContent(String shopId, Map<String, dynamic> shop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop overview cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.star,
                            size: 20,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (shop['rating'] as double).toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rating',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        shop['reviewCount'].toString(),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reviews',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Shop details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('category_form_label'.tr(context), shop['category'] ?? 'unknown'.tr(context)),
                _buildDetailRow('area_label'.tr(context), shop['area'] ?? 'unknown'.tr(context)),
                _buildDetailRow(
                  'status_label'.tr(context),
                  shop['approved'] ? 'approved'.tr(context) : 'admin_pending'.tr(context),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to shop management or edit
                        },
                        icon: const Icon(Icons.edit),
                        label: Text('edit_shop_label'.tr(context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
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
                          Navigator.of(context).pop();
                          // Navigate to shop detail screen
                        },
                        icon: const Icon(Icons.visibility),
                        label: Text('view_details'.tr(context)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubServiceDetails(String category, String subService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.cogs,
                      color: const Color(0xFF3B82F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subService,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.wrench,
                          size: 64,
                          color: const Color(0xFF64748B).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Subservice Details',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Detailed analytics for $subService in $category category',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('close_button'.tr(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getSubServicesForCategory(String category) {
    // This would typically fetch from your database
    // For now, returning sample subservices based on category
    switch (category.toLowerCase()) {
      case 'automotive':
        return [
          'Engine Repair',
          'Brake Service',
          'Oil Change',
          'Tire Service',
          'AC Repair',
        ];
      case 'electronics':
        return [
          'Phone Repair',
          'Computer Service',
          'TV Repair',
          'Audio Systems',
        ];
      case 'home services':
        return ['Plumbing', 'Electrical', 'Cleaning', 'Painting', 'Carpentry'];
      case 'beauty':
        return ['Hair Cut', 'Manicure', 'Facial', 'Massage', 'Makeup'];
      default:
        return ['General Service', 'Consultation', 'Maintenance'];
    }
  }

  Widget _buildTopEngagedShopsSection() {
    final topEngagedShops =
        _analyticsData['topEngagedShops']
            as List<MapEntry<String, Map<String, dynamic>>>? ??
        [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.fire,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Top 5 Engaged Shops',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Based on reviews & activity',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (topEngagedShops.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.chartLine,
                      color: const Color(0xFF64748B),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_data_available'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shops with reviews and ratings will appear here',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children:
                  topEngagedShops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final shopEntry = entry.value;
                    final shopId = shopEntry.key;
                    final shopData = shopEntry.value;

                    return _buildEngagedShopCard(index + 1, shopId, shopData);
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagedShopCard(
    int rank,
    String shopId,
    Map<String, dynamic> shopData,
  ) {
    final engagementScore = (shopData['engagementScore'] as double).round();
    final rating = shopData['rating'] as double;
    final reviewCount = shopData['reviewCount'] as int;
    final recentReviews = shopData['recentReviews'] as int;
    final category = shopData['category'] as String;
    final area = shopData['area'] as String;
    final isApproved = shopData['approved'] as bool;

    // Get rank color
    Color getRankColor() {
      switch (rank) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFC0C0C0); // Silver
        case 3:
          return const Color(0xFFCD7F32); // Bronze
        default:
          return const Color(0xFF64748B); // Gray
      }
    }

    // Get rank icon
    IconData getRankIcon() {
      switch (rank) {
        case 1:
          return FontAwesomeIcons.crown;
        case 2:
          return FontAwesomeIcons.medal;
        case 3:
          return FontAwesomeIcons.award;
        default:
          return FontAwesomeIcons.trophy;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showEngagedShopDetails(shopId, shopData),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: getRankColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: getRankColor().withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: FaIcon(getRankIcon(), color: getRankColor(), size: 20),
                ),
              ),
              const SizedBox(width: 16),

              // Shop info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shopData['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (!isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pending',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category • $area',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFBBF24),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Review count
                        Row(
                          children: [
                            const Icon(
                              Icons.reviews,
                              color: Color(0xFF3B82F6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'n_reviews_count'.tr(context).replaceAll('{count}', '$reviewCount'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Recent activity
                        if (recentReviews > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'n_recent'.tr(context).replaceAll('{count}', '$recentReviews'),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Engagement score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$engagementScore',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'score'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEngagedShopDetails(String shopId, Map<String, dynamic> shopData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: min(600, MediaQuery.of(context).size.width - 32),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.fire,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Engagement Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Shop name and basic info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopData['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${shopData['category']} • ${shopData['area']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Engagement metrics
                Text(
                  'Engagement Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),

                _buildEngagementMetric(
                  'total_reviews_label'.tr(context),
                  'n_reviews_count'.tr(context).replaceAll('{count}', '${shopData['reviewCount']}'),
                  Icons.reviews,
                  const Color(0xFF3B82F6),
                ),
                _buildEngagementMetric(
                  'Average Rating',
                  '${(shopData['rating'] as double).toStringAsFixed(1)} stars',
                  Icons.star,
                  const Color(0xFFFBBF24),
                ),
                _buildEngagementMetric(
                  'Recent Activity',
                  '${shopData['recentReviews']} reviews (30 days)',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
                _buildEngagementMetric(
                  'Engagement Score',
                  '${(shopData['engagementScore'] as double).round()}/100',
                  Icons.analytics,
                  const Color(0xFF8B5CF6),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'close'.tr(context),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEngagementMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
