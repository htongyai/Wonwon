import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:wonwonw2/utils/app_logger.dart';

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
          instagramPage: data['instagramPage'],
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
          instagramPage: data['instagramPage'],
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
      await _firestore.collection(_collection).doc(shop.id).set(shop.toMap());
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
      return true;
    } catch (e) {
      appLog('Error updating shop: $e');
      return false;
    }
  }

  // Approve a shop
  Future<bool> approveShop(String shopId) async {
    try {
      await _firestore.collection(_collection).doc(shopId).update({
        'approved': true,
      });
      return true;
    } catch (e) {
      appLog('Error approving shop: $e');
      return false;
    }
  }

  // Delete a shop
  Future<bool> deleteShop(String shopId) async {
    try {
      await _firestore.collection(_collection).doc(shopId).delete();
      return true;
    } catch (e) {
      appLog('Error deleting shop: $e');
      return false;
    }
  }

  Future<String?> _uploadImageToFirebase(
    Uint8List imageBytes,
    String shopId,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final shopImageRef = storageRef.child('shops/$shopId/main.jpg');

      // Upload the bytes
      await shopImageRef.putData(imageBytes);

      // Get the download URL and ensure it's using the correct domain
      String downloadUrl = await shopImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      appLog('Error uploading image to Firebase: $e');
      return null;
    }
  }
}
