import '../models/repair_shop.dart';
import 'dart:math' as math;
import 'mock_shop_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShopService {
  // Get all shops
  Future<List<RepairShop>> getAllShops() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Get saved user-submitted shops
    final userShops = await _getUserSubmittedShops();

    // Get approved user-submitted shops
    final approvedUserShops = userShops.where((shop) => shop.approved).toList();

    // Combine mock shops with approved user-submitted shops
    final allShops = [...MockShopData.getAllShops(), ...approvedUserShops];

    return allShops;
  }

  // Add a new shop
  Future<bool> addShop(RepairShop shop) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, this would send the shop to a backend API
      // For this demo, we'll save it to SharedPreferences

      // Get existing submitted shops
      final userShops = await _getUserSubmittedShops();

      // Add the new shop
      userShops.add(shop);

      // Save back to SharedPreferences
      await _saveUserSubmittedShops(userShops);

      return true;
    } catch (e) {
      print('Error adding shop: $e');
      return false;
    }
  }

  // Get user-submitted shops (both approved and pending)
  Future<List<RepairShop>> getUserSubmittedShops() async {
    return _getUserSubmittedShops();
  }

  // Private method to get user-submitted shops from SharedPreferences
  Future<List<RepairShop>> _getUserSubmittedShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopsJson = prefs.getStringList('user_submitted_shops') ?? [];

      return shopsJson.map((shopJson) {
        final shopMap = jsonDecode(shopJson) as Map<String, dynamic>;

        // Convert categories from dynamic to List<String>
        final List<dynamic> categoriesDynamic = shopMap['categories'] ?? [];
        final List<String> categories = categoriesDynamic.cast<String>();

        // Convert hours from dynamic to Map<String, String>
        final Map<dynamic, dynamic> hoursDynamic = shopMap['hours'] ?? {};
        final Map<String, String> hours = hoursDynamic.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );

        // Convert closingDays from dynamic to List<String>
        final List<dynamic> closingDaysDynamic = shopMap['closingDays'] ?? [];
        final List<String> closingDays = closingDaysDynamic.cast<String>();

        // Convert amenities from dynamic to List<String>
        final List<dynamic> amenitiesDynamic = shopMap['amenities'] ?? [];
        final List<String> amenities = amenitiesDynamic.cast<String>();

        // Convert photos from dynamic to List<String>
        final List<dynamic> photosDynamic = shopMap['photos'] ?? [];
        final List<String> photos = photosDynamic.cast<String>();

        // Convert features from dynamic to Map<String, bool>
        final Map<dynamic, dynamic> featuresDynamic = shopMap['features'] ?? {};
        final Map<String, bool> features = featuresDynamic.map(
          (key, value) => MapEntry(key.toString(), value as bool),
        );

        return RepairShop(
          id: shopMap['id'] as String,
          name: shopMap['name'] as String,
          description: shopMap['description'] as String,
          address: shopMap['address'] as String,
          area: shopMap['area'] as String,
          categories: categories,
          rating: (shopMap['rating'] as num).toDouble(),
          reviewCount: shopMap['reviewCount'] as int? ?? 0,
          amenities: amenities,
          hours: hours,
          closingDays: closingDays,
          latitude: (shopMap['latitude'] as num).toDouble(),
          longitude: (shopMap['longitude'] as num).toDouble(),
          durationMinutes: shopMap['durationMinutes'] as int? ?? 0,
          requiresPurchase: shopMap['requiresPurchase'] as bool? ?? false,
          photos: photos,
          priceRange: shopMap['priceRange'] as String? ?? '₿',
          features: features,
          approved: shopMap['approved'] as bool? ?? false,
          irregularHours: shopMap['irregularHours'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error getting user-submitted shops: $e');
      return [];
    }
  }

  // Private method to save user-submitted shops to SharedPreferences
  Future<void> _saveUserSubmittedShops(List<RepairShop> shops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopsJson = shops.map((shop) => jsonEncode(shop.toMap())).toList();
      await prefs.setStringList('user_submitted_shops', shopsJson);
    } catch (e) {
      print('Error saving user-submitted shops: $e');
    }
  }

  // Get shop by ID
  Future<RepairShop?> getShopById(String shopId) async {
    // Check user-submitted shops first
    final userShops = await _getUserSubmittedShops();
    final userShop = userShops.where((shop) => shop.id == shopId).toList();
    if (userShop.isNotEmpty) {
      return userShop.first;
    }

    // Then check mock shops
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final shops = MockShopData.getAllShops();
    return shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse:
          () => RepairShop(
            id: 'not-found',
            name: 'Not Found',
            description: 'Shop not found',
            address: '',
            area: '',
            categories: [],
            rating: 0,
            hours: {},
            latitude: 0,
            longitude: 0,
          ),
    );
  }

  // Get shops by category
  Future<List<RepairShop>> getShopsByCategory(String categoryId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get mock shops by category
    final mockShops = MockShopData.getShopsByCategory(categoryId);

    // Get approved user-submitted shops
    final userShops = await _getUserSubmittedShops();
    final approvedUserShops =
        userShops
            .where(
              (shop) =>
                  shop.approved &&
                  (categoryId == 'all' || shop.categories.contains(categoryId)),
            )
            .toList();

    // Combine lists
    return [...mockShops, ...approvedUserShops];
  }

  // Search shops by name or description
  Future<List<RepairShop>> searchShops(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final shops = await getAllShops();
    final lowerCaseQuery = query.toLowerCase();
    return shops
        .where(
          (shop) =>
              shop.name.toLowerCase().contains(lowerCaseQuery) ||
              shop.description.toLowerCase().contains(lowerCaseQuery) ||
              shop.area.toLowerCase().contains(lowerCaseQuery) ||
              shop.categories.any(
                (category) => category.toLowerCase().contains(lowerCaseQuery),
              ),
        )
        .toList();
  }

  // Get shops by area
  Future<List<RepairShop>> getShopsByArea(String area) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final shops = await getAllShops();
    final lowerCaseArea = area.toLowerCase();
    return shops
        .where((shop) => shop.area.toLowerCase().contains(lowerCaseArea))
        .toList();
  }

  // Get shops by rating (minimum rating)
  Future<List<RepairShop>> getShopsByMinimumRating(double minRating) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final shops = await getAllShops();
    return shops.where((shop) => shop.rating >= minRating).toList();
  }

  // Get nearby shops (within a certain radius in kilometers)
  Future<List<RepairShop>> getNearbyShops(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final shops = await getAllShops();
    return shops
        .where(
          (shop) =>
              _calculateDistance(
                latitude,
                longitude,
                shop.latitude,
                shop.longitude,
              ) <=
              radiusKm,
        )
        .toList();
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}
