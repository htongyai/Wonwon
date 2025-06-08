import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';

/// Helper class for handling stock images and placeholders throughout the app
class AssetHelpers {
  // Network placeholder URLs for repair shop images
  static const List<String> repairShopImages = [
    'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=800&q=80', // Electronics repair shop
    'https://images.unsplash.com/photo-1581092921461-39b0dc3b4ebf?w=800&q=80', // Computer repair
    'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800&q=80', // Phone repair
    'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=800&q=80', // Tools
    'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=800&q=80', // Repair workspace
  ];

  /// Get a stock repair shop image by index or random if not specified
  static String getRepairShopImage({int? index}) {
    if (index != null && index >= 0 && index < repairShopImages.length) {
      return repairShopImages[index];
    }
    // Return a consistent image based on current time (changes daily)
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return repairShopImages[dayOfYear % repairShopImages.length];
  }

  /// Get image error widget with app styling
  static Widget getImageErrorWidget({
    double size = 80,
    Color? color,
    IconData icon = Icons.image_not_supported_rounded,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? AppConstants.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size / 2,
          color: color ?? AppConstants.primaryColor,
        ),
      ),
    );
  }

  /// Generate placeholder image with shop name
  static Widget getShopPlaceholder(String shopName) {
    final nameInitials =
        shopName
            .split(' ')
            .take(2)
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
            .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.7),
            AppConstants.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          nameInitials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static String getStockImageUrl(String type) {
    switch (type) {
      case 'shop':
        return 'https://iili.io/3PiMVus.webp';
      case 'user':
        return 'https://iili.io/3PiMVus.webp';
      default:
        return 'https://iili.io/3PiMVus.webp';
    }
  }
}
