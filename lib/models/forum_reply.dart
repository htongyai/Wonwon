import 'package:cloud_firestore/cloud_firestore.dart';

class ForumReply {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int likes;
  final List<String> likedBy;
  final bool isSolution;
  final String? parentReplyId; // For nested replies
  final bool isHidden;
  final bool isDeleted;
  final String? moderationReason;
  final String? moderatedBy;
  final DateTime? moderatedAt;
  final Map<String, dynamic> metadata;

  ForumReply({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.editedAt,
    this.likes = 0,
    this.likedBy = const [],
    this.isSolution = false,
    this.parentReplyId,
    this.isHidden = false,
    this.isDeleted = false,
    this.moderationReason,
    this.moderatedBy,
    this.moderatedAt,
    this.metadata = const {},
  });

  factory ForumReply.fromMap(Map<String, dynamic> map, String id) {
    return ForumReply(
      id: id,
      topicId: map['topicId'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      editedAt:
          map['editedAt'] != null
              ? (map['editedAt'] as Timestamp).toDate()
              : null,
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      isSolution: map['isSolution'] ?? false,
      parentReplyId: map['parentReplyId'],
      isHidden: map['isHidden'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      moderationReason: map['moderationReason'],
      moderatedBy: map['moderatedBy'],
      moderatedAt:
          map['moderatedAt'] != null
              ? (map['moderatedAt'] as Timestamp).toDate()
              : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'likes': likes,
      'likedBy': likedBy,
      'isSolution': isSolution,
      'parentReplyId': parentReplyId,
      'isHidden': isHidden,
      'isDeleted': isDeleted,
      'moderationReason': moderationReason,
      'moderatedBy': moderatedBy,
      'moderatedAt':
          moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      'metadata': metadata,
    };
  }

  ForumReply copyWith({
    String? id,
    String? topicId,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? editedAt,
    int? likes,
    List<String>? likedBy,
    bool? isSolution,
    String? parentReplyId,
    bool? isHidden,
    bool? isDeleted,
    String? moderationReason,
    String? moderatedBy,
    DateTime? moderatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ForumReply(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isSolution: isSolution ?? this.isSolution,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      isHidden: isHidden ?? this.isHidden,
      isDeleted: isDeleted ?? this.isDeleted,
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
