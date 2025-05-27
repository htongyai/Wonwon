import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/repair_shop.dart';

class SavedShopService {
  static const String _savedShopsKey = 'saved_shops';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all saved shops for the current user
  Future<List<String>> getSavedShopIds() async {
    // Check if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Get saved shops from Firestore
        final snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('savedShops')
                .get();

        // Return shop IDs
        return snapshot.docs.map((doc) => doc.id).toList();
      } catch (e) {
        print('Error getting saved shops from Firestore: $e');
        // Fallback to SharedPreferences if Firestore fails
        return _getSavedShopsFromPrefs();
      }
    } else {
      // Use SharedPreferences for non-logged in users
      return _getSavedShopsFromPrefs();
    }
  }

  // Save a shop to the user's saved collection
  Future<bool> saveShop(String shopId) async {
    // Check if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Save to Firestore user's savedShops subcollection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedShops')
            .doc(shopId)
            .set({'savedAt': FieldValue.serverTimestamp()});

        return true;
      } catch (e) {
        print('Error saving shop to Firestore: $e');
        // Fallback to SharedPreferences if Firestore fails
        return _saveShopToPrefs(shopId);
      }
    } else {
      // Use SharedPreferences for non-logged in users
      return _saveShopToPrefs(shopId);
    }
  }

  // Remove a saved shop
  Future<bool> removeShop(String shopId) async {
    // Check if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Remove from Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedShops')
            .doc(shopId)
            .delete();

        return true;
      } catch (e) {
        print('Error removing shop from Firestore: $e');
        // Fallback to SharedPreferences if Firestore fails
        return _removeShopFromPrefs(shopId);
      }
    } else {
      // Use SharedPreferences for non-logged in users
      return _removeShopFromPrefs(shopId);
    }
  }

  // Check if a shop is saved
  Future<bool> isShopSaved(String shopId) async {
    // Check if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Check in Firestore
        final doc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('savedShops')
                .doc(shopId)
                .get();

        return doc.exists;
      } catch (e) {
        print('Error checking if shop is saved in Firestore: $e');
        // Fallback to SharedPreferences if Firestore fails
        final savedShops = await _getSavedShopsFromPrefs();
        return savedShops.contains(shopId);
      }
    } else {
      // Use SharedPreferences for non-logged in users
      final savedShops = await _getSavedShopsFromPrefs();
      return savedShops.contains(shopId);
    }
  }

  // Private method to get saved shops from SharedPreferences (fallback)
  Future<List<String>> _getSavedShopsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedShopsKey) ?? [];
  }

  // Private method to save shop to SharedPreferences (fallback)
  Future<bool> _saveShopToPrefs(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList(_savedShopsKey) ?? [];

    // Check if already saved
    if (savedShops.contains(shopId)) {
      return false; // Already saved
    }

    savedShops.add(shopId);
    return await prefs.setStringList(_savedShopsKey, savedShops);
  }

  // Private method to remove shop from SharedPreferences (fallback)
  Future<bool> _removeShopFromPrefs(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList(_savedShopsKey) ?? [];

    if (!savedShops.contains(shopId)) {
      return false; // Not in saved list
    }

    savedShops.remove(shopId);
    return await prefs.setStringList(_savedShopsKey, savedShops);
  }
}
