import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Service for caching shop data to reduce Firestore queries
class ShopCacheService {
  static const String _cacheKey = 'cached_shops';
  static const String _cacheTimestampKey = 'shops_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 1);

  /// Get cached shops if available and not expired
  static Future<List<RepairShop>?> getCachedShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) {
        appLog('No cache timestamp found');
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );

      if (cacheAge > _cacheValidityDuration) {
        appLog('Cache expired (age: ${cacheAge.inMinutes} minutes)');
        return null;
      }

      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) {
        appLog('No cached data found');
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      final shops = jsonList.map((json) => RepairShop.fromMap(json)).toList();
      
      appLog('Retrieved ${shops.length} shops from cache');
      return shops;
    } catch (e) {
      appLog('Error retrieving cached shops: $e');
      return null;
    }
  }

  /// Cache shops data
  static Future<void> cacheShops(List<RepairShop> shops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = shops.map((shop) => shop.toMap()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      appLog('Cached ${shops.length} shops successfully');
    } catch (e) {
      appLog('Error caching shops: $e');
    }
  }

  /// Clear cached shops
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      appLog('Shop cache cleared');
    } catch (e) {
      appLog('Error clearing shop cache: $e');
    }
  }

  /// Check if cache is valid
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) return false;
      
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      
      return cacheAge <= _cacheValidityDuration;
    } catch (e) {
      appLog('Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cache age in minutes
  static Future<int?> getCacheAgeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) return null;
      
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      
      return cacheAge.inMinutes;
    } catch (e) {
      appLog('Error getting cache age: $e');
      return null;
    }
  }
}
