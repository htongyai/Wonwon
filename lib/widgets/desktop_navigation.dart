import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/icon_helper.dart';
import 'package:wonwonw2/screens/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    // For now, we'll check if the user is logged in as admin
    // You can implement your own admin check logic here
    final user = FirebaseAuth.instance.currentUser;
    print('Checking admin status for user: ${user?.uid}');

    if (user != null) {
      // Check if user has admin role in Firestore
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          print('User data: $userData');
          final isAdmin =
              userData?['role'] == 'admin' || userData?['isAdmin'] == true;
          print('Is admin: $isAdmin');
          setState(() {
            _isAdmin = isAdmin;
          });
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error checking admin status: $e');
      }
    } else {
      print('No user logged in');
    }

    // Temporary: For testing, you can uncomment the line below to always show admin
    setState(() {
      _isAdmin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? collapsedSidebarWidth : sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with logo and collapse button
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!_isSidebarCollapsed) ...[
                        // Logo and name
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/wwg.png',
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'WonWon',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      // Collapse/Expand button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                          widget.onSidebarCollapsed?.call(_isSidebarCollapsed);
                        },
                        icon: Icon(
                          _isSidebarCollapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          color: AppConstants.primaryColor,
                        ),
                      ),
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
                      // Admin section
                      if (_isAdmin) ...[
                        const SizedBox(height: 20),
                        // Admin heading
                        if (!_isSidebarCollapsed)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'ADMIN',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        // Divider
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        // Dashboard option
                        _buildNavItem(
                          context,
                          4,
                          FontAwesomeIcons.chartLine,
                          'dashboard',
                          _isSidebarCollapsed,
                        ),
                        // Manage Shops option
                        _buildNavItem(
                          context,
                          5,
                          FontAwesomeIcons.store,
                          'manage_shops',
                          _isSidebarCollapsed,
                        ),
                        // Manage Users option
                        _buildNavItem(
                          context,
                          6,
                          FontAwesomeIcons.users,
                          'manage_users',
                          _isSidebarCollapsed,
                        ),
                        // Unapprove Pages option
                        _buildNavItem(
                          context,
                          7,
                          FontAwesomeIcons.clock,
                          'unapprove_pages',
                          _isSidebarCollapsed,
                        ),
                        // Reports option
                        _buildNavItem(
                          context,
                          8,
                          FontAwesomeIcons.chartBar,
                          'reports',
                          _isSidebarCollapsed,
                        ),
                      ],
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
          Expanded(child: widget.child),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 16 : 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppConstants.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                FaIcon(
                  icon,
                  color: isSelected ? Colors.white : AppConstants.primaryColor,
                  size: 20,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppConstants.darkColor,
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
                    Image.asset(
                      'assets/images/flag_us.png',
                      width: 20,
                      height: 15,
                      fit: BoxFit.cover,
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
                    Image.asset(
                      'assets/images/flag_th.png',
                      width: 20,
                      height: 15,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TH',
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
}
