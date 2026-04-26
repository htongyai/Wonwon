import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Community-wide impact ticker on the home screen. Reads a single
/// Firestore doc (`config/app.communityStats`) so we don't hammer the
/// repair records collection on every open.
///
/// Doc shape (optional; gracefully degrades if missing):
/// ```
/// config/app {
///   communityStats: {
///     itemsRepairedThisMonth: 1247,
///     monthOverMonthPercent: 18,
///     updatedAt: Timestamp
///   }
/// }
/// ```
class CommunityImpactBanner extends StatefulWidget {
  const CommunityImpactBanner({Key? key}) : super(key: key);

  @override
  State<CommunityImpactBanner> createState() => _CommunityImpactBannerState();
}

class _CommunityImpactBannerState extends State<CommunityImpactBanner> {
  int? _itemsThisMonth;
  int? _momPercent;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();
      if (!mounted) return;
      final raw = doc.data()?['communityStats'] as Map<String, dynamic>?;
      if (raw == null) return;
      setState(() {
        _itemsThisMonth = (raw['itemsRepairedThisMonth'] as num?)?.toInt();
        _momPercent = (raw['monthOverMonthPercent'] as num?)?.toInt();
      });
    } catch (e) {
      appLog('CommunityImpactBanner load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_itemsThisMonth == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: EcoPalette.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EcoPalette.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'community_eyebrow'.tr(context),
              style: EditorialTypography.eyebrowLeaf,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatCount(_itemsThisMonth!),
                    style: EditorialTypography.displayLarge.copyWith(
                      color: EcoPalette.inkPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '  ${'community_items_saved'.tr(context)}',
                    style: EditorialTypography.body.copyWith(
                      color: EcoPalette.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_momPercent != null && _momPercent! > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 14, color: EcoPalette.leaf),
                  const SizedBox(width: 4),
                  Text(
                    'community_mom_change'
                        .tr(context)
                        .replaceFirst('{n}', '$_momPercent'),
                    style: EditorialTypography.caption.copyWith(
                      color: EcoPalette.leaf,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    // Insert thousands separator for readability
    final s = n.toString();
    final chars = s.split('').reversed.toList();
    final buf = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(chars[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}
