import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared/utils/app_logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ---------- User properties ----------

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'account_type', value: role);
  }

  // ---------- Auth events ----------

  Future<void> logLogin({String method = 'email'}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({String method = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    await setUserId(null);
  }

  Future<void> logForgotPassword() async {
    await _analytics.logEvent(name: 'forgot_password');
  }

  Future<void> logDeleteAccount() async {
    await _analytics.logEvent(name: 'delete_account');
  }

  // ---------- Screen views ----------

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ---------- Navigation ----------

  Future<void> logTabChange(String tabName) async {
    await _analytics.logEvent(
      name: 'tab_change',
      parameters: {'tab': tabName},
    );
  }

  // ---------- Shop events ----------

  Future<void> logViewShop({
    required String shopId,
    required String shopName,
    String? category,
  }) async {
    await _analytics.logEvent(
      name: 'view_shop',
      parameters: {
        'shop_id': shopId,
        'shop_name': _truncate(shopName),
        if (category != null) 'category': _truncate(category),
      },
    );
  }

  Future<void> logSaveShop(String shopId) async {
    await _analytics.logEvent(
      name: 'save_shop',
      parameters: {'shop_id': shopId},
    );
  }

  Future<void> logUnsaveShop(String shopId) async {
    await _analytics.logEvent(
      name: 'unsave_shop',
      parameters: {'shop_id': shopId},
    );
  }

  Future<void> logGetDirections(String shopId) async {
    await _analytics.logEvent(
      name: 'get_directions',
      parameters: {'shop_id': shopId},
    );
  }

  Future<void> logAddShop({
    required String shopId,
    required String shopName,
    String? category,
  }) async {
    await _analytics.logEvent(
      name: 'add_shop',
      parameters: {
        'shop_id': shopId,
        'shop_name': _truncate(shopName),
        if (category != null) 'category': _truncate(category),
      },
    );
  }

  Future<void> logEditShop(String shopId) async {
    await _analytics.logEvent(
      name: 'edit_shop',
      parameters: {'shop_id': shopId},
    );
  }

  // ---------- Search & Filter events ----------

  Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: _truncate(query));
  }

  Future<void> logFilterCategory({
    required String category,
    String? subService,
  }) async {
    await _analytics.logEvent(
      name: 'filter_category',
      parameters: {
        'category': _truncate(category),
        if (subService != null) 'sub_service': _truncate(subService),
      },
    );
  }

  // ---------- Forum events ----------

  Future<void> logCreateTopic(String topicId) async {
    await _analytics.logEvent(
      name: 'create_forum_topic',
      parameters: {'topic_id': topicId},
    );
  }

  Future<void> logReplyToTopic(String topicId) async {
    await _analytics.logEvent(
      name: 'reply_forum_topic',
      parameters: {'topic_id': topicId},
    );
  }

  Future<void> logLikeContent({
    required String contentId,
    required String contentType,
  }) async {
    await _analytics.logEvent(
      name: 'like_content',
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
      },
    );
  }

  // ---------- Review events ----------

  Future<void> logWriteReview({
    required String shopId,
    required double rating,
  }) async {
    await _analytics.logEvent(
      name: 'write_review',
      parameters: {
        'shop_id': shopId,
        'rating': rating,
      },
    );
  }

  // ---------- Repair events ----------

  Future<void> logLogRepair(String shopId) async {
    await _analytics.logEvent(
      name: 'log_repair',
      parameters: {'shop_id': shopId},
    );
  }

  // ---------- Report events ----------

  Future<void> logSubmitReport(String shopId) async {
    await _analytics.logEvent(
      name: 'submit_report',
      parameters: {'shop_id': shopId},
    );
  }

  // ---------- Notification events ----------

  Future<void> logNotificationTap({
    required String type,
    String? relatedId,
  }) async {
    await _analytics.logEvent(
      name: 'notification_tap',
      parameters: {
        'notification_type': type,
        if (relatedId != null) 'related_id': relatedId,
      },
    );
  }

  // ---------- Map events ----------

  Future<void> logMapInteraction(String action) async {
    await _analytics.logEvent(
      name: 'map_interaction',
      parameters: {'action': action},
    );
  }

  // ---------- App events ----------

  Future<void> logLanguageChange(String locale) async {
    await _analytics.logEvent(
      name: 'change_language',
      parameters: {'locale': locale},
    );
  }

  Future<void> logShareShop(String shopId) async {
    await _analytics.logShare(
      contentType: 'shop',
      itemId: shopId,
      method: 'in_app',
    );
  }

  // ---------- Admin events ----------

  Future<void> logAdminAction({
    required String action,
    String? targetId,
    Map<String, String>? extra,
  }) async {
    await _analytics.logEvent(
      name: 'admin_action',
      parameters: {
        'action': action,
        if (targetId != null) 'target_id': targetId,
        ...?extra,
      },
    );
  }

  // ---------- Helpers ----------

  /// Firebase Analytics limits parameter values to 100 chars
  String _truncate(String value, [int maxLength = 100]) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }

  /// Wrap calls in try-catch so analytics failures never crash the app
  static Future<void> safeLog(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      appLog('Analytics error: $e');
    }
  }
}
