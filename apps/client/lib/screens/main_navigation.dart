import 'package:flutter/material.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:wonwon_client/screens/home_screen.dart';
import 'package:wonwon_client/screens/map_screen.dart';
import 'package:wonwon_client/screens/saved_locations_screen.dart';
import 'package:wonwon_client/screens/profile_screen.dart';
import 'package:wonwon_client/screens/forum_screen.dart';
import 'package:shared/mixins/auth_state_mixin.dart';
import 'package:wonwon_client/widgets/notification_overlay.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/localization/app_localizations.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/services/saved_shop_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/services/analytics_service.dart';

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
  Locale? _currentLocale;
  int _savedCount = 0;
  final SavedShopService _savedShopService = SavedShopService();

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    SavedLocationsScreen(),
    ProfileScreen(),
    ForumScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadLocale();
    _refreshSavedCount();
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh saved count when user navigates away from the Saved tab so
    // the badge reflects fresh state.
    _refreshSavedCount();
  }

  Future<void> _refreshSavedCount() async {
    try {
      final ids = await _savedShopService.getSavedShopIds();
      if (mounted) setState(() => _savedCount = ids.length);
    } catch (_) {
      // Silently ignore — badge just won't appear.
    }
  }

  /// Public-facing wrapper so child screens (e.g. the saved locations
  /// list) can push the latest count into the bottom-nav badge after
  /// they finish any cleanup work. Without this, the badge can drift
  /// out of sync with the list — tester reported seeing a positive
  /// count alongside an empty list.
  Future<void> refreshSavedCount() => _refreshSavedCount();

  Future<void> _loadLocale() async {
    final locale = await AppLocalizationsService.getLocale();
    if (mounted) setState(() => _currentLocale = locale);
  }

  void onTap(int index) {
    const tabNames = ['home', 'map', 'saved', 'profile', 'forum'];
    AnalyticsService.safeLog(() => AnalyticsService().logTabChange(tabNames[index]));
    setState(() {
      _currentIndex = index;
    });
    // Refresh the saved count whenever the user returns to a non-saved tab,
    // so changes made on the saved screen are reflected.
    if (index != 2) _refreshSavedCount();
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Desktop sidebar
          _buildDesktopSidebar(),
          // Main content
          Expanded(
            child: PageStorage(
              bucket: _pageStorageBucket,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset('assets/images/wwg.png', height: 36),
                const SizedBox(width: 10),
                Text(
                  'WonWon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Nav items
          ..._buildNavItems(),
          const Spacer(),
          // Language toggle at bottom
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

    final theme = Theme.of(context);
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
                    color: isSelected
                        ? AppConstants.primaryColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isSelected = (_currentLocale ?? const Locale('th')).languageCode == locale.languageCode;

    return TextButton(
      onPressed: () async {
        await AppLocalizationsService.setLocale(locale.languageCode);
        if (mounted) {
          setState(() => _currentLocale = locale);
        }
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
          color: isSelected
              ? AppConstants.primaryColor
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.house, 'home'.tr(context), 0)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.magnifyingGlass, 'search'.tr(context), 1)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.bookmark, 'saved'.tr(context), 2, badge: _savedCount)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.comments, 'forum'.tr(context), 4)),
              Expanded(child: _buildNavBarItem(FontAwesomeIcons.user, 'profile'.tr(context), 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index, {int badge = 0}) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 3,
              width: isSelected ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                FaIcon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : inactiveColor,
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: theme.cardColor, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppConstants.primaryColor : inactiveColor,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  _NavItem({required this.icon, required this.label, required this.index});
}
