import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/services/shop_service.dart';
import 'package:shared/utils/app_logger.dart';

class SavedShopService {
  static const String _savedShopsKey = 'saved_shops';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShopService _shopService = ShopService();

  /// Fetches multiple shops by ID in batch (delegates to ShopService).
  Future<List<RepairShop>> getShopsByIds(List<String> ids) async {
    return _shopService.getShopsByIds(ids);
  }

  /// Resolve the current user's saved shops using per-ID `doc.get()` so we
  /// can distinguish three outcomes for each ID:
  ///
  /// * `shops` — documents that loaded cleanly.
  /// * `confirmedMissing` — documents whose `doc.exists == false`, i.e. the
  ///   shop has been deleted from Firestore.
  /// * `unresolved` — the read threw (permission denied, offline, transient
  ///   error). These IDs should NOT be auto-deleted from the user's saved
  ///   list; the shop may come back online or an admin may re-approve it.
  ///
  /// QA bug: the previous implementation used a single `whereIn` query and
  /// treated any ID that wasn't returned as an orphan, which incorrectly
  /// deleted IDs for shops that were simply rules-blocked (e.g. pending
  /// re-approval). The badge count had already been cached before the list
  /// screen ran its cleanup, so the user saw a positive count alongside an
  /// empty list.
  Future<
          ({
            List<RepairShop> shops,
            List<String> confirmedMissing,
            List<String> unresolved,
          })>
      resolveSavedShopsSafely() async {
    final ids = await getSavedShopIds();
    if (ids.isEmpty) {
      return (shops: <RepairShop>[], confirmedMissing: <String>[], unresolved: <String>[]);
    }

    final shops = <RepairShop>[];
    final confirmedMissing = <String>[];
    final unresolved = <String>[];

    // Run per-ID reads in parallel; each one catches its own errors so a
    // single bad doc can't poison the whole batch.
    await Future.wait(ids.map((id) async {
      try {
        final doc = await _firestore.collection('shops').doc(id).get();
        if (!doc.exists) {
          confirmedMissing.add(id);
          return;
        }
        final data = doc.data();
        if (data == null) {
          unresolved.add(id);
          return;
        }
        data['id'] = doc.id;
        shops.add(RepairShop.fromMap(data));
      } catch (e) {
        appLog('Failed to resolve saved shop $id: $e');
        unresolved.add(id);
      }
    }));

    return (
      shops: shops,
      confirmedMissing: confirmedMissing,
      unresolved: unresolved,
    );
  }

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
        appLog('Error getting saved shops from Firestore: $e');
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
        appLog('Error saving shop to Firestore: $e');
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
        appLog('Error removing shop from Firestore: $e');
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
        appLog('Error checking if shop is saved in Firestore: $e');
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

  // Clean up orphaned saved shop IDs (shops that no longer exist)
  Future<void> cleanupOrphanedShops(List<String> orphanedIds) async {
    final user = _auth.currentUser;
    if (user != null && orphanedIds.isNotEmpty) {
      try {
        // Remove from Firestore in batch
        final batch = _firestore.batch();
        for (String orphanedId in orphanedIds) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('savedShops')
              .doc(orphanedId);
          batch.delete(docRef);
        }
        await batch.commit();
        appLog(
          'Cleaned up ${orphanedIds.length} orphaned saved shops from Firestore',
        );
      } catch (e) {
        appLog('Error cleaning up orphaned shops from Firestore: $e');
        // Fallback to individual removal from SharedPreferences
        for (String orphanedId in orphanedIds) {
          await _removeShopFromPrefs(orphanedId);
        }
      }
    } else {
      // Clean up from SharedPreferences for non-logged in users
      for (String orphanedId in orphanedIds) {
        await _removeShopFromPrefs(orphanedId);
      }
    }
  }
}
