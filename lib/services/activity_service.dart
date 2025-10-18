import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Activity types
  static const String USER_ACTIVITY = 'user';
  static const String SHOP_ACTIVITY = 'shop';
  static const String REVIEW_ACTIVITY = 'review';
  static const String ADMIN_ACTIVITY = 'admin';
  static const String SYSTEM_ACTIVITY = 'system';

  // User actions
  static const String USER_REGISTERED = 'user_registered';
  static const String USER_LOGIN = 'user_login';
  static const String USER_LOGOUT = 'user_logout';
  static const String USER_PROFILE_UPDATED = 'user_profile_updated';
  static const String USER_PASSWORD_CHANGED = 'user_password_changed';

  // Shop actions
  static const String SHOP_CREATED = 'shop_created';
  static const String SHOP_UPDATED = 'shop_updated';
  static const String SHOP_APPROVED = 'shop_approved';
  static const String SHOP_REJECTED = 'shop_rejected';
  static const String SHOP_DELETED = 'shop_deleted';

  // Review actions
  static const String REVIEW_POSTED = 'review_posted';
  static const String REVIEW_UPDATED = 'review_updated';
  static const String REVIEW_DELETED = 'review_deleted';
  static const String REVIEW_REPLY_POSTED = 'review_reply_posted';

  // Admin actions
  static const String ADMIN_USER_BANNED = 'admin_user_banned';
  static const String ADMIN_USER_UNBANNED = 'admin_user_unbanned';
  static const String ADMIN_SHOP_APPROVED = 'admin_shop_approved';
  static const String ADMIN_SHOP_REJECTED = 'admin_shop_rejected';
  static const String ADMIN_REPORT_RESOLVED = 'admin_report_resolved';

  // System actions
  static const String SYSTEM_BACKUP = 'system_backup';
  static const String SYSTEM_MAINTENANCE = 'system_maintenance';
  static const String SYSTEM_ERROR = 'system_error';

  /// Log a user activity
  Future<void> logUserActivity({
    required String action,
    required String title,
    required String description,
    String? targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await _logActivity(
      type: USER_ACTIVITY,
      action: action,
      title: title,
      description: description,
      targetUserId: targetUserId,
      metadata: metadata,
    );
  }

  /// Log a shop activity
  Future<void> logShopActivity({
    required String action,
    required String title,
    required String description,
    String? shopId,
    String? shopName,
    Map<String, dynamic>? metadata,
  }) async {
    await _logActivity(
      type: SHOP_ACTIVITY,
      action: action,
      title: title,
      description: description,
      shopId: shopId,
      shopName: shopName,
      metadata: metadata,
    );
  }

  /// Log a review activity
  Future<void> logReviewActivity({
    required String action,
    required String title,
    required String description,
    String? reviewId,
    String? shopId,
    double? rating,
    Map<String, dynamic>? metadata,
  }) async {
    await _logActivity(
      type: REVIEW_ACTIVITY,
      action: action,
      title: title,
      description: description,
      reviewId: reviewId,
      shopId: shopId,
      metadata: {...?metadata, if (rating != null) 'rating': rating},
    );
  }

  /// Log an admin activity
  Future<void> logAdminActivity({
    required String action,
    required String title,
    required String description,
    String? targetUserId,
    String? targetShopId,
    Map<String, dynamic>? metadata,
  }) async {
    await _logActivity(
      type: ADMIN_ACTIVITY,
      action: action,
      title: title,
      description: description,
      targetUserId: targetUserId,
      shopId: targetShopId,
      metadata: {...?metadata, 'adminAction': true},
    );
  }

  /// Log a system activity
  Future<void> logSystemActivity({
    required String action,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await _logActivity(
      type: SYSTEM_ACTIVITY,
      action: action,
      title: title,
      description: description,
      metadata: {...?metadata, 'automated': true},
    );
  }

  /// Internal method to log activity
  Future<void> _logActivity({
    required String type,
    required String action,
    required String title,
    required String description,
    String? targetUserId,
    String? shopId,
    String? shopName,
    String? reviewId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final timestamp = Timestamp.now();

      final activityData = {
        'type': type,
        'action': action,
        'title': title,
        'description': description,
        'timestamp': timestamp,
        'metadata': metadata ?? {},
      };

      // Add user information if available
      if (currentUser != null) {
        activityData['userId'] = currentUser.uid;
        if (currentUser.email != null) {
          activityData['userEmail'] = currentUser.email!;
        }

        // Get user name from Firestore
        try {
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            activityData['userName'] =
                userDoc.data()?['name'] ?? 'Unknown User';
          }
        } catch (e) {
          // Continue without user name if fetch fails
        }
      }

      // Add target user information
      if (targetUserId != null) {
        activityData['targetUserId'] = targetUserId;
        try {
          final targetUserDoc =
              await _firestore.collection('users').doc(targetUserId).get();
          if (targetUserDoc.exists) {
            activityData['targetUserName'] =
                targetUserDoc.data()?['name'] ?? 'Unknown User';
          }
        } catch (e) {
          // Continue without target user name if fetch fails
        }
      }

      // Add shop information
      if (shopId != null) {
        activityData['shopId'] = shopId;
        if (shopName != null) {
          activityData['shopName'] = shopName;
        } else {
          // Try to get shop name from Firestore
          try {
            final shopDoc =
                await _firestore.collection('shops').doc(shopId).get();
            if (shopDoc.exists) {
              activityData['shopName'] =
                  shopDoc.data()?['name'] ?? 'Unknown Shop';
            }
          } catch (e) {
            // Continue without shop name if fetch fails
          }
        }
      }

      // Add review information
      if (reviewId != null) {
        activityData['reviewId'] = reviewId;
      }

      // Store the activity log
      await _firestore.collection('activity_logs').add(activityData);

      // Also update user's last active time if it's a user activity
      if (currentUser != null && type == USER_ACTIVITY) {
        await _updateUserLastActive(currentUser.uid);
      }
    } catch (e) {
      // Log error but don't throw to avoid disrupting main functionality
      print('Error logging activity: $e');
    }
  }

  /// Update user's last active timestamp
  Future<void> _updateUserLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActiveAt': Timestamp.now(),
      });
    } catch (e) {
      // Ignore errors in updating last active time
    }
  }

  /// Get activity logs with filtering
  Future<List<Map<String, dynamic>>> getActivityLogs({
    String? type,
    String? userId,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('activity_logs');

      // Apply filters
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (shopId != null) {
        query = query.where('shopId', isEqualTo: shopId);
      }
      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Order by timestamp (newest first) and limit
      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting activity logs: $e');
      return [];
    }
  }

  /// Get activity statistics
  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('activity_logs');

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();
      final activities =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      // Count by type
      final typeCount = <String, int>{};
      final actionCount = <String, int>{};
      final dailyCount = <String, int>{};

      for (final activity in activities) {
        final type = activity['type'] as String;
        final action = activity['action'] as String;
        final timestamp = activity['timestamp'] as Timestamp;
        final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());

        typeCount[type] = (typeCount[type] ?? 0) + 1;
        actionCount[action] = (actionCount[action] ?? 0) + 1;
        dailyCount[date] = (dailyCount[date] ?? 0) + 1;
      }

      return {
        'totalActivities': activities.length,
        'typeCount': typeCount,
        'actionCount': actionCount,
        'dailyCount': dailyCount,
      };
    } catch (e) {
      print('Error getting activity stats: $e');
      return {
        'totalActivities': 0,
        'typeCount': <String, int>{},
        'actionCount': <String, int>{},
        'dailyCount': <String, int>{},
      };
    }
  }

  /// Clean up old activity logs (keep only last 90 days)
  Future<void> cleanupOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final query = _firestore
          .collection('activity_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate));

      final snapshot = await query.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up ${snapshot.docs.length} old activity logs');
    } catch (e) {
      print('Error cleaning up old logs: $e');
    }
  }
}

