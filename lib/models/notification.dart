import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  forumReply,
  forumLike,
  reviewReply,
  shopApproved,
  shopRejected,
  announcement,
  systemMessage,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String userId;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // ID of related content (forum topic, shop, etc.)

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userId,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.systemMessage,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      relatedId: map['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'userId': userId,
      'type': type.toString().split('.').last,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? userId,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.forumReply:
        return Icons.reply;
      case NotificationType.forumLike:
        return Icons.favorite;
      case NotificationType.reviewReply:
        return Icons.rate_review;
      case NotificationType.shopApproved:
        return Icons.check_circle;
      case NotificationType.shopRejected:
        return Icons.cancel;
      case NotificationType.announcement:
        return Icons.announcement;
      case NotificationType.systemMessage:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.forumReply:
        return Colors.blue;
      case NotificationType.forumLike:
        return Colors.red;
      case NotificationType.reviewReply:
        return Colors.orange;
      case NotificationType.shopApproved:
        return Colors.green;
      case NotificationType.shopRejected:
        return Colors.red;
      case NotificationType.announcement:
        return Colors.purple;
      case NotificationType.systemMessage:
        return Colors.grey;
    }
  }
}
