import 'package:wonwonw2/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Get reviews for a specific shop
  Future<List<Review>> getReviewsForShop(String shopId) async {
    try {
      final snapshot =
          await _firestore
              .collection('shops')
              .doc(shopId)
              .collection('review')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review(
          id: doc.id,
          shopId: data['shopId'] as String,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          comment: data['comment'] as String,
          rating: (data['rating'] as num).toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isAnonymous: data['isAnonymous'] as bool? ?? false,
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
      final reviewRef = shopRef.collection('review').doc(review.id);
      await reviewRef.set({
        'shopId': review.shopId,
        'userId': review.userId,
        'userName': review.isAnonymous ? 'Anonymous User' : review.userName,
        'comment': review.comment,
        'rating': review.rating,
        'createdAt': Timestamp.fromDate(review.createdAt),
        'isAnonymous': review.isAnonymous,
      });

      // Update average rating and review count
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
        await shopRef.update({'rating': avg, 'reviewCount': reviews.length});
      }
    } catch (e) {
      appLog('Error adding review: $e');
      rethrow;
    }
  }
}
