import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get notifications subcollection for a user
  static CollectionReference _getNotificationsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  // Create a new notification
  static Future<void> createNotification({
    required String title,
    required String message,
    required String userId,
    required NotificationType type,
    Map<String, dynamic> data = const {},
    String? relatedId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        userId: userId,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        relatedId: relatedId,
      );

      await _getNotificationsCollection(userId).add(notification.toMap());
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get notifications for current user
  static Stream<List<NotificationModel>> getUserNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _getNotificationsCollection(currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => NotificationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        })
        .handleError((error) {
          print('Error getting user notifications: $error');
          return <NotificationModel>[];
        });
  }

  // Get unread notifications count
  static Stream<int> getUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _getNotificationsCollection(currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          print('Error getting unread count: $error');
          return 0;
        });
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _getNotificationsCollection(
        currentUser.uid,
      ).doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications =
          await _getNotificationsCollection(
            currentUser.uid,
          ).where('isRead', isEqualTo: false).get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _getNotificationsCollection(
        currentUser.uid,
      ).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Create forum reply notification
  static Future<void> createForumReplyNotification({
    required String topicId,
    required String topicTitle,
    required String authorId,
    required String authorName,
    required String replyContent,
  }) async {
    try {
      // Get topic author
      final topicDoc =
          await _firestore.collection('forum_topics').doc(topicId).get();

      if (topicDoc.exists) {
        final topicData = topicDoc.data()!;
        final topicAuthorId = topicData['authorId'] as String;

        // Don't notify the author of their own reply
        if (topicAuthorId != authorId) {
          await createNotification(
            title: 'New Reply to Your Topic',
            message: '$authorName replied to your topic "$topicTitle"',
            userId: topicAuthorId,
            type: NotificationType.forumReply,
            data: {
              'topicId': topicId,
              'topicTitle': topicTitle,
              'authorId': authorId,
              'authorName': authorName,
              'replyContent': replyContent,
            },
            relatedId: topicId,
          );
        }
      }
    } catch (e) {
      print('Error creating forum reply notification: $e');
    }
  }

  // Create forum like notification
  static Future<void> createForumLikeNotification({
    required String topicId,
    required String topicTitle,
    required String likerId,
    required String likerName,
  }) async {
    try {
      // Get topic author
      final topicDoc =
          await _firestore.collection('forum_topics').doc(topicId).get();

      if (topicDoc.exists) {
        final topicData = topicDoc.data()!;
        final topicAuthorId = topicData['authorId'] as String;

        // Don't notify the author of their own like
        if (topicAuthorId != likerId) {
          await createNotification(
            title: 'New Like on Your Topic',
            message: '$likerName liked your topic "$topicTitle"',
            userId: topicAuthorId,
            type: NotificationType.forumLike,
            data: {
              'topicId': topicId,
              'topicTitle': topicTitle,
              'likerId': likerId,
              'likerName': likerName,
            },
            relatedId: topicId,
          );
        }
      }
    } catch (e) {
      print('Error creating forum like notification: $e');
    }
  }

  // Create review reply notification
  static Future<void> createReviewReplyNotification({
    required String shopId,
    required String shopName,
    required String reviewId,
    required String authorId,
    required String authorName,
    required String replyContent,
  }) async {
    try {
      // Get review author
      final reviewDoc =
          await _firestore
              .collection('shops')
              .doc(shopId)
              .collection('reviews')
              .doc(reviewId)
              .get();

      if (reviewDoc.exists) {
        final reviewData = reviewDoc.data()!;
        final reviewAuthorId = reviewData['userId'] as String;

        // Don't notify the author of their own reply
        if (reviewAuthorId != authorId) {
          await createNotification(
            title: 'New Reply to Your Review',
            message: '$authorName replied to your review for $shopName',
            userId: reviewAuthorId,
            type: NotificationType.reviewReply,
            data: {
              'shopId': shopId,
              'shopName': shopName,
              'reviewId': reviewId,
              'authorId': authorId,
              'authorName': authorName,
              'replyContent': replyContent,
            },
            relatedId: reviewId,
          );
        }
      }
    } catch (e) {
      print('Error creating review reply notification: $e');
    }
  }

  // Create shop approval notification
  static Future<void> createShopApprovalNotification({
    required String shopId,
    required String shopName,
    required String ownerId,
    required bool isApproved,
  }) async {
    try {
      final title = isApproved ? 'Shop Approved' : 'Shop Rejected';
      final message =
          isApproved
              ? 'Your shop "$shopName" has been approved!'
              : 'Your shop "$shopName" has been rejected. Please check the requirements.';

      await createNotification(
        title: title,
        message: message,
        userId: ownerId,
        type:
            isApproved
                ? NotificationType.shopApproved
                : NotificationType.shopRejected,
        data: {
          'shopId': shopId,
          'shopName': shopName,
          'isApproved': isApproved,
        },
        relatedId: shopId,
      );
    } catch (e) {
      print('Error creating shop approval notification: $e');
    }
  }

  // Create announcement notification for all users
  static Future<void> createAnnouncementNotification({
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        await createNotification(
          title: title,
          message: message,
          userId: userId,
          type: NotificationType.announcement,
          data: data,
        );
      }
    } catch (e) {
      print('Error creating announcement notification: $e');
    }
  }

  // Create system message notification
  static Future<void> createSystemMessageNotification({
    required String title,
    required String message,
    required String userId,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await createNotification(
        title: title,
        message: message,
        userId: userId,
        type: NotificationType.systemMessage,
        data: data,
      );
    } catch (e) {
      print('Error creating system message notification: $e');
    }
  }
}
