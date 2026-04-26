import 'package:shared/models/repair_record.dart';

/// Estimates the environmental + financial impact of a repair.
///
/// Values are **rough approximations** based on life-cycle assessment (LCA)
/// averages for the Bangkok context — not precise science. The goal is to
/// translate an abstract repair into a felt number ("4 kg CO₂ saved").
///
/// Sources / rationale:
///  * Clothing: ~8 kg CO₂e per garment (ref: Ellen MacArthur Foundation,
///    2017 fashion report).
///  * Electronics: highly variable, but a phone/laptop repair saves ~25 kg
///    CO₂e vs. replacement (ref: iFixit + EU Commission 2020 studies).
///  * Appliances: ~45 kg CO₂e average saved per repaired major appliance.
///
/// Money-saved figures are Bangkok retail/repair price ratios
/// (~60-80% cheaper than buying new).
class RepairImpact {
  RepairImpact._();

  /// CO₂ saved (kg) per repair, by category id.
  /// Matches [RepairCategory.getCategories()] ids.
  static const Map<String, double> _co2PerCategoryKg = {
    'clothing': 8.5,
    'footwear': 12.0,
    'watch': 2.0,
    'bag': 10.0,
    'electronics': 25.0,
    'appliance': 45.0,
  };

  /// Money saved (฿) per repair, by category id.
  /// Heuristic: average retail price of item − average repair cost.
  static const Map<String, int> _savedBahtPerCategory = {
    'clothing': 600,
    'footwear': 1200,
    'watch': 800,
    'bag': 1500,
    'electronics': 2500,
    'appliance': 3500,
  };

  // ── Per-repair figures ────────────────────────────────────────────────────

  /// CO₂ (kg) saved by this single repair. Returns 0 if unknown category.
  static double co2ForRepair(RepairRecord record) {
    return _co2PerCategoryKg[record.category] ?? 5.0;
  }

  /// Baht saved by this single repair (vs. buying new), minus the paid price.
  /// Returns 0 or negative is clamped to 0.
  static double moneySavedForRepair(RepairRecord record) {
    final baselineSaving =
        _savedBahtPerCategory[record.category]?.toDouble() ?? 600;
    final paid = record.price ?? 0;
    final net = baselineSaving - paid;
    return net < 0 ? 0 : net;
  }

  /// Baht saved for a shop in general (averaged across its categories).
  /// Used on shop-card savings chips where we don't have a specific repair.
  static int avgSavedBahtForCategories(List<String> categories) {
    if (categories.isEmpty) return 600;
    double total = 0;
    int count = 0;
    for (final c in categories) {
      final v = _savedBahtPerCategory[c];
      if (v != null) {
        total += v;
        count++;
      }
    }
    if (count == 0) return 600;
    return (total / count).round();
  }

  // ── Aggregates ────────────────────────────────────────────────────────────

  /// Total impact across a list of records. Always returns a non-null
  /// object (zero values if empty).
  static ImpactTotals totals(Iterable<RepairRecord> records) {
    double co2 = 0;
    double money = 0;
    final shops = <String>{};
    int items = 0;

    for (final r in records) {
      co2 += co2ForRepair(r);
      money += moneySavedForRepair(r);
      shops.add(r.shopId);
      items += 1;
    }

    return ImpactTotals(
      items: items,
      co2Kg: co2,
      moneyBaht: money,
      shopsSupported: shops.length,
    );
  }

  // ── Human analogies ───────────────────────────────────────────────────────

  /// Driving-km equivalent for a CO₂ amount. Average car emits ~0.25 kg CO₂ / km
  /// in city driving. Returns 0 if the result would round to less than 1 km.
  /// The caller formats the number into a localized string.
  static int drivingEquivalentKm(double co2Kg) {
    final km = (co2Kg / 0.25).round();
    return km < 1 ? 0 : km;
  }

  /// Trees analogy: ~21 kg CO₂ absorbed per mature tree per year.
  /// Returns the number of days of tree growth, or 0 if less than 1.
  /// The caller formats the number into a localized string.
  static int treesEquivalentDays(double co2Kg) {
    final days = (co2Kg / 21 * 365).round();
    return days < 1 ? 0 : days;
  }
}

/// Aggregate impact totals for a set of repairs.
class ImpactTotals {
  final int items;
  final double co2Kg;
  final double moneyBaht;
  final int shopsSupported;

  const ImpactTotals({
    required this.items,
    required this.co2Kg,
    required this.moneyBaht,
    required this.shopsSupported,
  });

  bool get isZero => items == 0;
}
