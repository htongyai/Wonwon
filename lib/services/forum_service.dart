import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/models/forum_topic.dart';
import 'package:wonwonw2/models/forum_reply.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/services/notification_service.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/services/moderator_service.dart';
import 'dart:async';
import 'dart:collection';

/// Optimized Forum Service with caching, performance monitoring, and better error handling
class ForumService {
  // Singleton pattern for better resource management
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  ForumService._internal();

  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static CollectionReference get _topicsCollection =>
      _firestore.collection('forum_topics');

  static CollectionReference _getRepliesCollection(String topicId) =>
      _topicsCollection.doc(topicId).collection('replies');

  // Performance monitoring
  static final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Caching system
  static final Map<String, ForumTopic> _topicCache = HashMap();
  static final Map<String, List<ForumReply>> _repliesCache = HashMap();
  static final Map<String, StreamSubscription> _activeSubscriptions = HashMap();

  // Cache configuration
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(minutes: 10);
  static final Map<String, DateTime> _cacheTimestamps = HashMap();

  // Query optimization
  static const int _defaultLimit = 20;
  static const int _maxLimit = 100;

  // Get current user with null safety
  static User? get _currentUser => _auth.currentUser;

  /// Create a new topic with optimized performance
  static Future<String> createTopic({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('createTopic');

      if (_currentUser == null) {
        throw Exception('User must be logged in to create a topic');
      }

      // Validate input
      if (title.trim().isEmpty || content.trim().isEmpty) {
        throw Exception('Title and content cannot be empty');
      }

      final topicData = {
        'title': title.trim(),
        'content': content.trim(),
        'authorId': _currentUser!.uid,
        'authorName':
            _currentUser!.displayName ?? _currentUser!.email ?? 'Anonymous',
        'category': category,
        'createdAt': Timestamp.now(),
        'lastActivity': Timestamp.now(),
        'replies': 0,
        'views': 0,
        'isPinned': false,
        'isLocked': false,
        'tags': tags,
        'metadata': {
          'wordCount': content.trim().split(' ').length,
          'charCount': content.trim().length,
        },
      };

      appLog('Creating topic with optimized data structure');
      final docRef = await _topicsCollection.add(topicData);

      // Invalidate cache
      _clearTopicCache();

      stopwatch.stop();
      _performanceMonitor.endOperation('createTopic', stopwatch.elapsed);

      appLog(
        'Topic created successfully in ${stopwatch.elapsedMilliseconds}ms',
      );
      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('createTopic', e);
      appLog('Error creating topic: $e');
      rethrow;
    }
  }

