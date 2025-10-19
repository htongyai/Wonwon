import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/design_tokens.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/localization/app_localizations.dart';

class TabletNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TabletNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize ResponsiveSize if needed
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    // Use responsive navigation bar height from design tokens
    final screenHeight = MediaQuery.of(context).size.height;
    final navBarHeight = DesignTokens.getResponsiveNavBarHeight(screenHeight);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: DesignTokens.shadowMd,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: FontAwesomeIcons.house,
            label: AppLocalizations.of(context).translate('home'),
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: FontAwesomeIcons.map,
            label: AppLocalizations.of(context).translate('map'),
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: FontAwesomeIcons.heart,
            label: AppLocalizations.of(context).translate('saved'),
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: FontAwesomeIcons.user,
            label: AppLocalizations.of(context).translate('profile'),
          ),
          _buildNavItem(
            context,
            index: 4,
            icon: FontAwesomeIcons.comments,
            label: AppLocalizations.of(context).translate('forum'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spacingSm,
              horizontal: DesignTokens.spacingXs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color:
                      isSelected ? AppConstants.primaryColor : Colors.grey[600],
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight:
                        isSelected
                            ? DesignTokens.fontWeightSemiBold
                            : DesignTokens.fontWeightNormal,
                    color:
                        isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
