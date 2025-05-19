import '../models/repair_shop.dart';
import 'dart:math' as math;
import 'mock_shop_data.dart';

class ShopService {
  // Get all shops
  Future<List<RepairShop>> getAllShops() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return all shops from mock data
    return MockShopData.getAllShops();
  }

  // Get shop by ID
  Future<RepairShop?> getShopById(String shopId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final shops = await getAllShops();
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

    return MockShopData.getShopsByCategory(categoryId);
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
