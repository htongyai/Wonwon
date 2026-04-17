/// Per-shop analytics data model.
/// Stores both lifetime totals and daily time-series data
/// for rendering charts and summary cards.
class ShopStats {
  final int totalViews;
  final int totalSaves;
  final int totalDirections;
  final int totalContacts;
  final int totalShares;
  final List<DailyStat> dailyStats;

  ShopStats({
    this.totalViews = 0,
    this.totalSaves = 0,
    this.totalDirections = 0,
    this.totalContacts = 0,
    this.totalShares = 0,
    this.dailyStats = const [],
  });

  /// Totals for the selected period (sum of daily stats).
  Map<String, int> get periodTotals {
    int views = 0, saves = 0, directions = 0, contacts = 0, shares = 0, reviews = 0;
    for (final d in dailyStats) {
      views += d.views;
      saves += d.saves;
      directions += d.directions;
      contacts += d.contacts;
      shares += d.shares;
      reviews += d.reviews;
    }
    return {
      'views': views,
      'saves': saves,
      'directions': directions,
      'contacts': contacts,
      'shares': shares,
      'reviews': reviews,
    };
  }

  /// Total engagement for the period.
  int get periodEngagement {
    final t = periodTotals;
    return t.values.fold(0, (sum, v) => sum + v);
  }
}

/// A single day's analytics data for one shop.
class DailyStat {
  final DateTime date;
  final int views;
  final int saves;
  final int directions;
  final int contacts;
  final int shares;
  final int reviews;

  DailyStat({
    required this.date,
    this.views = 0,
    this.saves = 0,
    this.directions = 0,
    this.contacts = 0,
    this.shares = 0,
    this.reviews = 0,
  });

  factory DailyStat.fromMap(Map<String, dynamic> map, DateTime date) {
    return DailyStat(
      date: date,
      views: (map['views'] as num?)?.toInt() ?? 0,
      saves: (map['saves'] as num?)?.toInt() ?? 0,
      directions: (map['directions'] as num?)?.toInt() ?? 0,
      contacts: (map['contacts'] as num?)?.toInt() ?? 0,
      shares: (map['shares'] as num?)?.toInt() ?? 0,
      reviews: (map['reviews'] as num?)?.toInt() ?? 0,
    );
  }

  /// Total interactions for this day.
  int get total => views + saves + directions + contacts + shares + reviews;
}
