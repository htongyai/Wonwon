import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/shop_stats.dart';
import 'package:shared/utils/app_logger.dart';

/// Service for recording and reading per-shop analytics.
///
/// Data is stored in two places for efficient reads:
/// 1. Lifetime totals on the shop document itself (fast summary)
/// 2. Daily breakdown in `shops/{id}/analytics/{YYYY-MM-DD}` (time-series charts)
class ShopAnalyticsService {
  static final ShopAnalyticsService _instance = ShopAnalyticsService._();
  factory ShopAnalyticsService() => _instance;
  ShopAnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Today's date key, e.g. "2026-04-07"
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Reference to the daily analytics doc for a shop.
  DocumentReference _dailyDoc(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('analytics').doc(_todayKey);

  /// Reference to the shop document itself.
  DocumentReference _shopDoc(String shopId) =>
      _firestore.collection('shops').doc(shopId);

  // ── Recording methods ─────────────────────────────────────────────────

  Future<void> recordView(String shopId) =>
      _increment(shopId, 'views', 'totalViews');

  Future<void> recordSave(String shopId) =>
      _increment(shopId, 'saves', 'totalSaves');

  Future<void> recordUnsave(String shopId) =>
      _increment(shopId, 'saves', 'totalSaves', delta: -1);

  Future<void> recordDirections(String shopId) =>
      _increment(shopId, 'directions', 'totalDirections');

  Future<void> recordContact(String shopId) =>
      _increment(shopId, 'contacts', 'totalContacts');

  Future<void> recordShare(String shopId) =>
      _increment(shopId, 'shares', 'totalShares');

  Future<void> recordReview(String shopId) async {
    // Reviews only go to the daily doc (lifetime review count is already
    // maintained by ReviewService on the shop document as `reviewCount`).
    try {
      await _dailyDoc(shopId).set({
        'reviews': FieldValue.increment(1),
        'date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLog('ShopAnalytics recordReview error: $e');
    }
  }

  /// Generic increment helper — updates both the daily doc and the shop total.
  Future<void> _increment(
    String shopId,
    String dailyField,
    String totalField, {
    int delta = 1,
  }) async {
    try {
      // Run both writes in parallel for speed.
      await Future.wait([
        _dailyDoc(shopId).set({
          dailyField: FieldValue.increment(delta),
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        _shopDoc(shopId).update({
          totalField: FieldValue.increment(delta),
        }),
      ]);
    } catch (e) {
      appLog('ShopAnalytics _increment($dailyField) error: $e');
    }
  }

  // ── Reading methods ───────────────────────────────────────────────────

  /// Fetch daily stats for the last [days] days.
  /// Returns a [ShopStats] with lifetime totals + daily breakdown.
  Future<ShopStats> getStats(String shopId, {int days = 30}) async {
    try {
      // 1. Read lifetime totals from the shop document.
      final shopSnap = await _shopDoc(shopId).get();
      final shopData = shopSnap.data() as Map<String, dynamic>? ?? {};

      final totalViews = (shopData['totalViews'] as num?)?.toInt() ?? 0;
      final totalSaves = (shopData['totalSaves'] as num?)?.toInt() ?? 0;
      final totalDirections = (shopData['totalDirections'] as num?)?.toInt() ?? 0;
      final totalContacts = (shopData['totalContacts'] as num?)?.toInt() ?? 0;
      final totalShares = (shopData['totalShares'] as num?)?.toInt() ?? 0;

      // 2. Read daily docs for the period.
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final startKey = DateFormat('yyyy-MM-dd').format(startDate);

      final analyticsSnap = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('analytics')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .orderBy(FieldPath.documentId)
          .get();

      // Build a map of existing daily data keyed by date string.
      final dailyMap = <String, Map<String, dynamic>>{};
      for (final doc in analyticsSnap.docs) {
        dailyMap[doc.id] = doc.data();
      }

      // 3. Build the daily stats list — fill in zeros for missing days.
      final dailyStats = <DailyStat>[];
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i + 1));
        final key = DateFormat('yyyy-MM-dd').format(date);
        final data = dailyMap[key];
        if (data != null) {
          dailyStats.add(DailyStat.fromMap(data, date));
        } else {
          dailyStats.add(DailyStat(date: date));
        }
      }

      return ShopStats(
        totalViews: totalViews,
        totalSaves: totalSaves,
        totalDirections: totalDirections,
        totalContacts: totalContacts,
        totalShares: totalShares,
        dailyStats: dailyStats,
      );
    } catch (e) {
      appLog('ShopAnalytics getStats error: $e');
      return ShopStats();
    }
  }
}
