import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

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

  // ---------- Screen views ----------

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
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

  // ---------- Search events ----------

  Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: _truncate(query));
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
      debugPrint('Analytics error: $e');
    }
  }
}