// Extension methods for easier logging
extension ActivityLogging on ActivityService {
  // User activity helpers
  Future<void> logUserRegistration(String userName, String userEmail) async {
    await logUserActivity(
      action: ActivityService.USER_REGISTERED,
      title: 'New User Registration',
      description: '$userName ($userEmail) joined the platform',
      metadata: {'email': userEmail},
    );
  }

  Future<void> logUserLogin(String userName) async {
    await logUserActivity(
      action: ActivityService.USER_LOGIN,
      title: 'User Login',
      description: '$userName logged in',
    );
  }

  Future<void> logUserLogout(String userName) async {
    await logUserActivity(
      action: ActivityService.USER_LOGOUT,
      title: 'User Logout',
      description: '$userName logged out',
    );
  }

  // Shop activity helpers
  Future<void> logShopRegistration(
    String shopId,
    String shopName,
    String category,
  ) async {
    await logShopActivity(
      action: ActivityService.SHOP_CREATED,
      title: 'New Shop Registration',
      description: 'Shop "$shopName" was registered',
      shopId: shopId,
      shopName: shopName,
      metadata: {'category': category},
    );
  }

  Future<void> logShopApproval(
    String shopId,
    String shopName,
    String adminName,
  ) async {
    await logAdminActivity(
      action: ActivityService.ADMIN_SHOP_APPROVED,
      title: 'Shop Approved',
      description: 'Shop "$shopName" was approved by $adminName',
      targetShopId: shopId,
      metadata: {'shopName': shopName, 'adminName': adminName},
    );
  }

  // Review activity helpers
  Future<void> logReviewPosted(
    String reviewId,
    String shopId,
    double rating,
    String userName,
  ) async {
    await logReviewActivity(
      action: ActivityService.REVIEW_POSTED,
      title: 'New Review Posted',
      description: '$userName posted a $rating-star review',
      reviewId: reviewId,
      shopId: shopId,
      rating: rating,
      metadata: {'userName': userName},
    );
  }
}
