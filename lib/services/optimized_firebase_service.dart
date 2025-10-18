import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'dart:async';
import 'dart:collection';

/// Optimized Firebase service with caching, query optimization, and performance monitoring
class OptimizedFirebaseService {
  static final OptimizedFirebaseService _instance =
      OptimizedFirebaseService._internal();
  factory OptimizedFirebaseService() => _instance;
  OptimizedFirebaseService._internal();

  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Performance monitoring
  static final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Caching system
  static final Map<String, dynamic> _cache = HashMap();
  static final Map<String, DateTime> _cacheTimestamps = HashMap();
  static final Map<String, StreamSubscription> _activeSubscriptions = HashMap();

  // Cache configuration
  static const int _maxCacheSize = 200;
  static const Duration _defaultCacheExpiry = Duration(minutes: 10);

  // Query optimization
  static const int _defaultLimit = 20;
  static const int _maxLimit = 100;

  /// Get current user with null safety
  static User? get currentUser => _auth.currentUser;

  /// Optimized query with caching and performance monitoring
  static Future<List<T>> getCollection<T>({
    required String collection,
    required T Function(Map<String, dynamic>, String) fromMap,
    String? whereField,
    dynamic whereValue,
    String? orderBy,
    bool descending = true,
    int? limit,
    bool useCache = true,
    Duration? cacheExpiry,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cacheKey =
        '${collection}_${whereField}_${whereValue}_${orderBy}_${descending}_${limit}';

    try {
      _performanceMonitor.startOperation('getCollection_$collection');

      // Check cache first
      if (useCache &&
          _cache.containsKey(cacheKey) &&
          _isCacheValid(cacheKey, cacheExpiry)) {
        appLog('Data retrieved from cache for collection: $collection');
        return List<T>.from(_cache[cacheKey]);
      }

      // Build query
      Query query = _firestore.collection(collection);

      // Apply filters
      if (whereField != null && whereValue != null) {
        query = query.where(whereField, isEqualTo: whereValue);
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      final queryLimit = (limit ?? _defaultLimit).clamp(1, _maxLimit);
      query = query.limit(queryLimit);

      // Execute query
      final snapshot = await query.get();
      final results = <T>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final item = fromMap(data, doc.id);
          results.add(item);
        } catch (e) {
          appLog('Error parsing document ${doc.id}: $e');
        }
      }

      // Cache results
      if (useCache) {
        _cacheData(cacheKey, results, cacheExpiry);
      }

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'getCollection_$collection',
        stopwatch.elapsed,
      );

      return results;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getCollection_$collection', e);
      appLog('Error in getCollection: $e');
      return [];
    }
  }

  /// Optimized stream query with caching
  static Stream<List<T>> getCollectionStream<T>({
    required String collection,
    required T Function(Map<String, dynamic>, String) fromMap,
    String? whereField,
    dynamic whereValue,
    String? orderBy,
    bool descending = true,
    int? limit,
    bool useCache = true,
    Duration? cacheExpiry,
  }) {
    final cacheKey =
        '${collection}_stream_${whereField}_${whereValue}_${orderBy}_${descending}_${limit}';

    try {
      _performanceMonitor.startOperation('getCollectionStream_$collection');

      // Build query
      Query query = _firestore.collection(collection);

      // Apply filters
      if (whereField != null && whereValue != null) {
        query = query.where(whereField, isEqualTo: whereValue);
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      final queryLimit = (limit ?? _defaultLimit).clamp(1, _maxLimit);
      query = query.limit(queryLimit);

      return query
          .snapshots()
          .map((snapshot) {
            final results = <T>[];

            for (var doc in snapshot.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                final item = fromMap(data, doc.id);
                results.add(item);
              } catch (e) {
                appLog('Error parsing document ${doc.id}: $e');
              }
            }

            // Cache results
            if (useCache) {
              _cacheData(cacheKey, results, cacheExpiry);
            }

            return results;
          })
          .handleError((error) {
            _performanceMonitor.recordError(
              'getCollectionStream_$collection',
              error,
            );
            appLog('Error in getCollectionStream: $error');
            return <T>[];
          });
    } catch (e) {
      _performanceMonitor.recordError('getCollectionStream_$collection', e);
      appLog('Error setting up getCollectionStream: $e');
      return Stream.value([]);
    }
  }

  /// Get single document with caching
  static Future<T?> getDocument<T>({
    required String collection,
    required String documentId,
    required T Function(Map<String, dynamic>, String) fromMap,
    bool useCache = true,
    Duration? cacheExpiry,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cacheKey = '${collection}_doc_$documentId';

    try {
      _performanceMonitor.startOperation('getDocument_$collection');

      // Check cache first
      if (useCache &&
          _cache.containsKey(cacheKey) &&
          _isCacheValid(cacheKey, cacheExpiry)) {
        appLog('Document retrieved from cache: $documentId');
        return _cache[cacheKey] as T?;
      }

      // Get document
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final result = fromMap(data, doc.id);

      // Cache result
      if (useCache) {
        _cacheData(cacheKey, result, cacheExpiry);
      }

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'getDocument_$collection',
        stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getDocument_$collection', e);
      appLog('Error in getDocument: $e');
      return null;
    }
  }

  /// Add document with optimistic updates
  static Future<String?> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('addDocument_$collection');

      DocumentReference docRef;
      if (documentId != null) {
        docRef = _firestore.collection(collection).doc(documentId);
      } else {
        docRef = _firestore.collection(collection).doc();
      }

      await docRef.set(data);

      // Clear related cache entries
      _clearCacheByPrefix(collection);

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'addDocument_$collection',
        stopwatch.elapsed,
      );

      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('addDocument_$collection', e);
      appLog('Error in addDocument: $e');
      return null;
    }
  }

  /// Update document with optimistic updates
  static Future<bool> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('updateDocument_$collection');

      await _firestore.collection(collection).doc(documentId).update(data);

      // Clear related cache entries
      _clearCacheByPrefix(collection);
      _clearCacheByPrefix('${collection}_doc_$documentId');

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'updateDocument_$collection',
        stopwatch.elapsed,
      );

      return true;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('updateDocument_$collection', e);
      appLog('Error in updateDocument: $e');
      return false;
    }
  }

  /// Delete document with cache cleanup
  static Future<bool> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('deleteDocument_$collection');

      await _firestore.collection(collection).doc(documentId).delete();

      // Clear related cache entries
      _clearCacheByPrefix(collection);
      _clearCacheByPrefix('${collection}_doc_$documentId');

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'deleteDocument_$collection',
        stopwatch.elapsed,
      );

      return true;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('deleteDocument_$collection', e);
      appLog('Error in deleteDocument: $e');
      return false;
    }
  }

  /// Batch operations for better performance
  static Future<bool> batchWrite({
    required List<Map<String, dynamic>> operations,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('batchWrite');

      final batch = _firestore.batch();

      for (var operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final documentId = operation['documentId'] as String?;
        final data = operation['data'] as Map<String, dynamic>;

        final docRef =
            documentId != null
                ? _firestore.collection(collection).doc(documentId)
                : _firestore.collection(collection).doc();

        switch (type) {
          case 'set':
            batch.set(docRef, data);
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();

      // Clear all cache
      _clearAllCache();

      stopwatch.stop();
      _performanceMonitor.endOperation('batchWrite', stopwatch.elapsed);

      return true;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('batchWrite', e);
      appLog('Error in batchWrite: $e');
      return false;
    }
  }

  /// Cache management
  static void _cacheData(String key, dynamic data, Duration? expiry) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Enforce cache size limit
    if (_cache.length > _maxCacheSize) {
      _cleanupOldCache();
    }
  }

  static bool _isCacheValid(String key, Duration? expiry) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final cacheTime = _cacheTimestamps[key]!;
    final expiryDuration = expiry ?? _defaultCacheExpiry;
    final isValid = DateTime.now().difference(cacheTime) < expiryDuration;

    if (!isValid) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    return isValid;
  }

  static void _clearCacheByPrefix(String prefix) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (var key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static void _clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void _cleanupOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (var entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheExpiry) {
        keysToRemove.add(entry.key);
      }
    }

    for (var key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Dispose resources
  static void dispose() {
    for (var subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    _clearAllCache();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'maxCacheSize': _maxCacheSize,
      'activeSubscriptions': _activeSubscriptions.length,
      'cacheKeys': _cache.keys.toList(),
    };
  }
}
