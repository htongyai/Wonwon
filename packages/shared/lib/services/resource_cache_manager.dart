import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';

import 'resource_cache_io.dart'
    if (dart.library.html) 'resource_cache_web.dart' as platform_cache;

class ResourceCacheManager {
  static final ResourceCacheManager _instance =
      ResourceCacheManager._internal();
  factory ResourceCacheManager() => _instance;
  ResourceCacheManager._internal();

  static const Duration defaultCacheDuration = Duration(days: 7);
  final Map<String, dynamic> _memoryCache = {};

  Future<void> initialize() async {
    if (kIsWeb) return;
    await platform_cache.initializeDiskCache();
    await _cleanExpiredCache();
  }

  String _generateKey(String key) {
    return sha256.convert(utf8.encode(key)).toString();
  }

  Future<void> setCache<T>(
    String key,
    T value, {
    Duration duration = defaultCacheDuration,
  }) async {
    final cacheKey = _generateKey(key);
    _memoryCache[cacheKey] = {
      'value': value,
      'expiry': DateTime.now().add(duration).millisecondsSinceEpoch,
    };

    if (value is String || value is Map || value is List) {
      await platform_cache.writeToDisk(cacheKey, json.encode(value));
    }
  }

  Future<T?> getCache<T>(String key) async {
    final cacheKey = _generateKey(key);
    final cachedData = _memoryCache[cacheKey];

    if (cachedData != null) {
      if (DateTime.now().millisecondsSinceEpoch < cachedData['expiry']) {
        return cachedData['value'] as T;
      } else {
        _memoryCache.remove(cacheKey);
        await platform_cache.removeFromDisk(cacheKey);
      }
    }

    if (T == String || T == Map || T == List) {
      final content = await platform_cache.readFromDisk(cacheKey);
      if (content != null) {
        final diskData = json.decode(content);
        _memoryCache[cacheKey] = {
          'value': diskData,
          'expiry':
              DateTime.now().add(defaultCacheDuration).millisecondsSinceEpoch,
        };
        return diskData as T;
      }
    }

    return null;
  }

  Future<void> removeCache(String key) async {
    final cacheKey = _generateKey(key);
    _memoryCache.remove(cacheKey);
    await platform_cache.removeFromDisk(cacheKey);
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    await platform_cache.clearDiskCache();
  }

  Future<void> _cleanExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _memoryCache.removeWhere((key, value) => value['expiry'] < now);
    await platform_cache.cleanExpiredDiskCache(
        now - defaultCacheDuration.inMilliseconds);
  }
}
