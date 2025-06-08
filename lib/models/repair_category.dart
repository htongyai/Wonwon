import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';

class RepairCategory {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final List<RepairSubService> subServices;

  RepairCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconPath = '',
    required this.subServices,
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
    final subServices = RepairSubService.getSubServices();

    return [
      RepairCategory(
        id: 'all',
        name: 'All',
        description: 'All repair services',
        iconPath: 'FontAwesomeIcons.screwdriverWrench',
        subServices: [],
      ),
      RepairCategory(
        id: 'clothing',
        name: 'Clothing',
        description: 'Clothing repair services',
        iconPath: 'FontAwesomeIcons.shirt',
        subServices: subServices['clothing'] ?? [],
      ),
      RepairCategory(
        id: 'footwear',
        name: 'Footwear',
        description: 'Shoe and footwear repair',
        iconPath: 'FontAwesomeIcons.shoePrints',
        subServices: subServices['footwear'] ?? [],
      ),
      RepairCategory(
        id: 'watch',
        name: 'Watches',
        description: 'Watch repair services',
        iconPath: 'FontAwesomeIcons.clock',
        subServices: subServices['watch'] ?? [],
      ),
      RepairCategory(
        id: 'bag',
        name: 'Bags',
        description: 'Bag repair services',
        iconPath: 'FontAwesomeIcons.briefcase',
        subServices: subServices['bag'] ?? [],
      ),
      RepairCategory(
        id: 'appliances',
        name: 'Appliances',
        description: 'Electrical appliance repair',
        iconPath: 'FontAwesomeIcons.plug',
        subServices: subServices['appliances'] ?? [],
      ),
      RepairCategory(
        id: 'electronics',
        name: 'Electronics',
        description: 'Computer, phone and electronic device repair',
        iconPath: 'FontAwesomeIcons.laptop',
        subServices: subServices['electronics'] ?? [],
      ),
    ];
  }
}