  /// Get topics with optimized querying and caching
  static Stream<List<ForumTopic>> getTopics({
    String? category,
    String? searchQuery,
    bool? isPinned,
    int limit = _defaultLimit,
  }) {
    final stopwatch = Stopwatch()..start();
    final cacheKey = 'topics_${category}_${searchQuery}_${isPinned}_$limit';

    try {
      _performanceMonitor.startOperation('getTopics');

      // Validate limit
      limit = limit.clamp(1, _maxLimit);

      // Build optimized query
      Query query = _topicsCollection
          .orderBy('lastActivity', descending: true)
          .limit(limit);

      // Apply server-side filters when possible
      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      return query
          .snapshots()
          .map((snapshot) {
            List<ForumTopic> topics = [];

            for (var doc in snapshot.docs) {
              try {
                final topic = ForumTopic.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );

                // Filter out hidden and deleted topics
                if (topic.isHidden || topic.isDeleted) {
                  continue;
                }

                // Apply client-side filters
                if (category != null &&
                    category != 'all' &&
                    topic.category != category) {
                  continue;
                }

                if (searchQuery != null && searchQuery.isNotEmpty) {
                  final query = searchQuery.toLowerCase();
                  if (!_matchesSearchQuery(topic, query)) {
                    continue;
                  }
                }

                topics.add(topic);
              } catch (e) {
                appLog('Error parsing topic ${doc.id}: $e');
              }
            }

            // Cache results
            _cacheTopics(cacheKey, topics);

            stopwatch.stop();
            _performanceMonitor.endOperation('getTopics', stopwatch.elapsed);

            return topics;
          })
          .handleError((error) {
            stopwatch.stop();
            _performanceMonitor.recordError('getTopics', error);
            appLog('Error in getTopics stream: $error');
            return <ForumTopic>[];
          });
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getTopics', e);
      appLog('Error setting up getTopics: $e');
      return Stream.value([]);
    }
  }

  /// Get a single topic with caching
  static Future<ForumTopic?> getTopic(String topicId) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('getTopic');

      // Check cache first
      if (_topicCache.containsKey(topicId) && _isCacheValid(topicId)) {
        appLog('Topic retrieved from cache: $topicId');
        return _topicCache[topicId];
      }

      final doc = await _topicsCollection.doc(topicId).get();
      if (doc.exists) {
        final topic = ForumTopic.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Cache the topic
        _cacheTopic(topicId, topic);

        stopwatch.stop();
        _performanceMonitor.endOperation('getTopic', stopwatch.elapsed);

        return topic;
      }
      return null;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getTopic', e);
      appLog('Error getting topic $topicId: $e');
      return null;
    }
  }

  /// Create a reply with optimized performance
  static Future<String> createReply({
    required String topicId,
    required String content,
    String? parentReplyId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('createReply');

      if (_currentUser == null) {
        throw Exception('User must be logged in to create a reply');
      }

      if (content.trim().isEmpty) {
        throw Exception('Reply content cannot be empty');
      }

      final replyData = {
        'topicId': topicId,
        'content': content.trim(),
        'authorId': _currentUser!.uid,
        'authorName':
            _currentUser!.displayName ?? _currentUser!.email ?? 'Anonymous',
        'createdAt': Timestamp.now(),
        'editedAt': null,
        'likes': 0,
        'likedBy': [],
        'isSolution': false,
        'parentReplyId': parentReplyId,
        'metadata': {
          'wordCount': content.trim().split(' ').length,
          'charCount': content.trim().length,
        },
      };

      appLog('Creating reply with optimized data structure');
      final docRef = await _getRepliesCollection(topicId).add(replyData);

      // Update topic atomically
      await _updateTopicActivity(topicId);

      // Invalidate caches
      _clearRepliesCache(topicId);
      _clearTopicCache();

      // Create notification asynchronously
      _createReplyNotificationAsync(topicId, content);

      stopwatch.stop();
      _performanceMonitor.endOperation('createReply', stopwatch.elapsed);

      appLog(
        'Reply created successfully in ${stopwatch.elapsedMilliseconds}ms',
      );
      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('createReply', e);
      appLog('Error creating reply: $e');
      rethrow;
    }
  }

  /// Get replies with optimized querying and caching
  static Stream<List<ForumReply>> getReplies(String topicId) {
    final stopwatch = Stopwatch()..start();
    final cacheKey = 'replies_$topicId';

    try {
      _performanceMonitor.startOperation('getReplies');

      // Check cache first
      if (_repliesCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        appLog('Replies retrieved from cache for topic: $topicId');
        return Stream.value(_repliesCache[cacheKey]!);
      }

      return _getRepliesCollection(topicId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            List<ForumReply> replies = [];

            for (var doc in snapshot.docs) {
              try {
                final reply = ForumReply.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );

                // Filter out hidden and deleted replies
                if (reply.isHidden || reply.isDeleted) {
                  continue;
                }

                // Filter top-level replies
                if (reply.parentReplyId == null) {
                  replies.add(reply);
                }
              } catch (e) {
                appLog('Error parsing reply ${doc.id}: $e');
              }
            }

            // Sort and cache
            replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _cacheReplies(cacheKey, replies);

            stopwatch.stop();
            _performanceMonitor.endOperation('getReplies', stopwatch.elapsed);

            return replies;
          })
          .handleError((error) {
            stopwatch.stop();
            _performanceMonitor.recordError('getReplies', error);
            appLog('Error in getReplies stream: $error');
            return <ForumReply>[];
          });
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getReplies', e);
      appLog('Error setting up getReplies: $e');
      return Stream.value([]);
    }
  }

  /// Get nested replies with optimized querying
  static Stream<List<ForumReply>> getNestedReplies(
    String topicId,
    String parentReplyId,
  ) {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('getNestedReplies');

      return _getRepliesCollection(topicId)
          .where('parentReplyId', isEqualTo: parentReplyId)
          .orderBy('createdAt', descending: false)
          .limit(50) // Limit nested replies to prevent performance issues
          .snapshots()
          .map((snapshot) {
            List<ForumReply> replies = [];

            for (var doc in snapshot.docs) {
              try {
                final reply = ForumReply.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                replies.add(reply);
              } catch (e) {
                appLog('Error parsing nested reply ${doc.id}: $e');
              }
            }

            stopwatch.stop();
            _performanceMonitor.endOperation(
              'getNestedReplies',
              stopwatch.elapsed,
            );

            return replies;
          })
          .handleError((error) {
            stopwatch.stop();
            _performanceMonitor.recordError('getNestedReplies', error);
            appLog('Error in getNestedReplies stream: $error');
            return <ForumReply>[];
          });
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('getNestedReplies', e);
      appLog('Error setting up getNestedReplies: $e');
      return Stream.value([]);
    }
  }

  /// Optimized like/unlike functionality
  static Future<void> toggleReplyLike(String topicId, String replyId) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('toggleReplyLike');

      if (_currentUser == null) {
        throw Exception('User must be logged in to like a reply');
      }

      final userId = _currentUser!.uid;
      final replyRef = _getRepliesCollection(topicId).doc(replyId);

      // Use transaction for atomic update
      await _firestore.runTransaction((transaction) async {
        final replyDoc = await transaction.get(replyRef);

        if (!replyDoc.exists) {
          throw Exception('Reply not found');
        }

        final replyData = replyDoc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(replyData['likedBy'] ?? []);
        final currentLikes = replyData['likes'] ?? 0;

        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
          transaction.update(replyRef, {
            'likes': currentLikes - 1,
            'likedBy': likedBy,
          });
        } else {
          // Like
          likedBy.add(userId);
          transaction.update(replyRef, {
            'likes': currentLikes + 1,
            'likedBy': likedBy,
          });

          // Create notification asynchronously
          _createLikeNotificationAsync(topicId, replyData);
        }
      });

      // Invalidate cache
      _clearRepliesCache(topicId);

      stopwatch.stop();
      _performanceMonitor.endOperation('toggleReplyLike', stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('toggleReplyLike', e);
      appLog('Error toggling reply like: $e');
      rethrow;
    }
  }

  /// Mark reply as solution
  static Future<void> markReplyAsSolution(
    String topicId,
    String replyId,
    bool isSolution,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('markReplyAsSolution');

      await _getRepliesCollection(
        topicId,
      ).doc(replyId).update({'isSolution': isSolution});

      // Invalidate cache
      _clearRepliesCache(topicId);

      stopwatch.stop();
      _performanceMonitor.endOperation(
        'markReplyAsSolution',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('markReplyAsSolution', e);
      appLog('Error marking reply as solution: $e');
      rethrow;
    }
  }

  /// Optimized topic deletion with batch operations
  static Future<void> deleteTopic(String topicId) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('deleteTopic');

      if (_currentUser == null) {
        throw Exception('User must be logged in to delete a topic');
      }

      final topic = await getTopic(topicId);
      if (topic == null) {
        throw Exception('Topic not found');
      }

      // Check permissions
      if (topic.authorId != _currentUser!.uid) {
        throw Exception('Only the author can delete this topic');
      }

      // Delete all replies first
      final repliesSnapshot = await _getRepliesCollection(topicId).get();
      final batch = _firestore.batch();

      for (var doc in repliesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the topic
      batch.delete(_topicsCollection.doc(topicId));

      await batch.commit();

      // Clear caches
      _clearTopicCache();
      _clearRepliesCache(topicId);

      stopwatch.stop();
      _performanceMonitor.endOperation('deleteTopic', stopwatch.elapsed);

      appLog('Topic and all replies deleted successfully');
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('deleteTopic', e);
      appLog('Error deleting topic: $e');
      rethrow;
    }
  }

  /// Optimized reply deletion
  static Future<void> deleteReply(String topicId, String replyId) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('deleteReply');

      if (_currentUser == null) {
        throw Exception('User must be logged in to delete a reply');
      }

      final replyDoc = await _getRepliesCollection(topicId).doc(replyId).get();
      if (!replyDoc.exists) {
        throw Exception('Reply not found');
      }

      final replyData = replyDoc.data() as Map<String, dynamic>;
      final replyAuthorId = replyData['authorId'] as String;

      // Check permissions
      if (replyAuthorId != _currentUser!.uid) {
        throw Exception('Only the author can delete this reply');
      }

      // Delete the reply
      await _getRepliesCollection(topicId).doc(replyId).delete();

      // Update topic activity
      await _updateTopicActivity(topicId);

      // Clear cache
      _clearRepliesCache(topicId);

      stopwatch.stop();
      _performanceMonitor.endOperation('deleteReply', stopwatch.elapsed);

      appLog('Reply deleted successfully');
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('deleteReply', e);
      appLog('Error deleting reply: $e');
      rethrow;
    }
  }

  /// Update topic views with debouncing
  static Future<void> incrementTopicViews(String topicId) async {
    try {
      await _topicsCollection.doc(topicId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      appLog('Error incrementing topic views: $e');
    }
  }

  /// Pin/unpin a topic (admin only)
  static Future<void> toggleTopicPin(String topicId, bool isPinned) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('toggleTopicPin');

      await _topicsCollection.doc(topicId).update({'isPinned': isPinned});

      // Clear cache
      _clearTopicCache();

      stopwatch.stop();
      _performanceMonitor.endOperation('toggleTopicPin', stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('toggleTopicPin', e);
      appLog('Error toggling topic pin: $e');
      rethrow;
    }
  }

  /// Lock/unlock a topic (admin only)
  static Future<void> toggleTopicLock(String topicId, bool isLocked) async {
    final stopwatch = Stopwatch()..start();

    try {
      _performanceMonitor.startOperation('toggleTopicLock');

      await _topicsCollection.doc(topicId).update({'isLocked': isLocked});

      // Clear cache
      _clearTopicCache();

      stopwatch.stop();
      _performanceMonitor.endOperation('toggleTopicLock', stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordError('toggleTopicLock', e);
      appLog('Error toggling topic lock: $e');
      rethrow;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Check if cache is still valid
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Cache a topic
  static void _cacheTopic(String topicId, ForumTopic topic) {
    if (_topicCache.length >= _maxCacheSize) {
      _evictOldestCacheEntry(_topicCache, _cacheTimestamps);
    }
    _topicCache[topicId] = topic;
    _cacheTimestamps[topicId] = DateTime.now();
  }

  /// Cache topics list
  static void _cacheTopics(String key, List<ForumTopic> topics) {
    // For topic lists, we don't cache individual topics to avoid duplication
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Cache replies
  static void _cacheReplies(String key, List<ForumReply> replies) {
    if (_repliesCache.length >= _maxCacheSize) {
      _evictOldestCacheEntry(_repliesCache, _cacheTimestamps);
    }
    _repliesCache[key] = replies;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Evict oldest cache entry
  static void _evictOldestCacheEntry(
    Map cache,
    Map<String, DateTime> timestamps,
  ) {
    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in timestamps.entries) {
      if (cache.containsKey(entry.key) &&
          (oldestTime == null || entry.value.isBefore(oldestTime))) {
        oldestKey = entry.key;
        oldestTime = entry.value;
      }
    }

    if (oldestKey != null) {
      cache.remove(oldestKey);
      timestamps.remove(oldestKey);
    }
  }

  /// Clear topic cache
  static void _clearTopicCache() {
    _topicCache.clear();
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('topic_'));
  }

  /// Clear replies cache for a topic
  static void _clearRepliesCache(String topicId) {
    final key = 'replies_$topicId';
    _repliesCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Update topic activity
  static Future<void> _updateTopicActivity(String topicId) async {
    await _topicsCollection.doc(topicId).update({
      'replies': FieldValue.increment(1),
      'lastActivity': Timestamp.now(),
    });
  }

  /// Search query matching
  static bool _matchesSearchQuery(ForumTopic topic, String query) {
    return topic.title.toLowerCase().contains(query) ||
        topic.content.toLowerCase().contains(query) ||
        topic.authorName.toLowerCase().contains(query) ||
        topic.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  /// Create reply notification asynchronously
  static void _createReplyNotificationAsync(String topicId, String content) {
    Future.microtask(() async {
      try {
        final topicDoc = await _topicsCollection.doc(topicId).get();
        if (topicDoc.exists) {
          final topicData = topicDoc.data() as Map<String, dynamic>;
          final topicTitle = topicData['title'] as String;
          final topicAuthorId = topicData['authorId'] as String;
          final authorName =
              _currentUser?.displayName ?? _currentUser?.email ?? 'Anonymous';

          if (topicAuthorId != _currentUser?.uid) {
            await NotificationService.createForumReplyNotification(
              topicId: topicId,
              topicTitle: topicTitle,
              authorId: _currentUser!.uid,
              authorName: authorName,
              replyContent: content.trim(),
            );
          }
        }
      } catch (e) {
        appLog('Error creating notification for reply: $e');
      }
    });
  }

  /// Create like notification asynchronously
  static void _createLikeNotificationAsync(
    String topicId,
    Map<String, dynamic> replyData,
  ) {
    Future.microtask(() async {
      try {
        final replyAuthorId = replyData['authorId'] as String;
        final likerName =
            _currentUser?.displayName ?? _currentUser?.email ?? 'Anonymous';

        if (replyAuthorId != _currentUser?.uid) {
          final topicDoc = await _topicsCollection.doc(topicId).get();
          if (topicDoc.exists) {
            final topicData = topicDoc.data() as Map<String, dynamic>;
            final topicTitle = topicData['title'] as String;

            await NotificationService.createForumLikeNotification(
              topicId: topicId,
              topicTitle: topicTitle,
              likerId: _currentUser!.uid,
              likerName: likerName,
            );
          }
        }
      } catch (e) {
        appLog('Error creating notification for like: $e');
      }
    });
  }

  // ==================== MODERATOR METHODS ====================

  /// Hide a topic (admin only)
  static Future<bool> hideTopic(String topicId, String reason) async {
    return await ModeratorService.hideTopic(topicId, reason);
  }

  /// Unhide a topic (admin only)
  static Future<bool> unhideTopic(String topicId) async {
    return await ModeratorService.unhideTopic(topicId);
  }

  /// Delete a topic (admin only)
  static Future<bool> adminDeleteTopic(String topicId, String reason) async {
    return await ModeratorService.deleteTopic(topicId, reason);
  }

  /// Restore a deleted topic (admin only)
  static Future<bool> restoreTopic(String topicId) async {
    return await ModeratorService.restoreTopic(topicId);
  }

  /// Lock a topic (admin only)
  static Future<bool> lockTopic(String topicId, String reason) async {
    return await ModeratorService.lockTopic(topicId, reason);
  }

  /// Unlock a topic (admin only)
  static Future<bool> unlockTopic(String topicId) async {
    return await ModeratorService.unlockTopic(topicId);
  }

  /// Pin a topic (admin only)
  static Future<bool> pinTopic(String topicId) async {
    return await ModeratorService.pinTopic(topicId);
  }

  /// Unpin a topic (admin only)
  static Future<bool> unpinTopic(String topicId) async {
    return await ModeratorService.unpinTopic(topicId);
  }

  /// Hide a reply (admin only)
  static Future<bool> hideReply(
    String topicId,
    String replyId,
    String reason,
  ) async {
    return await ModeratorService.hideReply(topicId, replyId, reason);
  }

  /// Unhide a reply (admin only)
  static Future<bool> unhideReply(String topicId, String replyId) async {
    return await ModeratorService.unhideReply(topicId, replyId);
  }

  /// Delete a reply (admin only)
  static Future<bool> adminDeleteReply(
    String topicId,
    String replyId,
    String reason,
  ) async {
    return await ModeratorService.deleteReply(topicId, replyId, reason);
  }

  /// Restore a deleted reply (admin only)
  static Future<bool> restoreReply(String topicId, String replyId) async {
    return await ModeratorService.restoreReply(topicId, replyId);
  }

  /// Get moderation history for a topic (admin only)
  static Future<Map<String, dynamic>?> getTopicModerationHistory(
    String topicId,
  ) async {
    return await ModeratorService.getTopicModerationHistory(topicId);
  }

  /// Get moderation history for a reply (admin only)
  static Future<Map<String, dynamic>?> getReplyModerationHistory(
    String topicId,
    String replyId,
  ) async {
    return await ModeratorService.getReplyModerationHistory(topicId, replyId);
  }

  /// Get all moderated content (admin only)
  static Future<List<Map<String, dynamic>>> getModeratedContent() async {
    return await ModeratorService.getModeratedContent();
  }

  /// Dispose resources
  static void dispose() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    _topicCache.clear();
    _repliesCache.clear();
    _cacheTimestamps.clear();
  }
}
