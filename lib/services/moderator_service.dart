import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Service for forum moderation functions - Admin only
class ModeratorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final AuthService _authService = AuthService();

  /// Check if current user is admin
  static Future<bool> _isAdmin() async {
    try {
      return await _authService.isAdmin();
    } catch (e) {
      appLog('Error checking admin status: $e');
      return false;
    }
  }

  /// Hide a forum topic (admin only)
  static Future<bool> hideTopic(String topicId, String reason) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can hide topics');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isHidden': true,
        'moderationReason': reason,
        'moderatedBy': currentUser.uid,
        'moderatedAt': Timestamp.now(),
      });

      appLog('Topic hidden successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error hiding topic: $e');
      return false;
    }
  }

  /// Unhide a forum topic (admin only)
  static Future<bool> unhideTopic(String topicId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can unhide topics');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isHidden': false,
        'moderationReason': null,
        'moderatedBy': null,
        'moderatedAt': null,
      });

      appLog('Topic unhidden successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error unhiding topic: $e');
      return false;
    }
  }

  /// Delete a forum topic (admin only)
  static Future<bool> deleteTopic(String topicId, String reason) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can delete topics');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      // Mark as deleted instead of actually deleting
      await _firestore.collection('forum_topics').doc(topicId).update({
        'isDeleted': true,
        'moderationReason': reason,
        'moderatedBy': currentUser.uid,
        'moderatedAt': Timestamp.now(),
      });

      appLog('Topic deleted successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error deleting topic: $e');
      return false;
    }
  }

  /// Restore a deleted forum topic (admin only)
  static Future<bool> restoreTopic(String topicId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can restore topics');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isDeleted': false,
        'moderationReason': null,
        'moderatedBy': null,
        'moderatedAt': null,
      });

      appLog('Topic restored successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error restoring topic: $e');
      return false;
    }
  }

  /// Lock a forum topic (admin only)
  static Future<bool> lockTopic(String topicId, String reason) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can lock topics');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isLocked': true,
        'moderationReason': reason,
        'moderatedBy': currentUser.uid,
        'moderatedAt': Timestamp.now(),
      });

      appLog('Topic locked successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error locking topic: $e');
      return false;
    }
  }

  /// Unlock a forum topic (admin only)
  static Future<bool> unlockTopic(String topicId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can unlock topics');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isLocked': false,
        'moderationReason': null,
        'moderatedBy': null,
        'moderatedAt': null,
      });

      appLog('Topic unlocked successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error unlocking topic: $e');
      return false;
    }
  }

  /// Pin a forum topic (admin only)
  static Future<bool> pinTopic(String topicId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can pin topics');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isPinned': true,
      });

      appLog('Topic pinned successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error pinning topic: $e');
      return false;
    }
  }

  /// Unpin a forum topic (admin only)
  static Future<bool> unpinTopic(String topicId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can unpin topics');
      }

      await _firestore.collection('forum_topics').doc(topicId).update({
        'isPinned': false,
      });

      appLog('Topic unpinned successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error unpinning topic: $e');
      return false;
    }
  }

  /// Hide a forum reply (admin only)
  static Future<bool> hideReply(
    String topicId,
    String replyId,
    String reason,
  ) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can hide replies');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      await _firestore
          .collection('forum_topics')
          .doc(topicId)
          .collection('replies')
          .doc(replyId)
          .update({
            'isHidden': true,
            'moderationReason': reason,
            'moderatedBy': currentUser.uid,
            'moderatedAt': Timestamp.now(),
          });

      appLog('Reply hidden successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error hiding reply: $e');
      return false;
    }
  }

  /// Unhide a forum reply (admin only)
  static Future<bool> unhideReply(String topicId, String replyId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can unhide replies');
      }

      await _firestore
          .collection('forum_topics')
          .doc(topicId)
          .collection('replies')
          .doc(replyId)
          .update({
            'isHidden': false,
            'moderationReason': null,
            'moderatedBy': null,
            'moderatedAt': null,
          });

      appLog('Reply unhidden successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error unhiding reply: $e');
      return false;
    }
  }

  /// Delete a forum reply (admin only)
  static Future<bool> deleteReply(
    String topicId,
    String replyId,
    String reason,
  ) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can delete replies');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      // Mark as deleted instead of actually deleting
      await _firestore
          .collection('forum_topics')
          .doc(topicId)
          .collection('replies')
          .doc(replyId)
          .update({
            'isDeleted': true,
            'moderationReason': reason,
            'moderatedBy': currentUser.uid,
            'moderatedAt': Timestamp.now(),
          });

      appLog('Reply deleted successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error deleting reply: $e');
      return false;
    }
  }

  /// Restore a deleted forum reply (admin only)
  static Future<bool> restoreReply(String topicId, String replyId) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can restore replies');
      }

      await _firestore
          .collection('forum_topics')
          .doc(topicId)
          .collection('replies')
          .doc(replyId)
          .update({
            'isDeleted': false,
            'moderationReason': null,
            'moderatedBy': null,
            'moderatedAt': null,
          });

      appLog('Reply restored successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error restoring reply: $e');
      return false;
    }
  }

  /// Get moderation history for a topic
  static Future<Map<String, dynamic>?> getTopicModerationHistory(
    String topicId,
  ) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can view moderation history');
      }

      final doc =
          await _firestore.collection('forum_topics').doc(topicId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'isHidden': data['isHidden'] ?? false,
        'isDeleted': data['isDeleted'] ?? false,
        'isLocked': data['isLocked'] ?? false,
        'isPinned': data['isPinned'] ?? false,
        'moderationReason': data['moderationReason'],
        'moderatedBy': data['moderatedBy'],
        'moderatedAt': data['moderatedAt'],
      };
    } catch (e) {
      appLog('Error getting moderation history: $e');
      return null;
    }
  }

  /// Get moderation history for a reply
  static Future<Map<String, dynamic>?> getReplyModerationHistory(
    String topicId,
    String replyId,
  ) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can view moderation history');
      }

      final doc =
          await _firestore
              .collection('forum_topics')
              .doc(topicId)
              .collection('replies')
              .doc(replyId)
              .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'isHidden': data['isHidden'] ?? false,
        'isDeleted': data['isDeleted'] ?? false,
        'moderationReason': data['moderationReason'],
        'moderatedBy': data['moderatedBy'],
        'moderatedAt': data['moderatedAt'],
      };
    } catch (e) {
      appLog('Error getting moderation history: $e');
      return null;
    }
  }

  /// Get all moderated content (admin only)
  static Future<List<Map<String, dynamic>>> getModeratedContent() async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can view moderated content');
      }

      final topicsQuery =
          await _firestore
              .collection('forum_topics')
              .where('isHidden', isEqualTo: true)
              .get();

      final deletedTopicsQuery =
          await _firestore
              .collection('forum_topics')
              .where('isDeleted', isEqualTo: true)
              .get();

      final lockedTopicsQuery =
          await _firestore
              .collection('forum_topics')
              .where('isLocked', isEqualTo: true)
              .get();

      final List<Map<String, dynamic>> moderatedContent = [];

      // Add hidden topics
      for (var doc in topicsQuery.docs) {
        moderatedContent.add({
          'type': 'topic',
          'id': doc.id,
          'action': 'hidden',
          'data': doc.data(),
        });
      }

      // Add deleted topics
      for (var doc in deletedTopicsQuery.docs) {
        moderatedContent.add({
          'type': 'topic',
          'id': doc.id,
          'action': 'deleted',
          'data': doc.data(),
        });
      }

      // Add locked topics
      for (var doc in lockedTopicsQuery.docs) {
        moderatedContent.add({
          'type': 'topic',
          'id': doc.id,
          'action': 'locked',
          'data': doc.data(),
        });
      }

      return moderatedContent;
    } catch (e) {
      appLog('Error getting moderated content: $e');
      return [];
    }
  }
}
