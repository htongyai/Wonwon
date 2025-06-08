import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class ResourceCacheManager {
  static final ResourceCacheManager _instance =
      ResourceCacheManager._internal();
  factory ResourceCacheManager() => _instance;
  ResourceCacheManager._internal();

  static const Duration defaultCacheDuration = Duration(days: 7);
  final Map<String, dynamic> _memoryCache = {};
  Directory? _cacheDirectory;

  Future<void> initialize() async {
    _cacheDirectory = await getTemporaryDirectory();
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
      await _writeToDisk(cacheKey, value);
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
        await _removeFromDisk(cacheKey);
      }
    }

    if (T == String || T == Map || T == List) {
      final diskData = await _readFromDisk(cacheKey);
      if (diskData != null) {
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
    await _removeFromDisk(cacheKey);
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    if (_cacheDirectory != null) {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create();
    }
  }

  Future<void> _cleanExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _memoryCache.removeWhere((key, value) => value['expiry'] < now);

    if (_cacheDirectory != null) {
      final files = await _cacheDirectory!.list().toList();
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.millisecondsSinceEpoch <
              now - defaultCacheDuration.inMilliseconds) {
            await file.delete();
          }
        }
      }
    }
  }

  Future<void> _writeToDisk(String key, dynamic value) async {
    if (_cacheDirectory == null) return;

    final file = File('${_cacheDirectory!.path}/$key');
    await file.writeAsString(json.encode(value));
  }

  Future<dynamic> _readFromDisk(String key) async {
    if (_cacheDirectory == null) return null;

    final file = File('${_cacheDirectory!.path}/$key');
    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    }
    return null;
  }

  Future<void> _removeFromDisk(String key) async {
    if (_cacheDirectory == null) return;

    final file = File('${_cacheDirectory!.path}/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
