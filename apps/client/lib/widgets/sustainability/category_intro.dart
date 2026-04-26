import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// One-line editorial intro shown when a category filter is active.
/// Frames the repair decision in the WonWon voice before the results.
class CategoryIntro extends StatelessWidget {
  final String categoryId;
  const CategoryIntro({Key? key, required this.categoryId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final intro = _introForCategory(categoryId);
    if (intro == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoPalette.surfaceDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 3, height: 40, color: EcoPalette.leaf),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '"${intro.tr(context)}"',
                style: EditorialTypography.displayQuote.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resolve the translation key for a category's editorial intro.
  /// Returns null for unknown categories so the widget stays invisible.
  String? _introForCategory(String id) {
    const map = {
      'clothing': 'intro_clothing',
      'footwear': 'intro_footwear',
      'watch': 'intro_watch',
      'bag': 'intro_bag',
      'electronics': 'intro_electronics',
      'appliance': 'intro_appliance',
    };
    return map[id];
  }
}
