class ReviewReply {
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  ReviewReply({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReviewReply.fromMap(Map<String, dynamic> map) => ReviewReply(
    userId: map['userId'],
    userName: map['userName'],
    comment: map['comment'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class Review {
  final String id;
  final String shopId;
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final bool isAnonymous;
  final List<ReviewReply> replies;

  Review({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.isAnonymous = false,
    this.replies = const [],
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
      'replies': replies.map((r) => r.toMap()).toList(),
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
      replies:
          (map['replies'] as List<dynamic>? ?? [])
              .map((r) => ReviewReply.fromMap(Map<String, dynamic>.from(r)))
              .toList(),
    );
  }

  String getDisplayName() {
    return isAnonymous ? 'Anonymous User' : userName;
  }
}
