import 'package:shared/models/repair_shop.dart';

/// Sort options for the shop list.
enum ShopSortMode {
  distance, // Default: closest first
  rating, // Highest rated first
  newest, // Most recently added
  nameAsc, // A → Z
}

extension ShopSortModeExt on ShopSortMode {
  String get key {
    switch (this) {
      case ShopSortMode.distance:
        return 'sort_distance';
      case ShopSortMode.rating:
        return 'sort_rating';
      case ShopSortMode.newest:
        return 'sort_newest';
      case ShopSortMode.nameAsc:
        return 'sort_name_asc';
    }
  }
}

/// Immutable filter state for the home screen shop list.
/// Wraps all user-selectable filter/sort options in one value.
class ShopFilter {
  /// When true, only shops currently open (based on local time + shop hours).
  final bool openNow;

  /// Minimum rating (inclusive). 0 means no filter.
  final double minRating;

  /// Price range symbols to include. Empty = all.
  /// Values: '฿', '฿฿', '฿฿฿', '฿฿฿฿'
  final Set<String> priceRanges;

  /// Max distance in kilometers from user. null = no filter.
  final double? maxDistanceKm;

  /// Active sort mode.
  final ShopSortMode sortMode;

  const ShopFilter({
    this.openNow = false,
    this.minRating = 0,
    this.priceRanges = const {},
    this.maxDistanceKm,
    this.sortMode = ShopSortMode.distance,
  });

  /// True when any optional filter is active (excluding sort).
  bool get hasActiveFilters =>
      openNow ||
      minRating > 0 ||
      priceRanges.isNotEmpty ||
      maxDistanceKm != null;

  /// Count of active filter dimensions (for the badge).
  int get activeCount {
    int n = 0;
    if (openNow) n++;
    if (minRating > 0) n++;
    if (priceRanges.isNotEmpty) n++;
    if (maxDistanceKm != null) n++;
    return n;
  }

  ShopFilter copyWith({
    bool? openNow,
    double? minRating,
    Set<String>? priceRanges,
    Object? maxDistanceKm = _unset, // sentinel to allow clearing to null
    ShopSortMode? sortMode,
  }) {
    return ShopFilter(
      openNow: openNow ?? this.openNow,
      minRating: minRating ?? this.minRating,
      priceRanges: priceRanges ?? this.priceRanges,
      maxDistanceKm: maxDistanceKm == _unset
          ? this.maxDistanceKm
          : maxDistanceKm as double?,
      sortMode: sortMode ?? this.sortMode,
    );
  }

  static const _unset = Object();
}

/// Utility class that applies a [ShopFilter] to a shop list.
/// Pure functions — no side effects.
class ShopFilterEngine {
  ShopFilterEngine._();

  /// Apply a filter + sort to a list of shops.
  /// [distanceKm] is a lookup callback for per-shop distance (null if unknown).
  static List<RepairShop> apply(
    List<RepairShop> shops,
    ShopFilter filter, {
    double? Function(RepairShop shop)? distanceKm,
  }) {
    Iterable<RepairShop> result = shops;

    // Open now filter
    if (filter.openNow) {
      result = result.where(_isOpenNow);
    }

    // Min rating
    if (filter.minRating > 0) {
      result = result.where((s) => s.rating >= filter.minRating);
    }

    // Price range
    if (filter.priceRanges.isNotEmpty) {
      result = result.where((s) => filter.priceRanges.contains(s.priceRange));
    }

    // Max distance
    if (filter.maxDistanceKm != null && distanceKm != null) {
      result = result.where((s) {
        final d = distanceKm(s);
        return d != null && d <= filter.maxDistanceKm!;
      });
    }

    final list = result.toList();

    // Sort
    switch (filter.sortMode) {
      case ShopSortMode.distance:
        if (distanceKm != null) {
          list.sort((a, b) {
            final da = distanceKm(a) ?? double.infinity;
            final db = distanceKm(b) ?? double.infinity;
            return da.compareTo(db);
          });
        } else {
          // No location available — falling back to rating sort gives
          // the user a meaningful order ("best shops first") instead of
          // leaving the list in arbitrary Firestore-fetch order. The
          // alternative (no sort) feels broken when a user picks
          // "Distance" and gets a random-looking list.
          list.sort((a, b) => b.rating.compareTo(a.rating));
        }
        break;
      case ShopSortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ShopSortMode.newest:
        list.sort((a, b) {
          final ta = a.timestamp?.millisecondsSinceEpoch ?? 0;
          final tb = b.timestamp?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
        break;
      case ShopSortMode.nameAsc:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return list;
  }

  /// Returns true if the shop is open at the current local time.
  /// Heuristic: parses hours for today's day-of-week from [RepairShop.hours].
  static bool _isOpenNow(RepairShop shop) {
    if (shop.irregularHours) return true; // Treat as "may be open"
    if (shop.hours.isEmpty) return false;

    final now = DateTime.now();
    final dayKey = _dayKey(now.weekday);

    // Try multiple key variations to be tolerant of existing data.
    final raw = shop.hours[dayKey] ??
        shop.hours[dayKey.toLowerCase()] ??
        shop.hours[_dayKeyFull(now.weekday)] ??
        shop.hours[_dayKeyFull(now.weekday).toLowerCase()];
    if (raw == null || raw.isEmpty) return false;
    if (raw.toLowerCase() == 'closed') return false;

    // Match patterns like "09:00-18:00" or "09:00 - 18:00"
    final cleaned = raw.replaceAll(' ', '');
    final parts = cleaned.split('-');
    if (parts.length != 2) return false;

    final open = _parseTime(parts[0]);
    final close = _parseTime(parts[1]);
    if (open == null || close == null) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    // Handle "past midnight" closing (e.g. 18:00-02:00)
    if (close < open) {
      return nowMinutes >= open || nowMinutes < close;
    }
    return nowMinutes >= open && nowMinutes < close;
  }

  static int? _parseTime(String s) {
    // Accept H:MM, HH:MM, H.MM, HH.MM, HHMM
    final clean = s.replaceAll('.', ':').trim();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(clean);
    if (m != null) {
      final h = int.tryParse(m.group(1)!) ?? 0;
      final mm = int.tryParse(m.group(2)!) ?? 0;
      return h * 60 + mm;
    }
    // HHMM
    final n = int.tryParse(clean);
    if (n != null && clean.length >= 3) {
      final h = n ~/ 100;
      final mm = n % 100;
      return h * 60 + mm;
    }
    return null;
  }

  static String _dayKey(int weekday) {
    // Dart weekday: 1=Mon ... 7=Sun. Match existing 3-letter keys.
    const keys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return keys[weekday - 1];
  }

  static String _dayKeyFull(int weekday) {
    const keys = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return keys[weekday - 1];
  }
}
