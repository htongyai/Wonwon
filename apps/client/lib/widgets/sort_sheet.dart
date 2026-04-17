import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/models/shop_filter.dart';

/// Bottom sheet that lets the user pick a [ShopSortMode].
/// Returns the selected mode via Navigator.pop.
class SortSheet extends StatelessWidget {
  final ShopSortMode current;
  const SortSheet({Key? key, required this.current}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = [
      _SortOption(ShopSortMode.distance, Icons.near_me_rounded),
      _SortOption(ShopSortMode.rating, Icons.star_rounded),
      _SortOption(ShopSortMode.newest, Icons.new_releases_rounded),
      _SortOption(ShopSortMode.nameAsc, Icons.sort_by_alpha_rounded),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'sort_by'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.darkColor,
                    ),
                  ),
                ],
              ),
            ),
            ...options.map((opt) => _OptionTile(
                  option: opt,
                  isSelected: opt.mode == current,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, opt.mode);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SortOption {
  final ShopSortMode mode;
  final IconData icon;
  const _SortOption(this.mode, this.icon);
}

class _OptionTile extends StatelessWidget {
  final _SortOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option.icon,
                  size: 18,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.mode.key.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppConstants.darkColor,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded,
                    size: 20, color: AppConstants.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
