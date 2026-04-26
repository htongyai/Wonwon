import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/models/shop_filter.dart';
import 'package:wonwon_client/widgets/filter_sheet.dart';
import 'package:wonwon_client/widgets/sort_sheet.dart';

/// Horizontal scroll row of quick filters + a More button.
/// Sits below the search field on the home screen.
class FilterBar extends StatelessWidget {
  final ShopFilter filter;
  final ValueChanged<ShopFilter> onChanged;

  const FilterBar({
    Key? key,
    required this.filter,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _SortChip(
              sortMode: filter.sortMode,
              onTap: () => _openSortSheet(context),
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'filter_open_now'.tr(context),
              icon: Icons.access_time_rounded,
              active: filter.openNow,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(filter.copyWith(openNow: !filter.openNow));
              },
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: '4★+',
              active: filter.minRating >= 4,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(filter.copyWith(
                  minRating: filter.minRating >= 4 ? 0 : 4,
                ));
              },
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: '฿฿',
              active: filter.priceRanges.contains('฿฿') ||
                  filter.priceRanges.contains('฿'),
              onTap: () {
                HapticFeedback.selectionClick();
                final current = Set<String>.from(filter.priceRanges);
                if (current.contains('฿฿') || current.contains('฿')) {
                  current.removeAll(['฿', '฿฿']);
                } else {
                  current.addAll(['฿', '฿฿']);
                }
                onChanged(filter.copyWith(priceRanges: current));
              },
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'filter_nearby'.tr(context),
              icon: Icons.near_me_rounded,
              active: filter.maxDistanceKm != null && filter.maxDistanceKm! <= 3,
              onTap: () {
                HapticFeedback.selectionClick();
                final cur = filter.maxDistanceKm;
                onChanged(filter.copyWith(
                  maxDistanceKm:
                      (cur != null && cur <= 3) ? null : 3.0,
                ));
              },
            ),
            const SizedBox(width: 8),
            _MoreFiltersChip(
              badge: filter.activeCount,
              onTap: () => _openFilterSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSortSheet(BuildContext context) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<ShopSortMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SortSheet(current: filter.sortMode),
    );
    if (result != null && result != filter.sortMode) {
      onChanged(filter.copyWith(sortMode: result));
    }
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<ShopFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterSheet(initial: filter),
    );
    if (result != null) onChanged(result);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips

// Shared neutral background for the non-active state of every filter chip.
// Theme-aware so dark mode gets a correspondingly dim surface instead of the
// old hardcoded light grey.
Color _chipIdleBg(ThemeData theme) =>
    theme.colorScheme.surfaceContainerHighest;

class _SortChip extends StatelessWidget {
  final ShopSortMode sortMode;
  final VoidCallback onTap;

  const _SortChip({required this.sortMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _chipIdleBg(theme),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert_rounded,
                  size: 15, color: theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                sortMode.key.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppConstants.primaryColor
                : _chipIdleBg(theme),
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 15,
                    color: active
                        ? Colors.white
                        : theme.colorScheme.onSurface),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreFiltersChip extends StatelessWidget {
  final int badge;
  final VoidCallback onTap;

  const _MoreFiltersChip({required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = badge > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppConstants.primaryColor : _chipIdleBg(theme),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded,
                  size: 15,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                'filter_more'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
