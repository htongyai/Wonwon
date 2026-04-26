// Add-shop method chooser.
//
// Shown when the home FAB is tapped. Asks the user how they want to add a
// shop — by pasting a Google Maps link (auto-fill) or by filling the form
// from scratch — before navigating to AddShopScreen. Splitting the entry
// point this way removes the discovery problem with the in-form import
// button: users who arrive with a maps link in hand don't have to scroll
// past the form to find the import path.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Result returned by [showAddShopMethodSheet].
enum AddShopMethod {
  /// Paste a Google Maps URL → import dialog → AddShopScreen prefilled.
  googleMaps,

  /// Open AddShopScreen empty.
  manual,
}

/// Convenience wrapper around `showModalBottomSheet` that returns the
/// selected method, or `null` if the user dismissed the sheet.
Future<AddShopMethod?> showAddShopMethodSheet(BuildContext context) {
  return showModalBottomSheet<AddShopMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AddShopMethodSheet(),
  );
}

class _AddShopMethodSheet extends StatelessWidget {
  const _AddShopMethodSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'add_shop'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'add_shop_method_subtitle'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _MethodCard(
              icon: Icons.auto_awesome_rounded,
              accent: EcoPalette.leaf,
              title: 'add_from_google_maps'.tr(context),
              subtitle: 'add_from_google_maps_desc'.tr(context),
              recommended: true,
              onTap: () =>
                  Navigator.pop(context, AddShopMethod.googleMaps),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: Icons.edit_note_rounded,
              accent: AppConstants.primaryColor,
              title: 'add_manually'.tr(context),
              subtitle: 'add_manually_desc'.tr(context),
              recommended: false,
              onTap: () => Navigator.pop(context, AddShopMethod.manual),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? accent.withValues(alpha: 0.12)
        : accent.withValues(alpha: 0.08);
    final borderColor = isDark
        ? accent.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'recommended'.tr(context),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
