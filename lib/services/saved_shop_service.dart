import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/repair_shop.dart';

class SavedShopService {
  static const String _savedShopsKey = 'saved_shops';

  // Get all saved shops
  Future<List<String>> getSavedShopIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList(_savedShopsKey) ?? [];
    return savedShops;
  }

  // Save a shop
  Future<bool> saveShop(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList(_savedShopsKey) ?? [];

    // Check if already saved
    if (savedShops.contains(shopId)) {
      return false; // Already saved
    }

    savedShops.add(shopId);
    return await prefs.setStringList(_savedShopsKey, savedShops);
  }

  // Remove a saved shop
  Future<bool> removeShop(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList(_savedShopsKey) ?? [];

    if (!savedShops.contains(shopId)) {
      return false; // Not in saved list
    }

    savedShops.remove(shopId);
    return await prefs.setStringList(_savedShopsKey, savedShops);
  }

  // Check if a shop is saved
  Future<bool> isShopSaved(String shopId) async {
    final savedShops = await getSavedShopIds();
    return savedShops.contains(shopId);
  }
}
