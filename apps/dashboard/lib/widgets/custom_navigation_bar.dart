import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/design_tokens.dart';
import 'package:shared/utils/responsive_size.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final navBarHeight = DesignTokens.getResponsiveNavBarHeight(screenHeight);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navBarHeight,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  index: 0,
                  icon: FontAwesomeIcons.house,
                  labelKey: 'home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  index: 1,
                  icon: FontAwesomeIcons.mapLocationDot,
                  labelKey: 'search',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  index: 2,
                  icon: FontAwesomeIcons.bookmark,
                  labelKey: 'saved_locations',
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  index: 3,
                  icon: FontAwesomeIcons.user,
                  labelKey: 'profile',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              Expanded(
                child: _NavItem(
                  index: 4,
                  icon: FontAwesomeIcons.comments,
                  labelKey: 'forum',
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String labelKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.labelKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pillWidth;
  late Animation<double> _pillOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _setupAnimations();
    if (widget.isSelected) {
      _controller.value = 1;
    }
  }

  void _setupAnimations() {
    _pillWidth = Tween<double>(begin: 0, end: 64).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _pillOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppConstants.primaryColor;
    final unselectedColor = Colors.grey.shade600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: _pillWidth.value.clamp(32, 64),
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedColor
                        .withValues(alpha: 0.12 * _pillOpacity.value),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: FaIcon(
                widget.icon,
                size: 22,
                color: widget.isSelected ? selectedColor : unselectedColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.labelKey.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight:
                    widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                color: widget.isSelected ? selectedColor : unselectedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
