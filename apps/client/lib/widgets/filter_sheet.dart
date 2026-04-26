import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/models/shop_filter.dart';

/// Full-featured filter modal. Shown when user taps "More filters".
/// Edits a local copy of [ShopFilter]; returns it on Apply.
class FilterSheet extends StatefulWidget {
  final ShopFilter initial;
  const FilterSheet({Key? key, required this.initial}) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ShopFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _update(ShopFilter next) {
    setState(() => _draft = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('filter_availability'.tr(context)),
                      _buildOpenNowToggle(context),
                      const SizedBox(height: 24),
                      _sectionTitle('filter_rating'.tr(context)),
                      _buildRatingRow(),
                      const SizedBox(height: 24),
                      _sectionTitle('filter_price'.tr(context)),
                      _buildPriceRow(),
                      const SizedBox(height: 24),
                      _sectionTitle('filter_distance'.tr(context)),
                      _buildDistanceRow(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pieces ────────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        children: [
          Text(
            'filters'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _draft.hasActiveFilters
                ? () {
                    HapticFeedback.selectionClick();
                    _update(ShopFilter(sortMode: _draft.sortMode));
                  }
                : null,
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
            ),
            child: Text(
              'clear_all'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildOpenNowToggle(BuildContext context) {
    final theme = Theme.of(context);
    return _Row(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppConstants.primaryColor,
        title: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              'filter_open_now'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        value: _draft.openNow,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          _update(_draft.copyWith(openNow: v));
        },
      ),
    );
  }

  Widget _buildRatingRow() {
    final options = [0.0, 3.0, 3.5, 4.0, 4.5];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((r) {
        final selected = _draft.minRating == r;
        return _PillChoice(
          selected: selected,
          label: r == 0 ? 'any'.tr(context) : '${r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 1)}★+',
          onTap: () {
            HapticFeedback.selectionClick();
            _update(_draft.copyWith(minRating: r));
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriceRow() {
    final prices = ['฿', '฿฿', '฿฿฿', '฿฿฿฿'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prices.map((p) {
        final selected = _draft.priceRanges.contains(p);
        return _PillChoice(
          selected: selected,
          label: p,
          onTap: () {
            HapticFeedback.selectionClick();
            final next = Set<String>.from(_draft.priceRanges);
            if (selected) {
              next.remove(p);
            } else {
              next.add(p);
            }
            _update(_draft.copyWith(priceRanges: next));
          },
        );
      }).toList(),
    );
  }

  Widget _buildDistanceRow(BuildContext context) {
    final options = <double?>[null, 1, 3, 5, 10];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((d) {
        final selected = _draft.maxDistanceKm == d;
        return _PillChoice(
          selected: selected,
          label: d == null
              ? 'any'.tr(context)
              : '${d.toInt()} km',
          onTap: () {
            HapticFeedback.selectionClick();
            _update(_draft.copyWith(maxDistanceKm: d));
          },
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _draft);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'filter_apply'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Widget child;
  const _Row({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}

class _PillChoice extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _PillChoice({
    required this.selected,
    required this.label,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.primaryColor
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppConstants.primaryColor
                  : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
