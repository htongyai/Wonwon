import 'package:cloud_firestore/cloud_firestore.dart';

class ForumTopic {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String category;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int replies;
  final int views;
  final bool isPinned;
  final bool isLocked;
  final bool isHidden;
  final bool isDeleted;
  final String? moderationReason;
  final String? moderatedBy;
  final DateTime? moderatedAt;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.createdAt,
    required this.lastActivity,
    this.replies = 0,
    this.views = 0,
    this.isPinned = false,
    this.isLocked = false,
    this.isHidden = false,
    this.isDeleted = false,
    this.moderationReason,
    this.moderatedBy,
    this.moderatedAt,
    this.tags = const [],
    this.metadata = const {},
  });

  factory ForumTopic.fromMap(Map<String, dynamic> map, String id) {
    return ForumTopic(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      category: map['category'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      lastActivity: _parseDateTime(map['lastActivity']),
      replies: map['replies'] ?? 0,
      views: map['views'] ?? 0,
      isPinned: map['isPinned'] ?? false,
      isLocked: map['isLocked'] ?? false,
      isHidden: map['isHidden'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      moderationReason: map['moderationReason'],
      moderatedBy: map['moderatedBy'],
      moderatedAt: _parseDateTimeNullable(map['moderatedAt']),
      tags: _parseStringList(map['tags']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'replies': replies,
      'views': views,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'isHidden': isHidden,
      'isDeleted': isDeleted,
      'moderationReason': moderationReason,
      'moderatedBy': moderatedBy,
      'moderatedAt':
          moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      'tags': tags,
      'metadata': metadata,
    };
  }

  ForumTopic copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? category,
    DateTime? createdAt,
    DateTime? lastActivity,
    int? replies,
    int? views,
    bool? isPinned,
    bool? isLocked,
    bool? isHidden,
    bool? isDeleted,
    String? moderationReason,
    String? moderatedBy,
    DateTime? moderatedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return ForumTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      replies: replies ?? this.replies,
      views: views ?? this.views,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      isDeleted: isDeleted ?? this.isDeleted,
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}
