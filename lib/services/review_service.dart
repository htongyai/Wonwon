import 'package:wonwonw2/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/services/content_management_service.dart';
import 'package:wonwonw2/services/activity_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reviews for a specific shop
  Future<List<Review>> getReviewsForShop(String shopId) async {
    try {
      final snapshot =
          await _firestore
              .collection('shops')
              .doc(shopId)
              .collection('review')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Parse replies if present
        final repliesData = data['replies'] as List<dynamic>? ?? [];
        final replies =
            repliesData
                .map((r) => ReviewReply.fromMap(Map<String, dynamic>.from(r)))
                .toList();
        return Review(
          id: doc.id,
          shopId: data['shopId'] as String,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          comment: data['comment'] as String,
          rating: (data['rating'] as num).toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isAnonymous: data['isAnonymous'] as bool? ?? false,
          replies: replies,
        );
      }).toList();
    } catch (e) {
      appLog('Error getting reviews: $e');
      return [];
    }
  }

  // Add a new review
  Future<void> addReview(Review review) async {
    try {
      final shopRef = _firestore.collection('shops').doc(review.shopId);
      // Validate review data
      if (review.rating < 0 || review.rating > 5) {
        throw ArgumentError('Rating must be between 0 and 5');
      }
      if (review.comment.trim().isEmpty) {
        throw ArgumentError('Review comment cannot be empty');
      }
      final reviewRef = review.id.isNotEmpty
          ? shopRef.collection('review').doc(review.id)
          : shopRef.collection('review').doc();
      await reviewRef.set({
        'shopId': review.shopId,
        'userId': review.userId,
        'userName': review.isAnonymous ? 'Anonymous User' : review.userName,
        'comment': review.comment,
        'rating': review.rating,
        'createdAt': Timestamp.fromDate(review.createdAt),
        'isAnonymous': review.isAnonymous,
      });

      // Update average rating atomically
      await _firestore.runTransaction((transaction) async {
        final reviewsSnapshot = await shopRef.collection('review').get();
        final reviews = reviewsSnapshot.docs;
        if (reviews.isNotEmpty) {
          double total = 0;
          for (var doc in reviews) {
            final data = doc.data();
            if (data['rating'] != null) {
              total += (data['rating'] as num).toDouble();
            }
          }
          final avg = total / reviews.length;
          transaction.update(shopRef, {'rating': avg, 'reviewCount': reviews.length});
        }
      });

      // Log review activity
      try {
        await ActivityService().logReviewPosted(
          review.id,
          review.shopId,
          review.rating,
          review.userName,
        );
      } catch (e) {
        appLog('Error logging review activity: $e');
      }
    } catch (e) {
      appLog('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> addReplyToReview({
    required String shopId,
    required String reviewId,
    required ReviewReply reply,
  }) async {
    try {
      final reviewRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('review')
          .doc(reviewId);
      await reviewRef.update({
        'replies': FieldValue.arrayUnion([reply.toMap()]),
      });
    } catch (e) {
      appLog('Error adding reply to review: $e');
      rethrow;
    }
  }

  // Delete a review with permission check
  Future<bool> deleteReview(
    String shopId,
    String reviewId,
    String reviewAuthorId,
  ) async {
    try {
      final contentService = ContentManagementService();
      final canDelete = await contentService.canDeleteContent(reviewAuthorId);

      if (!canDelete) {
        appLog('User does not have permission to delete this review');
        return false;
      }

      // Delete the review
      await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('review')
          .doc(reviewId)
          .delete();

      // Update average rating atomically
      await _firestore.runTransaction((transaction) async {
        final reviewsSnapshot =
            await _firestore
                .collection('shops')
                .doc(shopId)
                .collection('review')
                .get();

        final shopRef = _firestore.collection('shops').doc(shopId);
        final reviews = reviewsSnapshot.docs;
        if (reviews.isNotEmpty) {
          double total = 0;
          for (var doc in reviews) {
            final data = doc.data();
            if (data['rating'] != null) {
              total += (data['rating'] as num).toDouble();
            }
          }
          final avg = total / reviews.length;
          transaction.update(shopRef, {'rating': avg, 'reviewCount': reviews.length});
        } else {
          transaction.update(shopRef, {'rating': 0.0, 'reviewCount': 0});
        }
      });

      appLog('Review deleted successfully: $reviewId');
      return true;
    } catch (e) {
      appLog('Error deleting review: $e');
      return false;
    }
  }

  // Delete a review reply with permission check
  Future<bool> deleteReviewReply(
    String shopId,
    String reviewId,
    String replyId,
    String replyAuthorId,
  ) async {
    try {
      final contentService = ContentManagementService();
      final canDelete = await contentService.canDeleteContent(replyAuthorId);

      if (!canDelete) {
        appLog('User does not have permission to delete this reply');
        return false;
      }

      // Get the current review to find and remove the specific reply
      final reviewRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('review')
          .doc(reviewId);

      final reviewDoc = await reviewRef.get();
      if (!reviewDoc.exists) {
        appLog('Review not found: $reviewId');
        return false;
      }

      final data = reviewDoc.data()!;
      final replies = List<Map<String, dynamic>>.from(data['replies'] ?? []);

      // Remove the specific reply
      replies.removeWhere((reply) => reply['id'] == replyId);

      // Update the review with the new replies list
      await reviewRef.update({'replies': replies});

      appLog('Review reply deleted successfully: $replyId');
      return true;
    } catch (e) {
      appLog('Error deleting review reply: $e');
      return false;
    }
  }
}
