import 'package:shared/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/services/content_management_service.dart';
import 'package:shared/services/activity_service.dart';
import 'package:shared/services/shop_analytics_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // Verify authenticated user matches review author
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to submit a review');
      }
      if (currentUser.uid != review.userId) {
        throw Exception('Unauthorized: cannot submit review for another user');
      }

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

      // Update average rating incrementally (no need to fetch all reviews)
      await _firestore.runTransaction((transaction) async {
        // Read current shop data
        final shopDoc = await transaction.get(shopRef);
        final shopData = shopDoc.data() as Map<String, dynamic>? ?? {};
        final currentRating = (shopData['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (shopData['reviewCount'] as num?)?.toInt() ?? 0;

        // Calculate new average incrementally
        final newCount = currentCount + 1;
        final newAverage = ((currentRating * currentCount) + review.rating) / newCount;

        transaction.update(shopRef, {'rating': newAverage, 'reviewCount': newCount});
      });

      // Increment a denormalized reviewCount on the user document so the
      // profile screen can reflect the change in realtime via its
      // existing user-doc stream listener — no collectionGroup query or
      // composite index required. Failures here must not block the
      // review from being written.
      try {
        await _firestore
            .collection('users')
            .doc(review.userId)
            .set({'reviewCount': FieldValue.increment(1)},
                SetOptions(merge: true));
      } catch (e) {
        appLog('Error incrementing user reviewCount: $e');
      }

      // Record review analytics
      try {
        await ShopAnalyticsService().recordReview(review.shopId);
      } catch (e) {
        appLog('Error recording review analytics: $e');
      }

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
      // Verify user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to reply to a review');
      }

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

      // Read the review's rating before deleting it
      final reviewDoc = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('review')
          .doc(reviewId)
          .get();
      final deletedRating = reviewDoc.exists
          ? (reviewDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      // Capture the author uid before deletion so we can decrement their
      // user-level reviewCount without a second read.
      final reviewAuthorUid = reviewDoc.exists
          ? (reviewDoc.data()?['userId'] as String? ?? reviewAuthorId)
          : reviewAuthorId;

      // Delete the review
      await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('review')
          .doc(reviewId)
          .delete();

      // Decrement the author's denormalized reviewCount so the profile
      // screen updates in realtime. Clamp to zero via a transaction to
      // avoid negative values if the counter was out of sync.
      try {
        final userRef = _firestore.collection('users').doc(reviewAuthorUid);
        await _firestore.runTransaction((transaction) async {
          final userDoc = await transaction.get(userRef);
          final current =
              (userDoc.data()?['reviewCount'] as num?)?.toInt() ?? 0;
          final next = current > 0 ? current - 1 : 0;
          transaction.set(userRef, {'reviewCount': next}, SetOptions(merge: true));
        });
      } catch (e) {
        appLog('Error decrementing user reviewCount: $e');
      }

      // Update average rating decrementally (no need to fetch all reviews)
      final shopRef = _firestore.collection('shops').doc(shopId);
      await _firestore.runTransaction((transaction) async {
        // Read current shop data
        final shopDoc = await transaction.get(shopRef);
        final shopData = shopDoc.data() as Map<String, dynamic>? ?? {};
        final currentRating = (shopData['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (shopData['reviewCount'] as num?)?.toInt() ?? 0;

        if (currentCount <= 1) {
          // Last review being deleted
          transaction.update(shopRef, {'rating': 0.0, 'reviewCount': 0});
        } else {
          final newCount = currentCount - 1;
          final newAverage = ((currentRating * currentCount) - deletedRating) / newCount;
          transaction.update(shopRef, {'rating': newAverage, 'reviewCount': newCount});
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
