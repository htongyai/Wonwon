import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:wonwonw2/services/auth_manager.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/screens/admin_analytics_screen.dart';
import 'package:wonwonw2/screens/admin_shop_management_screen.dart';
import 'package:wonwonw2/screens/admin_user_management_screen.dart';
import 'package:wonwonw2/screens/admin_reports_management_screen.dart';
import 'package:wonwonw2/screens/activity_log_screen.dart';
import 'package:wonwonw2/screens/admin_settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wonwonw2/utils/app_logger.dart';

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

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      title: 'Dashboard',
      icon: FontAwesomeIcons.chartLine,
      route: '/admin/dashboard',
    ),
    AdminMenuItem(
      title: 'Analytics',
      icon: FontAwesomeIcons.chartPie,
      route: '/admin/analytics',
    ),
    AdminMenuItem(
      title: 'Shop Management',
      icon: FontAwesomeIcons.store,
      route: '/admin/shops',
    ),
    AdminMenuItem(
      title: 'User Management',
      icon: FontAwesomeIcons.users,
      route: '/admin/users',
    ),
    AdminMenuItem(
      title: 'Reports & Issues',
      icon: FontAwesomeIcons.flag,
      route: '/admin/reports',
    ),
    AdminMenuItem(
      title: 'Activity Log',
      icon: FontAwesomeIcons.clockRotateLeft,
      route: '/admin/activity-log',
    ),
    AdminMenuItem(
      title: 'Settings',
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
    if (!isLoggedIn) {
      // User logged out, redirect to login
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      // User logged in, check admin status
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

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Fetch all collections in parallel
    final futures = await Future.wait([
      _firestore.collection('shops').get(),
      _firestore.collection('users').get(),
      _firestore.collection('report').get(),
      _firestore.collection('reviews').get(),
    ]);

    final shopsSnapshot = futures[0];
    final usersSnapshot = futures[1];
    final reportsSnapshot = futures[2];
    final reviewsSnapshot = futures[3];

    // Process shops data
    final totalShops = shopsSnapshot.docs.length;
    final approvedShops =
        shopsSnapshot.docs
            .where((doc) => doc.data()['approved'] == true)
            .length;
    final pendingShops = totalShops - approvedShops;
    final recentShops =
        shopsSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    // Process users data
    final totalUsers = usersSnapshot.docs.length;
    final activeUsers =
        usersSnapshot.docs
            .where((doc) => doc.data()['status'] == 'active')
            .length;
    final recentUsers =
        usersSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    // Process reports data
    final totalReports = reportsSnapshot.docs.length;
    final pendingReports =
        reportsSnapshot.docs
            .where((doc) => doc.data()['resolved'] != true)
            .length;
    final recentReports =
        reportsSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isAfter(sevenDaysAgo);
          }
          return false;
        }).length;

    // Process reviews data
    final totalReviews = reviewsSnapshot.docs.length;
    double averageRating = 0.0;
    if (totalReviews > 0) {
      double totalRating = 0.0;
      for (var doc in reviewsSnapshot.docs) {
        final rating = doc.data()['rating'] ?? 0.0;
        totalRating += rating;
      }
      averageRating = totalRating / totalReviews;
    }

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
      'totalReviews': totalReviews,
      'averageRating': averageRating,
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
        return const AdminUserManagementScreen();
      case 4:
        return const AdminReportsManagementScreen();
      case 5:
        return const ActivityLogScreen();
      case 6:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardOverview();
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // WonWon Logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/wwg.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to text logo if image fails to load
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'WW',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // App Name and Tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'WonWon',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Repair Finder',
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
                ),

                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.userShield,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Management Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = index == _selectedIndex;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              safeSetState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppConstants.primaryColor.withOpacity(
                                          0.1,
                                        )
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  FaIcon(
                                    item.icon,
                                    size: 16,
                                    color:
                                        isSelected
                                            ? AppConstants.primaryColor
                                            : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? AppConstants.primaryColor
                                              : const Color(0xFF475569),
                                    ),
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

                // User Info and Logout Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Username
                      if (_userEmail != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.user,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _userEmail!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _authManager.logout();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/');
                            }
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.signOutAlt,
                            size: 16,
                          ),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF475569),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // App Version
                      if (_appVersion.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Version $_appVersion',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(child: _getCurrentScreen()),
        ],
      ),
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
                  'Dashboard Overview',
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
        title: 'Total Shops',
        value: _dashboardStats['totalShops']?.toString() ?? '0',
        subtitle: '${_dashboardStats['recentShops'] ?? 0} new this week',
        icon: FontAwesomeIcons.store,
        color: const Color(0xFF3B82F6),
        trend: (_dashboardStats['recentShops'] ?? 0) > 0 ? 'up' : 'neutral',
      ),
      DashboardStat(
        title: 'Pending Approvals',
        value: _dashboardStats['pendingShops']?.toString() ?? '0',
        subtitle: 'Shops awaiting approval',
        icon: FontAwesomeIcons.clock,
        color: const Color(0xFFF59E0B),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'Total Users',
        value: _dashboardStats['totalUsers']?.toString() ?? '0',
        subtitle: '${_dashboardStats['recentUsers'] ?? 0} new this week',
        icon: FontAwesomeIcons.users,
        color: const Color(0xFF10B981),
        trend: (_dashboardStats['recentUsers'] ?? 0) > 0 ? 'up' : 'neutral',
      ),
      DashboardStat(
        title: 'Open Reports',
        value: _dashboardStats['pendingReports']?.toString() ?? '0',
        subtitle: 'Issues to resolve',
        icon: FontAwesomeIcons.flag,
        color: const Color(0xFFEF4444),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'Average Rating',
        value: (_dashboardStats['averageRating'] ?? 0.0).toStringAsFixed(1),
        subtitle: 'From ${_dashboardStats['totalReviews'] ?? 0} reviews',
        icon: FontAwesomeIcons.star,
        color: const Color(0xFF8B5CF6),
        trend: 'neutral',
      ),
      DashboardStat(
        title: 'Active Users',
        value: _dashboardStats['activeUsers']?.toString() ?? '0',
        subtitle: 'Currently active',
        icon: FontAwesomeIcons.userCheck,
        color: const Color(0xFF06B6D4),
        trend: 'neutral',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
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
            color: Colors.black.withOpacity(0.02),
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
                  color: stat.color.withOpacity(0.1),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
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
        title: 'Approve Shops',
        subtitle: '${_dashboardStats['pendingShops'] ?? 0} pending',
        icon: FontAwesomeIcons.check,
        color: const Color(0xFF10B981),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 2; // Shop Management
          });
        },
      ),
      QuickAction(
        title: 'Review Reports',
        subtitle: '${_dashboardStats['pendingReports'] ?? 0} open',
        icon: FontAwesomeIcons.flag,
        color: const Color(0xFFEF4444),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 4; // Reports Management
          });
        },
      ),
      QuickAction(
        title: 'User Management',
        subtitle: 'Manage user accounts',
        icon: FontAwesomeIcons.userCog,
        color: const Color(0xFF3B82F6),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 3; // User Management
          });
        },
      ),
      QuickAction(
        title: 'View Analytics',
        subtitle: 'Detailed insights',
        icon: FontAwesomeIcons.chartLine,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          safeSetState(() {
            _selectedIndex = 1; // Analytics
          });
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: actions.length,
          itemBuilder:
              (context, index) => _buildQuickActionCard(actions[index]),
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
                color: Colors.black.withOpacity(0.02),
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
                  color: action.color.withOpacity(0.1),
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
          'Recent Activity',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New shop registration',
                'A new repair shop has been submitted for approval',
                FontAwesomeIcons.store,
                const Color(0xFF3B82F6),
                '2 hours ago',
              ),
              const Divider(height: 32),
              _buildActivityItem(
                'User report submitted',
                'A user has reported an issue with a shop listing',
                FontAwesomeIcons.flag,
                const Color(0xFFEF4444),
                '4 hours ago',
              ),
              const Divider(height: 32),
              _buildActivityItem(
                'New user registration',
                '3 new users have joined the platform',
                FontAwesomeIcons.userPlus,
                const Color(0xFF10B981),
                '6 hours ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: FaIcon(icon, color: color, size: 16)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
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
