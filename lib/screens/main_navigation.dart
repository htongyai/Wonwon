import 'package:flutter/material.dart';
import 'package:wonwonw2/screens/home_screen.dart';
import 'package:wonwonw2/screens/map_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/profile_screen.dart';
import 'package:wonwonw2/screens/desktop_home_screen.dart';
import 'package:wonwonw2/screens/desktop_map_screen.dart';
import 'package:wonwonw2/screens/desktop_saved_locations_screen.dart';
import 'package:wonwonw2/screens/desktop_profile_screen.dart';
import 'package:wonwonw2/screens/admin_dashboard_main_screen.dart';
import 'package:wonwonw2/screens/forum_screen.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/custom_navigation_bar.dart';
import 'package:wonwonw2/widgets/desktop_navigation.dart';
import 'package:wonwonw2/services/auth_manager.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/notification_overlay.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final Widget child;

  const MainNavigation({Key? key, this.initialIndex = 0, required this.child})
    : super(key: key);

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> with AuthStateMixin {
  late int _currentIndex;
  bool _isAdmin = false;
  bool _isLoading = true;
  final _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    print('=== MAIN NAVIGATION INIT ===');
    print(
      'MainNavigation: initState called with initialIndex: ${widget.initialIndex}',
    );
    _currentIndex = widget.initialIndex;
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _authManager.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void onAuthStateChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      // User logged out, reset admin status
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } else {
      // User logged in, check admin status
      _checkAdminStatus();
    }
  }

  @override
  void onUserChanged(user) {
    if (user != null) {
      _checkAdminStatus();
    }
  }

  void onTap(int index) {
    // Check if user is trying to access admin routes
    if (index >= 5 && !_isAdmin) {
      // Show error message for non-admin users trying to access admin routes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'access_denied'.tr(context) +
                '. ' +
                'admin_privileges_required'.tr(context),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle admin dashboard separately (opens as new screen)
    if (index == 5 && _isAdmin) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AdminDashboardMainScreen(),
        ),
      );
      return;
    }

    // For regular tabs, just update the current index
    setState(() {
      _currentIndex = index;
    });
  }

  // Static method to find the MainNavigationState
  static MainNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationState>();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ResponsiveSize if needed
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    // Use desktop navigation for desktop screens
    if (ResponsiveSize.shouldShowDesktopLayout(context)) {
      return NotificationOverlay(
        child: DesktopNavigation(
          currentIndex: _currentIndex,
          onTap: onTap,
          onSidebarCollapsed: (collapsed) {
            // Sidebar collapse state handled by DesktopNavigation
          },
          child: _buildCurrentScreen(),
        ),
      );
    }

    // Use mobile navigation for mobile/tablet screens
    return NotificationOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildCurrentScreen(),
        bottomNavigationBar: CustomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // Show loading screen while checking admin status
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    // For desktop, use desktop-specific screens when available
    if (ResponsiveSize.shouldShowDesktopLayout(context)) {
      switch (_currentIndex) {
        case 0:
          return const DesktopHomeScreen();
        case 1:
          return const DesktopMapScreen();
        case 2:
          return const DesktopSavedLocationsScreen();
        case 3:
          return const DesktopProfileScreen();
        case 4:
          return const ForumScreen();
        default:
          return const HomeScreen();
      }
    }

    // For mobile/tablet, use mobile-specific screens
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const SavedLocationsScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const ForumScreen();
      default:
        return const HomeScreen();
    }
  }
}
