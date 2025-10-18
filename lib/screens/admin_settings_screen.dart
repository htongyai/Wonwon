import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:wonwonw2/services/auth_manager.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/screens/main_navigation.dart';

class AdminSettingsScreen extends OptimizedScreen {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends OptimizedLoadingScreen<AdminSettingsScreen>
    with AuthStateMixin {
  final AuthManager _authManager = AuthManager();

  @override
  void onAuthStateChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      // User logged out, redirect to login
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void onUserChanged(user) {
    // Admin settings don't need special user change handling
  }

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Admin Settings',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage system settings and configurations',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          // Settings Sections
          _buildSettingsSection('Admin Dashboard', [
            _buildSettingItem(
              'Shop Management',
              'Manage repair shops, approve/unapprove listings',
              FontAwesomeIcons.store,
              const Color(0xFF3B82F6),
              () => _navigateToShopManagement(),
            ),
            _buildSettingItem(
              'User Management',
              'Manage users, roles, and permissions',
              FontAwesomeIcons.users,
              const Color(0xFF10B981),
              () => _navigateToUserManagement(),
            ),
            _buildSettingItem(
              'Reports & Issues',
              'View and manage user reports and issues',
              FontAwesomeIcons.flag,
              const Color(0xFFEF4444),
              () => _navigateToReports(),
            ),
          ]),

          const SizedBox(height: 32),

          _buildSettingsSection('Account', [
            _buildSettingItem(
              'Logout',
              'Sign out of admin account',
              FontAwesomeIcons.signOut,
              const Color(0xFF64748B),
              () => _showLogoutDialog(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children:
                items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      item,
                      if (index < items.length - 1)
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: FaIcon(icon, color: color, size: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToShopManagement() {
    Navigator.of(context).pop(); // Close settings
    // The parent AdminDashboardMainScreen will handle navigation to shop management
  }

  void _navigateToUserManagement() {
    Navigator.of(context).pop(); // Close settings
    // The parent AdminDashboardMainScreen will handle navigation to user management
  }

  void _navigateToReports() {
    Navigator.of(context).pop(); // Close settings
    // The parent AdminDashboardMainScreen will handle navigation to reports
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.signOut,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Logout'),
              ],
            ),
            content: Text(
              'Are you sure you want to logout from the admin dashboard?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authManager.logout();
      // Navigate back to main navigation and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(child: SizedBox()),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
