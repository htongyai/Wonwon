import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewReply {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  ReviewReply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReviewReply.fromMap(Map<String, dynamic> map) => ReviewReply(
    id: map['id']?.toString() ?? '',
    userId: map['userId']?.toString() ?? '',
    userName: map['userName']?.toString() ?? '',
    comment: map['comment']?.toString() ?? '',
    createdAt: _parseDateTime(map['createdAt']),
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
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
      id: map['id']?.toString() ?? '',
      shopId: map['shopId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      comment: map['comment']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDateTime(map['createdAt']),
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      replies:
          (map['replies'] as List<dynamic>? ?? [])
              .map((r) => ReviewReply.fromMap(Map<String, dynamic>.from(r)))
              .toList(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String getDisplayName() {
    return isAnonymous ? 'Anonymous User' : userName;
  }
}
