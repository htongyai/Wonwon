import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/firebase_shop_service.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class ShopService {
  final FirebaseShopService _firebaseService = FirebaseShopService();

  // Get all approved shops
  Future<List<RepairShop>> getAllShops() async {
    try {
      appLog('Querying Firestore for all approved shops...');

      // Get the shops collection reference
      final CollectionReference shopsCollection = FirebaseFirestore.instance
          .collection('shops');

      // Query for approved shops
      final QuerySnapshot snapshot =
          await shopsCollection.where('approved', isEqualTo: true).get();

      appLog(
        'Firestore query: shopsCollection.where("approved", isEqualTo: true)',
      );
      appLog('Query returned ${snapshot.docs.length} documents');

      appLog('Firestore returned ${snapshot.docs.length} documents');

      // Check for duplicate document IDs
      final docIds = snapshot.docs.map((doc) => doc.id).toList();
      final uniqueDocIds = docIds.toSet();
      appLog('All document IDs from Firestore: $docIds');
      appLog('Unique document IDs: ${uniqueDocIds.toList()}');

      if (docIds.length != uniqueDocIds.length) {
        appLog('WARNING: Duplicate document IDs found in Firestore response!');
        final duplicates = <String, int>{};
        for (final id in docIds) {
          duplicates[id] = (duplicates[id] ?? 0) + 1;
        }
        duplicates.forEach((id, count) {
          if (count > 1) {
            appLog(
              'Document ID $id appears $count times in Firestore response',
            );
          }
        });
      }

      // Convert documents to RepairShop objects
      final List<RepairShop> shops =
          snapshot.docs.map((doc) {
            appLog('Processing document ${doc.id}');
            final data = doc.data() as Map<String, dynamic>;
            // Add the document ID to the data
            data['id'] = doc.id;
            return RepairShop.fromMap(data);
          }).toList();

      appLog(
        'Successfully converted ${shops.length} documents to RepairShop objects',
      );

      // Remove duplicates by ID (keep the first occurrence)
      final Map<String, RepairShop> uniqueShops = {};
      for (final shop in shops) {
        if (!uniqueShops.containsKey(shop.id)) {
          uniqueShops[shop.id] = shop;
        }
      }

      final uniqueShopsList = uniqueShops.values.toList();
      appLog(
        'After removing duplicates: ${uniqueShopsList.length} unique shops',
      );
      return uniqueShopsList;
    } catch (e) {
      appLog('Error getting all shops: $e');
      rethrow;
    }
  }

  // Get unapproved shops
  Future<List<RepairShop>> getUnapprovedShops() async {
    try {
      appLog('Querying Firestore for unapproved shops...');

      // Get the shops collection reference
      final CollectionReference shopsCollection = FirebaseFirestore.instance
          .collection('shops');

      // Query for unapproved shops
      final QuerySnapshot snapshot =
          await shopsCollection.where('approved', isEqualTo: false).get();

      appLog('Firestore returned ${snapshot.docs.length} documents');

      // Convert documents to RepairShop objects
      final List<RepairShop> shops =
          snapshot.docs.map((doc) {
            appLog('Processing document ${doc.id}');
            final data = doc.data() as Map<String, dynamic>;
            // Add the document ID to the data
            data['id'] = doc.id;
            appLog('Document data: $data');
            return RepairShop.fromMap(data);
          }).toList();

      appLog(
        'Successfully converted ${shops.length} documents to RepairShop objects',
      );
      return shops;
    } catch (e) {
      appLog('Error getting unapproved shops: $e');
      rethrow;
    }
  }

  // Add a new shop
  Future<bool> addShop(RepairShop shop) async {
    return await _firebaseService.addShop(shop);
  }

  // Update a shop
  Future<bool> updateShop(RepairShop shop) async {
    return await _firebaseService.updateShop(shop);
  }

  // Approve a shop
  Future<bool> approveShop(String shopId) async {
    return await _firebaseService.approveShop(shopId);
  }

  // Delete a shop
  Future<bool> deleteShop(String shopId) async {
    return await _firebaseService.deleteShop(shopId);
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
          instagramPage: shopMap['instagramPage'],
        );
      }).toList();
    } catch (e) {
      appLog('Error getting user-submitted shops: $e');
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
      appLog('Error saving user-submitted shops: $e');
    }
  }

  // Get shop by ID
  Future<RepairShop?> getShopById(String shopId) async {
    try {
      final shops = await getAllShops();
      try {
        return shops.firstWhere((shop) => shop.id == shopId);
      } catch (e) {
        // Shop not found, return null instead of placeholder
        appLog('Shop with ID $shopId not found');
        return null;
      }
    } catch (e) {
      appLog('Error getting shop by ID $shopId: $e');
      return null;
    }
  }

  // Get shops by category
  Future<List<RepairShop>> getShopsByCategory(String categoryId) async {
    final shops = await getAllShops();
    if (categoryId == 'all') {
      return shops;
    }
    return shops.where((shop) => shop.categories.contains(categoryId)).toList();
  }

  // Search shops by name or description
  Future<List<RepairShop>> searchShops(String query) async {
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
    final shops = await getAllShops();
    final lowerCaseArea = area.toLowerCase();
    return shops
        .where((shop) => shop.area.toLowerCase().contains(lowerCaseArea))
        .toList();
  }

  // Get shops by rating (minimum rating)
  Future<List<RepairShop>> getShopsByMinimumRating(double minRating) async {
    final shops = await getAllShops();
    return shops.where((shop) => shop.rating >= minRating).toList();
  }

  // Get nearby shops (within a certain radius in kilometers)
  Future<List<RepairShop>> getNearbyShops(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
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

  // Calculate distance between two points using Haversine formula
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

  Future<bool> updateShopApprovalStatus(String shopId, bool approved) async {
    try {
      appLog('Updating shop approval status for shop $shopId to $approved');

      // Get the shops collection reference
      final DocumentReference shopRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId);

      // Update the document
      await shopRef.update({
        'approved': approved,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      appLog('Successfully updated shop approval status');
      return true;
    } catch (e) {
      appLog('Error updating shop approval status: $e');
      return false;
    }
  }
}
