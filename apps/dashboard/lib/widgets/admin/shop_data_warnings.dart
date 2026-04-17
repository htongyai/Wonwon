import 'package:flutter/material.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

/// Types of missing data a shop can have.
enum ShopWarningType {
  missingName,
  missingCoordinates,
  missingPhone,
  missingCategories,
  missingAddress,
}

/// Utility to check a [RepairShop] for missing critical data.
class ShopDataWarnings {
  /// Returns the list of warnings for the given shop.
  static List<ShopWarningType> getWarnings(RepairShop shop) {
    final warnings = <ShopWarningType>[];

    if (shop.name.trim().isEmpty || shop.name == 'Unnamed Shop') {
      warnings.add(ShopWarningType.missingName);
    }
    if (shop.latitude == 0.0 && shop.longitude == 0.0) {
      warnings.add(ShopWarningType.missingCoordinates);
    }
    if (shop.phoneNumber == null || shop.phoneNumber!.trim().isEmpty) {
      warnings.add(ShopWarningType.missingPhone);
    }
    if (shop.categories.isEmpty) {
      warnings.add(ShopWarningType.missingCategories);
    }
    if (shop.address.trim().isEmpty && shop.area.trim().isEmpty) {
      warnings.add(ShopWarningType.missingAddress);
    }

    return warnings;
  }

  /// Human-readable label for a warning type (localized).
  static String warningLabel(ShopWarningType type, BuildContext context) {
    switch (type) {
      case ShopWarningType.missingName:
        return 'warning_missing_name'.tr(context);
      case ShopWarningType.missingCoordinates:
        return 'warning_missing_coordinates'.tr(context);
      case ShopWarningType.missingPhone:
        return 'warning_missing_phone'.tr(context);
      case ShopWarningType.missingCategories:
        return 'warning_missing_categories'.tr(context);
      case ShopWarningType.missingAddress:
        return 'warning_missing_address'.tr(context);
    }
  }
}

/// A small warning badge that shows on a shop card when data is incomplete.
///
/// Renders nothing if there are no warnings.
class ShopWarningBadge extends StatelessWidget {
  final RepairShop shop;

  const ShopWarningBadge({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final warnings = ShopDataWarnings.getWarnings(shop);
    if (warnings.isEmpty) return const SizedBox.shrink();

    final tooltipText = warnings
        .map((w) => '• ${ShopDataWarnings.warningLabel(w, context)}')
        .join('\n');

    return Tooltip(
      message: tooltipText,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFBBF24), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(
              '${warnings.length}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
