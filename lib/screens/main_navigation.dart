import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/home_screen.dart';
import 'package:wonwonw2/screens/desktop_home_screen.dart';
import 'package:wonwonw2/screens/desktop_map_screen.dart';
import 'package:wonwonw2/screens/map_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/desktop_saved_locations_screen.dart';
import 'package:wonwonw2/screens/profile_screen.dart';
import 'package:wonwonw2/screens/admin_dashboard_screen.dart';
import 'package:wonwonw2/screens/admin_manage_shops_screen.dart';
import 'package:wonwonw2/screens/admin_manage_users_screen.dart';
import 'package:wonwonw2/screens/admin_unapprove_pages_screen.dart';
import 'package:wonwonw2/screens/admin_reports_screen.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/custom_navigation_bar.dart';
import 'package:wonwonw2/widgets/desktop_navigation.dart';
import 'package:go_router/go_router.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final Widget child;

  const MainNavigation({Key? key, this.initialIndex = 0, required this.child})
    : super(key: key);

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  bool _isMainSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void onTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Update the URL based on the selected tab
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/saved');
        break;
      case 3:
        context.go('/profile');
        break;
      case 4:
        context.go('/admin/dashboard');
        break;
      case 5:
        context.go('/admin/manage-shops');
        break;
      case 6:
        context.go('/admin/manage-users');
        break;
      case 7:
        context.go('/admin/unapprove-pages');
        break;
      case 8:
        context.go('/admin/reports');
        break;
    }
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
    if (ResponsiveSize.shouldShowDesktopLayout()) {
      return DesktopNavigation(
        currentIndex: _currentIndex,
        onTap: onTap,
        onSidebarCollapsed: (collapsed) {
          setState(() {
            _isMainSidebarCollapsed = collapsed;
          });
        },
        child: _buildCurrentScreen(),
      );
    }

    // Use mobile navigation for mobile/tablet screens
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTap,
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // For desktop, use desktop-specific screens when available
    if (ResponsiveSize.shouldShowDesktopLayout()) {
      switch (_currentIndex) {
        case 0:
          return const DesktopHomeScreen();
        case 1:
          return const DesktopMapScreen();
        case 2:
          return const DesktopSavedLocationsScreen();
        case 3:
          return const ProfileScreen();
        case 4:
          return const AdminDashboardScreen();
        case 5:
          return const AdminManageShopsScreen();
        case 6:
          return const AdminManageUsersScreen();
        case 7:
          return const AdminUnapprovePagesScreen();
        case 8:
          return const AdminReportsScreen();
        default:
          return const HomeScreen();
      }
    }

    // For mobile/tablet, use the child widget passed from router
    return widget.child;
  }
}
