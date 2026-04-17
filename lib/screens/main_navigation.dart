import 'package:flutter/material.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:wonwonw2/screens/home_screen.dart';
import 'package:wonwonw2/screens/map_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/profile_screen.dart';
import 'package:wonwonw2/screens/forum_screen.dart';
import 'package:shared/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/widgets/notification_overlay.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared/utils/app_reload.dart';

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
  final _pageStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  static MainNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationState>();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.shouldShowDesktopLayout(width);

    return NotificationOverlay(
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: PageStorage(
              bucket: _pageStorageBucket,
              child: _buildCurrentScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset('assets/images/wwg.png', height: 36),
                const SizedBox(width: 10),
                const Text(
                  'WonWon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF443616),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._buildNavItems(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLangButton('EN', const Locale('en')),
                const SizedBox(width: 8),
                _buildLangButton('TH', const Locale('th')),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems() {
    final items = [
      _NavItem(icon: FontAwesomeIcons.house, label: 'home'.tr(context), index: 0),
      _NavItem(icon: FontAwesomeIcons.map, label: 'search'.tr(context), index: 1),
      _NavItem(icon: FontAwesomeIcons.bookmark, label: 'saved'.tr(context), index: 2),
      _NavItem(icon: FontAwesomeIcons.comments, label: 'forum'.tr(context), index: 4),
      _NavItem(icon: FontAwesomeIcons.user, label: 'profile'.tr(context), index: 3),
    ];

    return items.map((item) {
      final isSelected = _currentIndex == item.index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(item.index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  FaIcon(
                    item.icon,
                    size: 18,
                    color: isSelected ? AppConstants.primaryColor : const Color(0xFF757575),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppConstants.primaryColor : const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLangButton(String label, Locale locale) {
    return FutureBuilder<Locale>(
      future: AppLocalizationsService.getLocale(),
      builder: (context, snapshot) {
        final currentLocale = snapshot.data ?? const Locale('th');
        final isSelected = currentLocale.languageCode == locale.languageCode;

        return TextButton(
          onPressed: () async {
            await AppLocalizationsService.setLocale(locale.languageCode);
            if (kIsWeb) {
              reload();
            }
            if (mounted) setState(() {});
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: isSelected
                ? AppConstants.primaryColor.withValues(alpha: 0.1)
                : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppConstants.primaryColor : Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.house, 'home'.tr(context), 0)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.magnifyingGlass, 'search'.tr(context), 1)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.bookmark, 'saved'.tr(context), 2)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.comments, 'forum'.tr(context), 4)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.user, 'profile'.tr(context), 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 20,
            color: isSelected ? AppConstants.primaryColor : const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppConstants.primaryColor : const Color(0xFFBDBDBD),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
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

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  _NavItem({required this.icon, required this.label, required this.index});
}
