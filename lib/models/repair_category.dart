import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class RepairCategory {
  final String id;
  final String name;
  final String description;
  final String iconPath;

  RepairCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconPath = '',
  });

  // Get localized name
  String getLocalizedName(BuildContext context) {
    return 'category_$id'.tr(context);
  }

  // Get localized description
  String getLocalizedDescription(BuildContext context) {
    return 'category_${id}_desc'.tr(context);
  }

  static List<RepairCategory> getCategories() {
    return [
      RepairCategory(
        id: 'all',
        name: 'All',
        description: 'All repair services',
        iconPath: 'FontAwesomeIcons.screwdriverWrench',
      ),
      RepairCategory(
        id: 'clothing',
        name: 'Clothing',
        description: 'Clothing repair services',
        iconPath: 'FontAwesomeIcons.shirt',
      ),
      RepairCategory(
        id: 'footwear',
        name: 'Footwear',
        description: 'Shoe and footwear repair',
        iconPath: 'FontAwesomeIcons.shoePrints',
      ),
      RepairCategory(
        id: 'watch',
        name: 'Watches',
        description: 'Watch repair services',
        iconPath: 'FontAwesomeIcons.clock',
      ),
      RepairCategory(
        id: 'bag',
        name: 'Bags',
        description: 'Bag repair services',
        iconPath: 'FontAwesomeIcons.briefcase',
      ),
      RepairCategory(
        id: 'appliance',
        name: 'Appliances',
        description: 'Electrical appliance repair',
        iconPath: 'FontAwesomeIcons.blender',
      ),
      RepairCategory(
        id: 'electronics',
        name: 'Electronics',
        description: 'Computer, phone and electronic device repair',
        iconPath: 'FontAwesomeIcons.laptop',
      ),
    ];
  }
}
