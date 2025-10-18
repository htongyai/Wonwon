import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/services/activity_service.dart';

class FirebaseShopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'shops';

  // Get all approved shops
  Future<List<RepairShop>> getAllShops() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('approved', isEqualTo: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RepairShop(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          address: data['address'] ?? '',
          area: data['area'] ?? '',
          categories: List<String>.from(data['categories'] ?? []),
          rating: (data['rating'] ?? 0.0).toDouble(),
          reviewCount: data['reviewCount'] ?? 0,
          amenities: List<String>.from(data['amenities'] ?? []),
          hours: Map<String, String>.from(data['hours'] ?? {}),
          closingDays: List<String>.from(data['closingDays'] ?? []),
          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          durationMinutes: data['durationMinutes'] ?? 0,
          requiresPurchase: data['requiresPurchase'] ?? false,
          photos: List<String>.from(data['photos'] ?? []),
          priceRange: data['priceRange'] ?? '₿',
          features: Map<String, bool>.from(data['features'] ?? {}),
          approved: data['approved'] ?? false,
          irregularHours: data['irregularHours'] ?? false,
          subServices: Map<String, List<String>>.from(
            data['subServices'] ?? {},
          ),
          phoneNumber: data['phoneNumber'],
          facebookPage: data['facebookPage'],
          buildingNumber: data['buildingNumber'],
          buildingName: data['buildingName'],
          buildingFloor: data['buildingFloor'],
          soi: data['soi'],
          district: data['district'],
          province: data['province'],
          landmark: data['landmark'],
          lineId: data['lineId'],
          instagramPage: data['instagramPage'],
          otherContacts: data['otherContacts'],
          paymentMethods:
              data['paymentMethods'] != null
                  ? List<String>.from(data['paymentMethods'])
                  : null,
          tryOnAreaAvailable: data['tryOnAreaAvailable'],
          notesOrConditions: data['notesOrConditions'],
          usualOpeningTime: data['usualOpeningTime'],
          usualClosingTime: data['usualClosingTime'],
          timestamp:
              data['timestamp'] != null
                  ? DateTime.tryParse(data['timestamp'])
                  : null,
        );
      }).toList();
    } catch (e) {
      appLog('Error getting shops: $e');
      return [];
    }
  }

  // Get unapproved shops
  Future<List<RepairShop>> getUnapprovedShops() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('approved', isEqualTo: false)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RepairShop(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          address: data['address'] ?? '',
          area: data['area'] ?? '',
          categories: List<String>.from(data['categories'] ?? []),
          rating: (data['rating'] ?? 0.0).toDouble(),
          reviewCount: data['reviewCount'] ?? 0,
          amenities: List<String>.from(data['amenities'] ?? []),
          hours: Map<String, String>.from(data['hours'] ?? {}),
          closingDays: List<String>.from(data['closingDays'] ?? []),
          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          durationMinutes: data['durationMinutes'] ?? 0,
          requiresPurchase: data['requiresPurchase'] ?? false,
          photos: List<String>.from(data['photos'] ?? []),
          priceRange: data['priceRange'] ?? '₿',
          features: Map<String, bool>.from(data['features'] ?? {}),
          approved: data['approved'] ?? false,
          irregularHours: data['irregularHours'] ?? false,
          subServices: Map<String, List<String>>.from(
            data['subServices'] ?? {},
          ),
          phoneNumber: data['phoneNumber'],
          facebookPage: data['facebookPage'],
          buildingNumber: data['buildingNumber'],
          buildingName: data['buildingName'],
          buildingFloor: data['buildingFloor'],
          soi: data['soi'],
          district: data['district'],
          province: data['province'],
          landmark: data['landmark'],
          lineId: data['lineId'],
          instagramPage: data['instagramPage'],
          otherContacts: data['otherContacts'],
          paymentMethods:
              data['paymentMethods'] != null
                  ? List<String>.from(data['paymentMethods'])
                  : null,
          tryOnAreaAvailable: data['tryOnAreaAvailable'],
          notesOrConditions: data['notesOrConditions'],
          usualOpeningTime: data['usualOpeningTime'],
          usualClosingTime: data['usualClosingTime'],
          timestamp:
              data['timestamp'] != null
                  ? DateTime.tryParse(data['timestamp'])
                  : null,
        );
      }).toList();
    } catch (e) {
      appLog('Error getting unapproved shops: $e');
      return [];
    }
  }

  // Add a new shop
  Future<bool> addShop(RepairShop shop) async {
    try {
      // Debug logging to identify the source of empty IDs
      appLog('Adding shop with ID: "${shop.id}" (length: ${shop.id.length})');
      appLog('Shop name: "${shop.name}"');
      
      if (shop.id.isEmpty) {
        throw Exception('Shop ID cannot be empty. Shop name: ${shop.name}');
      }
      
      await _firestore.collection(_collection).doc(shop.id).set(shop.toMap());

      // Log shop creation activity
      try {
        final category =
            shop.categories.isNotEmpty ? shop.categories.first : 'Unknown';
        await ActivityService().logShopRegistration(
          shop.id,
          shop.name,
          category,
        );
      } catch (e) {
        appLog('Error logging shop creation activity: $e');
      }

      return true;
    } catch (e) {
      appLog('Error adding shop: $e');
      return false;
    }
  }

  // Update a shop
  Future<bool> updateShop(RepairShop shop) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shop.id)
          .update(shop.toMap());

      // Log shop update activity
      try {
        await ActivityService().logShopActivity(
          action: ActivityService.SHOP_UPDATED,
          title: 'Shop Updated',
          description: 'Shop "${shop.name}" information was updated',
          shopId: shop.id,
          metadata: {
            'shopName': shop.name,
            'category':
                shop.categories.isNotEmpty ? shop.categories.first : 'Unknown',
          },
        );
      } catch (e) {
        appLog('Error logging shop update activity: $e');
      }

      return true;
    } catch (e) {
      appLog('Error updating shop: $e');
      return false;
    }
  }

  // Approve a shop
  Future<bool> approveShop(String shopId) async {
    try {
      // Get shop details before approving
      final shopDoc =
          await _firestore.collection(_collection).doc(shopId).get();
      final shopData = shopDoc.data();
      final shopName = shopData?['name'] ?? 'Unknown Shop';

      await _firestore.collection(_collection).doc(shopId).update({
        'approved': true,
      });

      // Log shop approval activity
      try {
        await ActivityService().logShopApproval(shopId, shopName, 'Admin');
      } catch (e) {
        appLog('Error logging shop approval activity: $e');
      }

      return true;
    } catch (e) {
      appLog('Error approving shop: $e');
      return false;
    }
  }

  // Delete a shop
  Future<bool> deleteShop(String shopId) async {
    try {
      // Get shop details before deleting
      final shopDoc =
          await _firestore.collection(_collection).doc(shopId).get();
      final shopData = shopDoc.data();
      final shopName = shopData?['name'] ?? 'Unknown Shop';

      await _firestore.collection(_collection).doc(shopId).delete();

      // Log shop deletion activity
      try {
        await ActivityService().logAdminActivity(
          action: 'shop_deleted',
          title: 'Shop Deleted',
          description: 'Shop "$shopName" was deleted by admin',
          metadata: {
            'shopName': shopName,
            'shopId': shopId,
            'adminAction': true,
          },
        );
      } catch (e) {
        appLog('Error logging shop deletion activity: $e');
      }

      return true;
    } catch (e) {
      appLog('Error deleting shop: $e');
      return false;
    }
  }
}
