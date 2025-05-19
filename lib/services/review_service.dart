import 'package:wonwonw2/models/review.dart';

class ReviewService {
  // Mock data for reviews
  List<Review> _mockReviews = [
    Review(
      id: '1',
      shopId: 'shop1',
      userId: 'user1',
      userName: 'John Smith',
      comment: 'Great service! They fixed my phone in just 30 minutes.',
      rating: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isAnonymous: false,
    ),
    Review(
      id: '2',
      shopId: 'shop1',
      userId: 'user2',
      userName: 'Mary Johnson',
      comment: 'Reasonable prices and good quality repair.',
      rating: 4.5,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isAnonymous: true,
    ),
    Review(
      id: '3',
      shopId: 'shop1',
      userId: 'user3',
      userName: 'Robert Wilson',
      comment: 'They did a decent job, but took longer than expected.',
      rating: 3.5,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      isAnonymous: false,
    ),
    Review(
      id: '4',
      shopId: 'shop2',
      userId: 'user4',
      userName: 'Sarah Lee',
      comment: 'Excellent work on my laptop screen replacement!',
      rating: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isAnonymous: false,
    ),
  ];

  // Get reviews for a specific shop
  Future<List<Review>> getReviewsForShop(String shopId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return filtered reviews
    return _mockReviews.where((review) => review.shopId == shopId).toList();
  }

  // Add a new review
  Future<void> addReview(Review review) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Add to mock list
    _mockReviews.add(review);
  }
}
