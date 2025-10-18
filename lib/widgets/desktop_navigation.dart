import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/utils/icon_helper.dart';
import 'package:wonwonw2/screens/settings_screen.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonwonw2/widgets/notification_icon.dart';
import 'package:wonwonw2/services/notification_controller.dart';

class DesktopNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Widget child;
  final Function(bool)? onSidebarCollapsed;

  const DesktopNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.child,
    this.onSidebarCollapsed,
  }) : super(key: key);

  @override
  State<DesktopNavigation> createState() => _DesktopNavigationState();
}

class _DesktopNavigationState extends State<DesktopNavigation> {
  static const double sidebarWidth = 280.0;
  static const double collapsedSidebarWidth = 80.0;
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? collapsedSidebarWidth : sidebarWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // WonWon Logo
                if (!_isSidebarCollapsed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
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
                        // Collapse button
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSidebarCollapsed = !_isSidebarCollapsed;
                            });
                            widget.onSidebarCollapsed?.call(
                              _isSidebarCollapsed,
                            );
                          },
                          icon: Icon(
                            Icons.menu,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Collapsed logo
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'WW',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSidebarCollapsed = !_isSidebarCollapsed;
                            });
                            widget.onSidebarCollapsed?.call(
                              _isSidebarCollapsed,
                            );
                          },
                          icon: Icon(
                            Icons.menu_open,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Header Section
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
                          FontAwesomeIcons.home,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Main App',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'User Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(
                        context,
                        0,
                        FontAwesomeIcons.house,
                        'home',
                        _isSidebarCollapsed,
                      ),
                      _buildNavItem(
                        context,
                        1,
                        FontAwesomeIcons.mapLocationDot,
                        'search',
                        _isSidebarCollapsed,
                      ),
                      _buildNavItem(
                        context,
                        2,
                        FontAwesomeIcons.bookmark,
                        'saved',
                        _isSidebarCollapsed,
                      ),
                      _buildNavItem(
                        context,
                        3,
                        FontAwesomeIcons.user,
                        'profile',
                        _isSidebarCollapsed,
                      ),
                      _buildNavItem(
                        context,
                        4,
                        FontAwesomeIcons.comments,
                        'forum',
                        _isSidebarCollapsed,
                      ),
                    ],
                  ),
                ),

                // Border separator between navigation and footer
                Container(height: 1, color: Colors.grey.withOpacity(0.2)),

                // Footer with language selector
                if (!_isSidebarCollapsed) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildLanguageSelector(context),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top title bar with login/profile circle
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Page title (will be set by individual screens)
                      Expanded(
                        child: Text(
                          _getPageTitle(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                      ),

                      // Notification icon (only when logged in)
                      FutureBuilder<User?>(
                        future: Future.value(FirebaseAuth.instance.currentUser),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user != null) {
                            return Row(
                              children: [
                                NotificationIcon(
                                  onTap: () {
                                    NotificationController().openSidebar();
                                  },
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Login/Profile circle
                      _buildLoginProfileCircle(context),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isCollapsed,
  ) {
    final isSelected = widget.currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isSelected
                      ? Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                      )
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppConstants.primaryColor
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FaIcon(
                      icon,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                      size: 16,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return FutureBuilder<Locale>(
      future: AppLocalizationsService.getLocale(),
      builder: (context, snapshot) {
        final currentLocale = snapshot.data ?? const Locale('en');
        final isEnglish = currentLocale.languageCode == 'en';

        return Row(
          children: [
            // English button
            GestureDetector(
              onTap: () async {
                await AppLocalizationsService.setLocale('en');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isEnglish
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isEnglish
                            ? AppConstants.primaryColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.flag,
                      size: 16,
                      color:
                          isEnglish
                              ? AppConstants.primaryColor
                              : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EN',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight:
                            isEnglish ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isEnglish
                                ? AppConstants.primaryColor
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Thai button
            GestureDetector(
              onTap: () async {
                await AppLocalizationsService.setLocale('th');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      !isEnglish
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        !isEnglish
                            ? AppConstants.primaryColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.flag,
                      size: 16,
                      color:
                          !isEnglish
                              ? AppConstants.primaryColor
                              : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ไทย',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight:
                            !isEnglish ? FontWeight.w600 : FontWeight.w500,
                        color:
                            !isEnglish
                                ? AppConstants.primaryColor
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Feedback icon
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: IconHelper.getSafeIcon(
                FontAwesomeIcons.comment,
                Icons.comment,
                color: AppConstants.primaryColor,
                size: 16,
              ),
              onPressed: () {
                _launchFeedbackForm();
              },
            ),
            const SizedBox(width: 8),
            // Settings icon
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: IconHelper.getSafeIcon(
                FontAwesomeIcons.gear,
                Icons.settings,
                color: AppConstants.darkColor,
                size: 16,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _launchFeedbackForm() async {
    const url = 'https://forms.gle/your-feedback-form-url';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback: show a dialog or snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open feedback form'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get page title based on current index
  String _getPageTitle(BuildContext context) {
    switch (widget.currentIndex) {
      case 0:
        return 'home'.tr(context);
      case 1:
        return 'search'.tr(context);
      case 2:
        return 'saved_locations'.tr(context);
      case 3:
        return 'profile'.tr(context);
      case 4:
        return 'forum'.tr(context);
      case 5:
        return 'dashboard'.tr(context);
      case 6:
        return 'manage_shops'.tr(context);
      case 7:
        return 'manage_users'.tr(context);
      case 8:
        return 'unapprove_pages'.tr(context);
      case 9:
        return 'reports'.tr(context);
      default:
        return 'home'.tr(context);
    }
  }

  // Build login/profile circle
  Widget _buildLoginProfileCircle(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user != null) {
          // User is logged in - show profile circle
          return GestureDetector(
            onTap: () {
              // Navigate to profile or show profile menu
              widget.onTap(3); // Navigate to profile page
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName![0].toUpperCase()
                      : user.email?.isNotEmpty == true
                      ? user.email![0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        } else {
          // User is not logged in - show login text button
          return GestureDetector(
            onTap: () {
              // Navigate to login page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Log In',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
