class Review {
  final String id;
  final String shopId;
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final bool isAnonymous;

  Review({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      shopId: map['shopId'],
      userId: map['userId'],
      userName: map['userName'],
      comment: map['comment'],
      rating: map['rating'],
      createdAt: DateTime.parse(map['createdAt']),
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }

  String getDisplayName() {
    return isAnonymous ? 'Anonymous User' : userName;
  }
}
