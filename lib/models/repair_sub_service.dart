import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class RepairSubService {
  final String id;
  final String name;
  final String description;
  final String categoryId;

  RepairSubService({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
  });

  // Get localized name
  String getLocalizedName(BuildContext context) {
    return 'subservice_${categoryId}_$id'.tr(context);
  }

  // Get localized description
  String getLocalizedDescription(BuildContext context) {
    return 'subservice_${categoryId}_${id}_desc'.tr(context);
  }

  static Map<String, List<RepairSubService>> getSubServices() {
    return {
      'clothing': [
        RepairSubService(
          id: 'zipper_replacement',
          name: 'Zipper replacement',
          description: 'Zipper replacement and repair',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'pants_hemming',
          name: 'Pants hemming',
          description: 'Pants hemming and adjustment',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'waist_adjustment',
          name: 'Waist adjustment',
          description: 'Waist adjustment for pants and skirts',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'elastic_replacement',
          name: 'Elastic replacement',
          description: 'Elastic band replacement',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'button_replacement',
          name: 'Button replacement',
          description: 'Button replacement and repair',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'collar_replacement',
          name: 'Collar replacement',
          description: 'Collar replacement and repair',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'tear_repair',
          name: 'Tear repair',
          description: 'Repair of tears and holes',
          categoryId: 'clothing',
        ),
        RepairSubService(
          id: 'add_pockets',
          name: 'Add pockets',
          description: 'Add pockets to pants or shirts',
          categoryId: 'clothing',
        ),
      ],
      'footwear': [
        RepairSubService(
          id: 'sole_replacement',
          name: 'Sole replacement',
          description: 'Sole replacement and repair',
          categoryId: 'footwear',
        ),
        RepairSubService(
          id: 'leather_repair',
          name: 'Leather shoe repair',
          description: 'Leather shoe repair and maintenance',
          categoryId: 'footwear',
        ),
        RepairSubService(
          id: 'heel_repair',
          name: 'Heel repair/replacement',
          description: 'Heel repair and replacement',
          categoryId: 'footwear',
        ),
        RepairSubService(
          id: 'shoe_cleaning',
          name: 'Shoe cleaning',
          description: 'Professional shoe cleaning',
          categoryId: 'footwear',
        ),
      ],
      'watch': [
        RepairSubService(
          id: 'scratch_removal',
          name: 'Scratch removal',
          description: 'Watch scratch removal',
          categoryId: 'watch',
        ),
        RepairSubService(
          id: 'battery_replacement',
          name: 'Battery replacement',
          description: 'Watch battery replacement',
          categoryId: 'watch',
        ),
        RepairSubService(
          id: 'watch_cleaning',
          name: 'Watch cleaning',
          description: 'Professional watch cleaning',
          categoryId: 'watch',
        ),
        RepairSubService(
          id: 'strap_replacement',
          name: 'Strap replacement',
          description: 'Watch strap replacement',
          categoryId: 'watch',
        ),
        RepairSubService(
          id: 'glass_replacement',
          name: 'Glass replacement',
          description: 'Watch glass replacement',
          categoryId: 'watch',
        ),
        RepairSubService(
          id: 'authenticity_check',
          name: 'Authenticity check',
          description: 'Watch authenticity verification',
          categoryId: 'watch',
        ),
      ],
      'bag': [
        RepairSubService(
          id: 'bag_repair',
          name: 'Various bag repairs',
          description:
              'Women\'s bags, brand name, travel, document, backpack, sports, student, golf bag, belt, leather jacket, laptop bag, musical instruments, food delivery, shoe repair, stroller repair',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'women_bags',
          name: 'Women\'s bags',
          description: 'Repair of women\'s bags and accessories',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'brand_bags',
          name: 'Brand name bags',
          description: 'Repair of luxury and designer bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'travel_bags',
          name: 'Travel bags',
          description: 'Repair of travel luggage and suitcases',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'document_bags',
          name: 'Document bags',
          description: 'Repair of document and briefcase bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'backpacks',
          name: 'Backpacks',
          description: 'Repair of backpacks and school bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'sports_bags',
          name: 'Sports bags',
          description: 'Repair of sports and gym bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'student_bags',
          name: 'Student bags',
          description: 'Repair of student and school bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'golf_bags',
          name: 'Golf bags',
          description: 'Repair of golf bags and accessories',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'belts',
          name: 'Belts',
          description: 'Repair of belts and leather accessories',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'leather_jackets',
          name: 'Leather jackets',
          description: 'Repair of leather jackets and outerwear',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'laptop_bags',
          name: 'Laptop bags',
          description: 'Repair of laptop and computer bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'music_instruments',
          name: 'Musical instruments',
          description: 'Repair of musical instrument cases and bags',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'food_delivery',
          name: 'Food delivery',
          description: 'Repair of food delivery bags and containers',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'shoe_repair',
          name: 'Shoe repair',
          description: 'Repair of shoes and footwear (in some cases)',
          categoryId: 'bag',
        ),
        RepairSubService(
          id: 'stroller_repair',
          name: 'Stroller repair',
          description: 'Repair of strollers and baby carriages (in some cases)',
          categoryId: 'bag',
        ),
      ],
      'appliances': [
        RepairSubService(
          id: 'small_appliances',
          name: 'Small appliances',
          description: 'Fan, hair dryer, microwave, air conditioner remote',
          categoryId: 'appliances',
        ),
        RepairSubService(
          id: 'large_appliances',
          name: 'Large appliances',
          description: 'Refrigerator, washing machine, dryer',
          categoryId: 'appliances',
        ),
      ],
      'electronics': [
        RepairSubService(
          id: 'laptop',
          name: 'Laptop',
          description: 'Laptop repair and maintenance',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'mac',
          name: 'Mac / iMac / Mac Pro',
          description: 'Apple computer repair and maintenance',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'mobile',
          name: 'Mobile phones and tablets',
          description: 'iPhone, iPad repair and maintenance',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'network',
          name: 'Networking devices',
          description: 'Network device repair and maintenance',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'printer',
          name: 'Printers',
          description: 'Printer repair and maintenance',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'audio',
          name: 'Audio devices',
          description: 'Headphones and speakers repair',
          categoryId: 'electronics',
        ),
        RepairSubService(
          id: 'other_electronics',
          name: 'Others',
          description: 'Other electronic device repairs',
          categoryId: 'electronics',
        ),
      ],
    };
  }
}
