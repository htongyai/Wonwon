import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wonwonw2/constants/design_tokens.dart';
import 'package:wonwonw2/models/user.dart' as app_user;
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/admin_dashboard_main_screen.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class TabletProfileScreen extends StatefulWidget {
  const TabletProfileScreen({Key? key}) : super(key: key);

  @override
  State<TabletProfileScreen> createState() => _TabletProfileScreenState();
}

class _TabletProfileScreenState extends State<TabletProfileScreen>
    with WidgetDisposalMixin<TabletProfileScreen> {
  firebase_auth.User? _user;
  app_user.User? _userData;
  bool _loading = true;
  bool _isAdmin = false;
  bool _isSidebarCollapsed = false;

  @override
  void onInitState() {
    super.onInitState();
    _user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _setupUserDataListener(_user!.uid);
      _fetchAdminStatus(_user!.uid);
    }

    // Use the mixin's automatic subscription management
    listenToStream(firebase_auth.FirebaseAuth.instance.authStateChanges(), (
      user,
    ) {
      setState(() {
        _user = user;
        _loading = false;
      });
      if (user != null) {
        _setupUserDataListener(user.uid);
        _fetchAdminStatus(user.uid);
      } else {
        setState(() {
          _isAdmin = false;
          _userData = null;
        });
      }
    });
  }

  void _setupUserDataListener(String uid) {
    // Use the mixin's automatic subscription management
    listenToStream(
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      (snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _userData = app_user.User.fromMap(snapshot.data()!, snapshot.id);
            _loading = false;
          });
        }
      },
      onError: (error) {
        appLog('Error listening to user data: $error');
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _fetchAdminStatus(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _isAdmin = doc.data()?['isAdmin'] == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left sidebar with profile info (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 0 : 300,
            child:
                _isSidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildTabletSidebar(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with toggle button
                _buildTabletHeader(),
                // Profile content
                Expanded(child: _buildTabletProfileContent()),
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
                  'Profile Info',
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
          // Profile info
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              children: [
                // User avatar and basic info
                _buildUserInfoCard(),
                const SizedBox(height: DesignTokens.spacingLg),
                // Quick stats
                _buildQuickStatsCard(),
                const SizedBox(height: DesignTokens.spacingLg),
                // Quick actions
                _buildQuickActionsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppConstants.primaryColor,
              backgroundImage:
                  _userData?.profileImageUrl != null
                      ? NetworkImage(_userData!.profileImageUrl!)
                      : null,
              child:
                  _userData?.profileImageUrl == null
                      ? Text(
                        _userData?.name?.isNotEmpty == true
                            ? _userData!.name![0].toUpperCase()
                            : _user!.email![0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeXl,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              _userData?.name ?? 'User',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              _user!.email!,
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeSm,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_isAdmin) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingSm,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  'Member since ${_formatDate(_user!.metadata.creationTime)}',
                  style: GoogleFonts.inter(fontSize: DesignTokens.fontSizeSm),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  'Last login: ${_formatDate(_user!.metadata.lastSignInTime)}',
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

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            _buildQuickActionButton('Edit Profile', Icons.edit, () {
              // Edit profile logic
            }),
            _buildQuickActionButton('Settings', Icons.settings, () {
              // Settings logic
            }),
            if (_isAdmin)
              _buildQuickActionButton(
                'Admin Panel',
                Icons.admin_panel_settings,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardMainScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppConstants.primaryColor),
                const SizedBox(width: DesignTokens.spacingSm),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: DesignTokens.fontSizeSm),
                ),
              ],
            ),
          ),
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
            'Profile',
            style: GoogleFonts.inter(
              fontSize: DesignTokens.fontSizeXl,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const Spacer(),
          // Logout button
          TextButton.icon(
            onPressed: () {
              _showLogoutDialog();
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletProfileContent() {
    return SingleChildScrollView(
      padding: DesignTokens.getResponsivePadding(ResponsiveSize.screenWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile details
          _buildProfileDetailsCard(),
          const SizedBox(height: DesignTokens.spacingLg),
          // Repair history
          _buildRepairHistoryCard(),
          const SizedBox(height: DesignTokens.spacingLg),
          // Account settings
          _buildAccountSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Details',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            _buildDetailRow('Name', _userData?.name ?? 'Not set'),
            _buildDetailRow('Email', _user!.email!),
            _buildDetailRow(
              'Phone',
              'Not set',
            ), // User model doesn't have phoneNumber field
            _buildDetailRow(
              'Address',
              'Not set',
            ), // User model doesn't have address field
            _buildDetailRow(
              'Join Date',
              _formatDate(_user!.metadata.creationTime),
            ),
            _buildDetailRow(
              'Last Login',
              _formatDate(_user!.metadata.lastSignInTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeSm,
                fontWeight: DesignTokens.fontWeightMedium,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: DesignTokens.fontSizeSm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair History',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            // This would be populated with actual repair history
            Center(
              child: Column(
                children: [
                  Icon(Icons.build, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Text(
                    'No repair history yet',
                    style: GoogleFonts.inter(
                      fontSize: DesignTokens.fontSizeMd,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    'Your repair records will appear here',
                    style: GoogleFonts.inter(
                      fontSize: DesignTokens.fontSizeSm,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: GoogleFonts.inter(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            _buildSettingItem(
              'Change Password',
              'Update your account password',
              Icons.lock,
              () {
                // Change password logic
              },
            ),
            _buildSettingItem(
              'Privacy Settings',
              'Manage your privacy preferences',
              Icons.privacy_tip,
              () {
                // Privacy settings logic
              },
            ),
            _buildSettingItem(
              'Notifications',
              'Configure notification preferences',
              Icons.notifications,
              () {
                // Notification settings logic
              },
            ),
            _buildSettingItem(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              () {
                _showDeleteAccountDialog();
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isDestructive
                          ? Colors.red[600]
                          : AppConstants.primaryColor,
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeMd,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: isDestructive ? Colors.red[600] : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: DesignTokens.fontSizeSm,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
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
              'Please log in to view your profile',
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await firebase_auth.FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Delete account logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          ),
    );
  }
}
