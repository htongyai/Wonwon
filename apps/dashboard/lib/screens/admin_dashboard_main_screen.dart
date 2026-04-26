import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_dashboard/widgets/optimized_screen.dart';
import 'package:shared/services/auth_manager.dart';
import 'package:wonwon_dashboard/mixins/auth_state_mixin.dart';
import 'package:wonwon_dashboard/screens/admin_analytics_screen.dart';
import 'package:wonwon_dashboard/screens/admin_shop_management_screen.dart';
import 'package:wonwon_dashboard/screens/admin_user_management_screen.dart';
import 'package:wonwon_dashboard/screens/admin_reports_management_screen.dart';
import 'package:wonwon_dashboard/screens/activity_log_screen.dart';
import 'package:wonwon_dashboard/screens/admin_settings_screen.dart';
import 'package:wonwon_dashboard/screens/admin_map_view_screen.dart';
import 'package:wonwon_dashboard/widgets/auth_gate.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class AdminDashboardMainScreen extends OptimizedScreen {
  const AdminDashboardMainScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminDashboardMainScreen> createState() =>
      _AdminDashboardMainScreenState();
}

class _AdminDashboardMainScreenState
    extends OptimizedLoadingScreen<AdminDashboardMainScreen>
    with AuthStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthManager _authManager = AuthManager();

  Map<String, dynamic> _dashboardStats = {};
  int _selectedIndex = 0;
  String? _userEmail;
  String _appVersion = '';

  List<AdminMenuItem> _getMenuItems(BuildContext context) => [
    AdminMenuItem(
      title: 'dashboard_label'.tr(context),
      icon: FontAwesomeIcons.chartLine,
      route: '/admin/dashboard',
    ),
    AdminMenuItem(
      title: 'analytics_label'.tr(context),
      icon: FontAwesomeIcons.chartPie,
      route: '/admin/analytics',
    ),
    AdminMenuItem(
      title: 'shop_management_label'.tr(context),
      icon: FontAwesomeIcons.store,
      route: '/admin/shops',
    ),
    AdminMenuItem(
      title: 'map_view_label'.tr(context),
      icon: FontAwesomeIcons.mapLocationDot,
      route: '/admin/map',
    ),
    AdminMenuItem(
      title: 'user_management_label'.tr(context),
      icon: FontAwesomeIcons.users,
      route: '/admin/users',
    ),
    AdminMenuItem(
      title: 'reports_issues_label'.tr(context),
      icon: FontAwesomeIcons.flag,
      route: '/admin/reports',
    ),
    AdminMenuItem(
      title: 'activity_log_label'.tr(context),
      icon: FontAwesomeIcons.clockRotateLeft,
      route: '/admin/activity-log',
    ),
    AdminMenuItem(
      title: 'settings_label'.tr(context),
      icon: FontAwesomeIcons.cog,
      route: '/admin/settings',
    ),
  ];

  @override
  void onScreenInit() {
    super.onScreenInit();
    appLog('=== ADMIN DASHBOARD MAIN SCREEN INIT ===');
    appLog('AdminDashboardMainScreen: onScreenInit called');
    _loadDashboardData();
    _loadUserInfo();
    _loadAppVersion();
  }

  @override
  void onAuthStateChanged(bool isLoggedIn) {
    if (!mounted) return;
    if (!isLoggedIn) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminAuthGate()),
        (route) => false,
      );
    } else {
      _checkAdminAccess();
    }
  }

  @override
  void onUserChanged(user) {
    if (user != null) {
      _loadUserInfo();
      _checkAdminAccess();
    }
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _authManager.isAdmin();
      if (!isAdmin) {
        appLog('AdminDashboardMainScreen: Access denied - not an admin');
        setError('Access Denied', message: 'You do not have admin privileges');
        return;
      }
      appLog('AdminDashboardMainScreen: Admin access confirmed');
    } catch (e) {
      appLog('AdminDashboardMainScreen: Error checking admin access: $e');
      setError(
        'Authentication Error',
        message: 'Failed to verify admin privileges',
      );
    }
  }

  Future<void> _loadDashboardData() async {
    setLoading(true, message: 'Loading dashboard data...');

    try {
      // Check admin access
      final isAdmin = await _authManager.isAdmin();
      appLog(
        'AdminDashboardMainScreen: Checking admin access. Is admin? $isAdmin',
      );
      if (!isAdmin) {
        appLog('AdminDashboardMainScreen: Access denied - not an admin');
        setError('Access Denied', message: 'You do not have admin privileges');
        return;
      }
      appLog(
        'AdminDashboardMainScreen: Admin access confirmed, loading dashboard...',
      );

      // Load dashboard statistics
      final stats = await _loadDashboardStats();

      safeSetState(() {
        _dashboardStats = stats;
      });

      setLoading(false);
    } catch (e) {
      setError(e, message: 'Failed to load dashboard data');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final email = await _authManager.getCurrentUserName();
      if (mounted) {
        safeSetState(() {
          _userEmail = email;
        });
      }
    } catch (e) {
      appLog('Error loading user info: $e');
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        safeSetState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      appLog('Error loading app version: $e');
    }
  }

  /// Aggregate review stats from subcollections: shops/{shopId}/review
  Future<Map<String, dynamic>> _aggregateReviewStats() async {
    try {
      final shopsSnapshot = await _firestore.collection('shops').get();
      int totalReviews = 0;
      double totalRating = 0.0;

      // Fetch review subcollections in parallel (batched to avoid overwhelming Firestore)
      final futures = <Future<QuerySnapshot>>[];
      for (final shopDoc in shopsSnapshot.docs) {
        futures.add(
          _firestore.collection('shops').doc(shopDoc.id).collection('review').get(),
        );
      }

      final reviewSnapshots = await Future.wait(
        futures.map((f) => f.then<QuerySnapshot?>((v) => v).catchError((_) => null as QuerySnapshot?)),
        eagerError: false,
      );

      for (final snapshot in reviewSnapshots) {
        if (snapshot == null) continue;
        for (final doc in snapshot.docs) {
          totalReviews++;
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final rating = (data['rating'] ?? 0.0);
            if (rating is num) totalRating += rating.toDouble();
          }
        }
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': totalReviews > 0 ? totalRating / totalReviews : 0.0,
      };
    } catch (e) {
      appLog('Error aggregating review stats: $e');
      return {'totalReviews': 0, 'averageRating': 0.0};
    }
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Fetch all collections in parallel, tolerating individual failures
    QuerySnapshot? shopsSnapshot;
    QuerySnapshot? usersSnapshot;
    QuerySnapshot? reportsSnapshot;

    final results = await Future.wait([
      _firestore.collection('shops').get().then<QuerySnapshot?>((v) => v).catchError((_) => null as QuerySnapshot?),
      _firestore.collection('users').get().then<QuerySnapshot?>((v) => v).catchError((_) => null as QuerySnapshot?),
      _firestore.collection('report').get().then<QuerySnapshot?>((v) => v).catchError((_) => null as QuerySnapshot?),
    ], eagerError: false);

    // Fetch review stats from subcollections (correct path: shops/{id}/review)
    final reviewStats = await _aggregateReviewStats();

    shopsSnapshot = results[0];
    usersSnapshot = results[1];
    reportsSnapshot = results[2];

    // Process shops data
    final shopsDocs = (shopsSnapshot?.docs ?? []).cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    final totalShops = shopsDocs.length;
    final approvedShops =
        shopsDocs
            .where((doc) => doc.data()['approved'] == true)
            .length;
    final pendingShops = totalShops - approvedShops;
    final recentShops =
        shopsDocs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    // Process users data
    final usersDocs = (usersSnapshot?.docs ?? []).cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    final totalUsers = usersDocs.length;
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final activeUsers =
        usersDocs.where((doc) {
          final lastLoginAt = doc.data()['lastLoginAt'];
          return lastLoginAt is Timestamp &&
              lastLoginAt.toDate().isAfter(thirtyDaysAgo);
        }).length;
    final recentUsers =
        usersDocs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    // Process reports data
    final reportsDocs = (reportsSnapshot?.docs ?? []).cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    final totalReports = reportsDocs.length;
    final pendingReports =
        reportsDocs
            .where((doc) => doc.data()['resolved'] != true)
            .length;
    final recentReports =
        reportsDocs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    return {
      'totalShops': totalShops,
      'approvedShops': approvedShops,
      'pendingShops': pendingShops,
      'recentShops': recentShops,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'recentUsers': recentUsers,
      'totalReports': totalReports,
      'pendingReports': pendingReports,
      'recentReports': recentReports,
      'totalReviews': reviewStats['totalReviews'] ?? 0,
      'averageRating': reviewStats['averageRating'] ?? 0.0,
    };
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const AdminAnalyticsScreen();
      case 2:
        return const AdminShopManagementScreen();
      case 3:
        return const AdminMapViewScreen();
      case 4:
        return const AdminUserManagementScreen();
      case 5:
        return const AdminReportsManagementScreen();
      case 6:
        return const ActivityLogScreen();
      case 7:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardOverview();
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget buildContent(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const FaIcon(FontAwesomeIcons.bars, size: 18),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/wwg.png', width: 28, height: 28,
                    errorBuilder: (_, __, ___) => Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('WW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('WonWon', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
            ),
      drawer: isDesktop ? null : Drawer(
        backgroundColor: Colors.white,
        child: _buildSidebarContent(context, inDrawer: true),
      ),
      body: Row(
        children: [
          // Desktop sidebar
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: _buildSidebarContent(context, inDrawer: false),
            ),

          // Main Content
          Expanded(child: _getCurrentScreen()),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool inDrawer}) {
    final menuItems = _getMenuItems(context);
    return Column(
      children: [
        // Logo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Image.asset('assets/images/wwg.png', width: 44, height: 44, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('WW', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('WonWon', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    Text('repair_finder'.tr(context), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Admin badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(FontAwesomeIcons.userShield, color: const Color(0xFF64748B), size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text('admin_panel'.tr(context), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Menu items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final isSelected = index == _selectedIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      safeSetState(() => _selectedIndex = index);
                      if (inDrawer) Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          FaIcon(item.icon, size: 15, color: isSelected ? AppConstants.primaryColor : const Color(0xFF64748B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.title, style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppConstants.primaryColor : const Color(0xFF475569),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: Column(
            children: [
              if (_userEmail != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.user, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_userEmail!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authManager.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AdminAuthGate()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.signOutAlt, size: 14),
                  label: Text('logout_button'.tr(context), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (_appVersion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${'version_label'.tr(context)} $_appVersion', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'dashboard_overview'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Cards
          _buildStatsGrid(),
          const SizedBox(height: 32),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 32),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      DashboardStat(
        title: 'total_shops'.tr(context),
        value: _dashboardStats['totalShops']?.toString() ?? '0',
        subtitle: 'n_new_this_week'.tr(context).replaceAll('{count}', '${_dashboardStats['recentShops'] ?? 0}'),
        icon: FontAwesomeIcons.store,
        color: const Color(0xFF3B82F6),
        trend: (_dashboardStats['recentShops'] ?? 0) > 0 ? 'up' : 'neutral',
      ),
      DashboardStat(
        title: 'pending_approvals'.tr(context),
        value: _dashboardStats['pendingShops']?.toString() ?? '0',
        subtitle: 'shops_awaiting_approval'.tr(context),
        icon: FontAwesomeIcons.clock,
        color: const Color(0xFFF59E0B),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'total_users'.tr(context),
        value: _dashboardStats['totalUsers']?.toString() ?? '0',
        subtitle: 'n_new_this_week'.tr(context).replaceAll('{count}', '${_dashboardStats['recentUsers'] ?? 0}'),
        icon: FontAwesomeIcons.users,
        color: const Color(0xFF10B981),
        trend: (_dashboardStats['recentUsers'] ?? 0) > 0 ? 'up' : 'neutral',
      ),
      DashboardStat(
        title: 'open_reports'.tr(context),
        value: _dashboardStats['pendingReports']?.toString() ?? '0',
        subtitle: 'issues_to_resolve'.tr(context),
        icon: FontAwesomeIcons.flag,
        color: const Color(0xFFEF4444),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'average_rating'.tr(context),
        value: (_dashboardStats['averageRating'] ?? 0.0).toStringAsFixed(1),
        subtitle: ((_dashboardStats['totalReviews'] ?? 0) == 1)
            ? 'one_review_from'.tr(context)
            : 'from_n_reviews'.tr(context).replaceAll('{count}', '${_dashboardStats['totalReviews'] ?? 0}'),
        icon: FontAwesomeIcons.star,
        color: const Color(0xFF8B5CF6),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'active_users'.tr(context),
        value: _dashboardStats['activeUsers']?.toString() ?? '0',
        subtitle: 'currently_active'.tr(context),
        icon: FontAwesomeIcons.userCheck,
        color: const Color(0xFF06B6D4),
        trend: 'neutral',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index]),
        );
      },
    );
  }

  Widget _buildStatCard(DashboardStat stat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FaIcon(stat.icon, color: stat.color, size: 20),
                ),
              ),
              const Spacer(),
              if (stat.trend == 'up')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.arrowUp,
                    color: Color(0xFF10B981),
                    size: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stat.value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        title: 'approve_shops'.tr(context),
        subtitle: 'n_pending'.tr(context).replaceAll('{count}', '${_dashboardStats['pendingShops'] ?? 0}'),
        icon: FontAwesomeIcons.check,
        color: const Color(0xFF10B981),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 2;
          });
        },
      ),
      QuickAction(
        title: 'review_reports'.tr(context),
        subtitle: 'n_open'.tr(context).replaceAll('{count}', '${_dashboardStats['pendingReports'] ?? 0}'),
        icon: FontAwesomeIcons.flag,
        color: const Color(0xFFEF4444),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 5;
          });
        },
      ),
      QuickAction(
        title: 'user_management_label'.tr(context),
        subtitle: 'manage_users'.tr(context),
        icon: FontAwesomeIcons.userCog,
        color: const Color(0xFF3B82F6),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 4;
          });
        },
      ),
      QuickAction(
        title: 'view_analytics'.tr(context),
        subtitle: 'detailed_insights'.tr(context),
        icon: FontAwesomeIcons.chartLine,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 1;
          });
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr(context),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
            final aspect = crossAxisCount == 1 ? 3.5 : (crossAxisCount == 2 ? 2.2 : 1.6);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspect,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: actions.length,
              itemBuilder:
                  (context, index) => _buildQuickActionCard(actions[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FaIcon(action.icon, color: action.color, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recent_activity'.tr(context),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
            ),
            title: Text(
              'view_activity_log'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'view_all_activity_events'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF64748B),
            ),
            onTap: () {
              safeSetState(() {
                _selectedIndex = 6;
              });
            },
          ),
        ),
      ],
    );
  }
}

class AdminMenuItem {
  final String title;
  final IconData icon;
  final String route;

  AdminMenuItem({required this.title, required this.icon, required this.route});
}

class DashboardStat {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;

  DashboardStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
