import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class ContentManagementService {
  static final ContentManagementService _instance =
      ContentManagementService._internal();
  factory ContentManagementService() => _instance;
  ContentManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Delete a review
  Future<bool> deleteReview(String reviewId, String reviewAuthorId) async {
    try {
      // Check if user has permission to delete this review
      final canDelete = await _authService.canDeleteContent(reviewAuthorId);
      if (!canDelete) {
        appLog('User does not have permission to delete this review');
        return false;
      }

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();
      appLog('Review deleted successfully: $reviewId');
      return true;
    } catch (e) {
      appLog('Error deleting review: $e');
      return false;
    }
  }

  // Delete a forum topic
  Future<bool> deleteForumTopic(String topicId, String topicAuthorId) async {
    try {
      // Check if user has permission to delete this topic
      final canDelete = await _authService.canDeleteContent(topicAuthorId);
      if (!canDelete) {
        appLog('User does not have permission to delete this topic');
        return false;
      }

      // Delete all replies first
      final repliesSnapshot =
          await _firestore
              .collection('forum_replies')
              .where('topicId', isEqualTo: topicId)
              .get();

      final batch = _firestore.batch();
      for (final doc in repliesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the topic
      batch.delete(_firestore.collection('forum_topics').doc(topicId));

      // Commit the batch
      await batch.commit();
      appLog('Forum topic and all replies deleted successfully: $topicId');
      return true;
    } catch (e) {
      appLog('Error deleting forum topic: $e');
      return false;
    }
  }

  // Delete a forum reply
  Future<bool> deleteForumReply(String replyId, String replyAuthorId) async {
    try {
      // Check if user has permission to delete this reply
      final canDelete = await _authService.canDeleteContent(replyAuthorId);
      if (!canDelete) {
        appLog('User does not have permission to delete this reply');
        return false;
      }

      // Delete the reply
      await _firestore.collection('forum_replies').doc(replyId).delete();
      appLog('Forum reply deleted successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error deleting forum reply: $e');
      return false;
    }
  }

  // Delete a shop comment (if you have a comments collection)
  Future<bool> deleteShopComment(
    String commentId,
    String commentAuthorId,
  ) async {
    try {
      // Check if user has permission to delete this comment
      final canDelete = await _authService.canDeleteContent(commentAuthorId);
      if (!canDelete) {
        appLog('User does not have permission to delete this comment');
        return false;
      }

      // Delete the comment
      await _firestore.collection('shop_comments').doc(commentId).delete();
      appLog('Shop comment deleted successfully: $commentId');
      return true;
    } catch (e) {
      appLog('Error deleting shop comment: $e');
      return false;
    }
  }

  // Check if current user can delete specific content
  Future<bool> canDeleteContent(String contentAuthorId) async {
    return await _authService.canDeleteContent(contentAuthorId);
  }

  // Get current user's role for UI display
  Future<String> getCurrentUserRole() async {
    final accountType = await _authService.getCurrentUserAccountType();
    switch (accountType) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'shop_owner':
        return 'Shop Owner';
      case 'user':
      default:
        return 'User';
    }
  }
}
