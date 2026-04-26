import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/models/repair_category.dart';
import 'package:shared/models/repair_sub_service.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Horizontal scrollable category filter chips with expandable sub-service row
class CategoryChips extends StatelessWidget {
  final String selectedCategoryId;
  final String? selectedSubServiceId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String?> onSubServiceSelected;

  const CategoryChips({
    Key? key,
    required this.selectedCategoryId,
    this.selectedSubServiceId,
    required this.onCategorySelected,
    required this.onSubServiceSelected,
  }) : super(key: key);

  static final List<RepairCategory> _cachedCategories = RepairCategory.getCategories();
  static final Map<String, List<RepairSubService>> _cachedSubServices = RepairSubService.getSubServices();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _cachedCategories;
    final allSubServices = _cachedSubServices;
    final hasSubServices = selectedCategoryId != 'all' &&
        (allSubServices[selectedCategoryId]?.isNotEmpty ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category row
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => onCategorySelected(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : theme.dividerColor,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        _getCategoryIcon(cat.id),
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'category_${cat.id}'.tr(context),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Sub-service row (animated)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: hasSubServices
              ? _buildSubServiceRow(context, allSubServices[selectedCategoryId] ?? [])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubServiceRow(
      BuildContext context, List<RepairSubService> subServices) {
    final theme = Theme.of(context);
    final idleBg = theme.colorScheme.surfaceContainerHighest;
    final idleBorder = theme.dividerColor;
    final idleFg = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subServices.length + 1, // +1 for "All" chip
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            if (index == 0) {
              // "All" sub-services chip
              final isSelected = selectedSubServiceId == null;
              return GestureDetector(
                onTap: () => onSubServiceSelected(null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor.withValues(alpha: 0.15)
                        : idleBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor.withValues(alpha: 0.4)
                          : idleBorder,
                    ),
                  ),
                  child: Text(
                    'category_all'.tr(context),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : idleFg,
                    ),
                  ),
                ),
              );
            }

            final sub = subServices[index - 1];
            final isSelected = selectedSubServiceId == sub.id;
            return GestureDetector(
              onTap: () =>
                  onSubServiceSelected(isSelected ? null : sub.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withValues(alpha: 0.15)
                      : idleBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryColor.withValues(alpha: 0.4)
                        : idleBorder,
                  ),
                ),
                child: Text(
                  'subservice_${sub.categoryId}_${sub.id}'.tr(context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppConstants.primaryColor
                        : idleFg,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'all':
        return FontAwesomeIcons.screwdriverWrench;
      case 'clothing':
        return FontAwesomeIcons.shirt;
      case 'footwear':
        return FontAwesomeIcons.shoePrints;
      case 'watch':
        return FontAwesomeIcons.clock;
      case 'bag':
        return FontAwesomeIcons.briefcase;
      case 'appliances':
        return FontAwesomeIcons.plug;
      case 'electronics':
        return FontAwesomeIcons.laptop;
      default:
        return FontAwesomeIcons.screwdriverWrench;
    }
  }
}
